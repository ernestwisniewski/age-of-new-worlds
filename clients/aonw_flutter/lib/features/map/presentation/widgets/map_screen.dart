import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../l10n/l10n.dart';
import '../../../diplomacy/application/diplomacy_state.dart';
import '../../../local_game/application/local_ai_turn_state.dart';
import '../../../local_game/application/local_handoff_state.dart';
import '../../../local_game/presentation/local_handoff_overlay.dart';
import '../../../research/application/research_state.dart';
import '../../../save_game/application/local_save_state.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../turns/application/turn_action_state.dart';
import '../../../turns/application/turn_presentation_queue.dart';
import '../../../turns/presentation/turn_banner.dart';
import '../../../turns/presentation/turn_hud.dart';
import '../../application/game_session_state.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../input/map_gamepad_input.dart';
import '../input/map_input.dart';
import '../input/map_viewport_intent.dart';
import '../map_presentation_controller.dart';
import '../map_render_snapshot.dart';
import 'flame_map_viewport.dart';
import 'map_hud_panels.dart';
import 'map_selection_overlay.dart';
import 'map_status.dart';
import 'network_game_status_overlay.dart';

part 'map_screen_ready.dart';

final class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.controller,
    this.inputSource,
    this.onOpenSettings,
    this.flameGameFactory = AonwFlameGame.new,
    this.routeObserver,
    this.autoLoad = true,
    super.key,
  });

  final MapPresentationController controller;
  final MapInputSource? inputSource;
  final VoidCallback? onOpenSettings;
  final AonwFlameGame Function() flameGameFactory;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final bool autoLoad;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

final class _MapScreenState extends State<MapScreen>
    with WidgetsBindingObserver, RouteAware, SingleTickerProviderStateMixin {
  late AonwFlameGame _flameGame;
  late FocusNode _flameFocusNode;
  late AppLifecycleState _lifecycleState;
  late Ticker _gamepadTicker;
  ModalRoute<void>? _subscribedRoute;
  var _routeVisible = true;
  var _flameGeneration = 0;
  StreamSubscription<MapInputCommand>? _inputSubscription;
  StreamSubscription<MapGamepadInput>? _continuousInputSubscription;
  MapGamepadInput _gamepadInput = MapGamepadInput.idle;
  MapGamepadFrameController _gamepadFrames = MapGamepadFrameController();
  Duration? _lastGamepadElapsed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _gamepadTicker = createTicker(_tickGamepad);
    _flameFocusNode = FocusNode(debugLabel: 'AoNW Flame viewport');
    _flameGame = widget.flameGameFactory();
    _flameGame.setHexIntentSink(_handleHexIntent);
    widget.controller.addListener(_synchronizeFlameScene);
    widget.controller.cursor.addListener(_synchronizeFlameCursor);
    _listenToInput(widget.inputSource);
    if (widget.autoLoad) widget.controller.load();
    _synchronizeFlameScene();
    _synchronizeFlameCursor();
    _synchronizeFlameLifecycle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRoute();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_synchronizeFlameScene);
      oldWidget.controller.cursor.removeListener(_synchronizeFlameCursor);
      widget.controller.addListener(_synchronizeFlameScene);
      widget.controller.cursor.addListener(_synchronizeFlameCursor);
    }
    if (oldWidget.inputSource != widget.inputSource) {
      _listenToInput(widget.inputSource);
    }
    if (oldWidget.flameGameFactory != widget.flameGameFactory) {
      _installFreshFlameGame();
    }
    if (oldWidget.routeObserver != widget.routeObserver) {
      oldWidget.routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
      _subscribeToRoute();
    }
    if (widget.autoLoad &&
        (oldWidget.controller != widget.controller || !oldWidget.autoLoad)) {
      widget.controller.load();
    }
    _synchronizeFlameScene();
    _synchronizeFlameCursor();
    _synchronizeFlameLifecycle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.routeObserver?.unsubscribe(this);
    widget.controller.removeListener(_synchronizeFlameScene);
    widget.controller.cursor.removeListener(_synchronizeFlameCursor);
    unawaited(_inputSubscription?.cancel());
    unawaited(_continuousInputSubscription?.cancel());
    _gamepadTicker.dispose();
    _flameGame.setHexIntentSink(null);
    _flameFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _synchronizeFlameLifecycle();
  }

  @override
  void didPush() => _setRouteVisible(true);

  @override
  void didPopNext() => _setRouteVisible(true);

  @override
  void didPushNext() => _setRouteVisible(false);

  @override
  void didPop() => _setRouteVisible(false);

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.controller, builder: _buildState);

  Widget _buildState(BuildContext context, Widget? child) {
    final state = widget.controller.state;
    final settings = ClientSettingsScope.settingsOf(context);
    _flameGame.setReducedMotion(
      settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
    );
    _flameGame.setCameraSensitivity(settings.cameraSensitivity);
    _flameGame.setMapElevationWallsVisible(settings.showMapElevationWalls);
    _synchronizeGamepadSettings(settings.cameraSensitivity);
    return switch (state) {
      GameSessionLoading() => const LoadingMap(),
      GameSessionFailure(:final code) => MapFailure(
        code: code,
        retry: widget.controller.load,
      ),
      GameSessionReady(
        :final scene,
        :final interaction,
        :final turnPresentations,
        :final turnAction,
        :final research,
        :final diplomacy,
        :final localAiTurn,
        :final localHandoff,
        :final localSave,
      ) =>
        _ReadyMap(
          scene: scene,
          interaction: interaction,
          turnPresentations: turnPresentations,
          turnAction: turnAction,
          research: research,
          diplomacy: diplomacy,
          localAiTurn: localAiTurn,
          localHandoff: localHandoff,
          localSave: localSave,
          controller: widget.controller,
          onInput: _handleInput,
          onOpenSettings: widget.onOpenSettings,
          flameGame: _flameGame,
          flameGeneration: _flameGeneration,
          flameFocusNode: _flameFocusNode,
          onRetryFlame: _retryFlame,
        ),
    };
  }

  void _listenToInput(MapInputSource? source) {
    unawaited(_inputSubscription?.cancel());
    unawaited(_continuousInputSubscription?.cancel());
    _inputSubscription = source?.commands.listen(_handleInput);
    _gamepadInput = MapGamepadInput.idle;
    _gamepadFrames.prime(_gamepadInput);
    _continuousInputSubscription = switch (source) {
      ContinuousMapInputSource(:final continuousInputs) =>
        continuousInputs.listen(_handleContinuousInput),
      _ => null,
    };
    _synchronizeGamepadTicker();
  }

  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _subscribedRoute) return;
    widget.routeObserver?.unsubscribe(this);
    _subscribedRoute = route;
    widget.routeObserver?.subscribe(this, route);
  }

  void _setRouteVisible(bool visible) {
    if (_routeVisible == visible) return;
    _routeVisible = visible;
    _synchronizeFlameLifecycle();
  }

  void _synchronizeFlameLifecycle() {
    _flameGame.setViewportActive(
      _routeVisible && _lifecycleState == AppLifecycleState.resumed,
    );
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadSettings(double cameraSensitivity) {
    if (_gamepadFrames.cameraSensitivity == cameraSensitivity) return;
    _gamepadFrames = MapGamepadFrameController(
      cameraSensitivity: cameraSensitivity,
    )..prime(_gamepadInput);
    _synchronizeGamepadTicker();
  }

  void _handleContinuousInput(MapGamepadInput input) {
    _gamepadInput = input;
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadTicker() {
    final available =
        _routeVisible && _lifecycleState == AppLifecycleState.resumed;
    if (!available || (_gamepadInput.isIdle && _gamepadFrames.isIdle)) {
      _lastGamepadElapsed = null;
      _gamepadTicker.stop();
      return;
    }
    if (!_gamepadTicker.isActive) _gamepadTicker.start();
  }

  void _tickGamepad(Duration elapsed) {
    final previous = _lastGamepadElapsed;
    _lastGamepadElapsed = elapsed;
    final dt = previous == null
        ? 0.0
        : (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final frame = _gamepadFrames.advance(input: _gamepadInput, dt: dt);
    if (!frame.isIdle) {
      _flameGame.applyGamepadCameraFrame(frame, dt);
      final cursorStep = frame.cursorStep;
      if (cursorStep != null) _handleInput(cursorStep);
      if (frame.activatePressed) _handleInput(MapInputCommand.activate);
      if (frame.cancelPressed) _handleInput(MapInputCommand.cancel);
      if (frame.toggleReferencePressed) {
        _handleInput(MapInputCommand.toggleReference);
      }
    }
    _synchronizeGamepadTicker();
  }

  void _synchronizeFlameScene() {
    switch (widget.controller.state) {
      case GameSessionReady(:final scene, :final interaction):
        _flameGame.sceneSink.replaceScene(
          MapRenderSnapshot(
            map: scene.map,
            interaction: interaction,
            reference: scene.reference,
            player: scene.player,
          ),
        );
      case GameSessionLoading() || GameSessionFailure():
        _flameGame.sceneSink.clearScene();
    }
  }

  void _synchronizeFlameCursor() {
    _flameGame.sceneSink.replaceCursor(widget.controller.cursor.value);
  }

  void _installFreshFlameGame() {
    _flameGame.setHexIntentSink(null);
    _flameGame = widget.flameGameFactory();
    _flameGame.setHexIntentSink(_handleHexIntent);
    _flameGeneration += 1;
    _synchronizeFlameCursor();
  }

  void _retryFlame() {
    setState(_installFreshFlameGame);
    _synchronizeFlameScene();
    _synchronizeFlameCursor();
    _synchronizeFlameLifecycle();
  }

  void _handleInput(MapInputCommand command) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    final state = widget.controller.state;
    if (state is! GameSessionReady) return;
    if (widget.controller.networkConnection.blocksGameplay) return;
    if (state.localHandoff.blocksGameplay) return;
    _handleReadyInput(state, command);
  }

  void _handleReadyInput(GameSessionReady state, MapInputCommand command) {
    switch (command) {
      case MapInputCommand.activate:
        widget.controller.select(
          widget.controller.cursor.value ??
              state.interaction.selected ??
              MapInputCursor.initial(state.scene.map),
        );
      case MapInputCommand.cancel:
        widget.controller.hover(null);
        widget.controller.select(null);
      case MapInputCommand.toggleReference:
        widget.controller.toggleReference();
      case MapInputCommand.cursorUp:
      case MapInputCommand.cursorDown:
      case MapInputCommand.cursorLeft:
      case MapInputCommand.cursorRight:
        final current =
            widget.controller.cursor.value ??
            state.interaction.selected ??
            MapInputCursor.initial(state.scene.map);
        widget.controller.hover(
          MapInputCursor.move(state.scene.map, current, command),
        );
    }
  }

  void _handleHexIntent(MapHexIntent intent) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    if (widget.controller.networkConnection.blocksGameplay) return;
    final state = widget.controller.state;
    if (state is GameSessionReady && state.localHandoff.blocksGameplay) return;
    switch (intent) {
      case MapHexHoverIntent(:final coordinate):
        widget.controller.hover(coordinate);
      case MapHexSelectIntent(:final coordinate):
        widget.controller.select(coordinate);
    }
  }
}

final class _SaveAction extends StatelessWidget {
  const _SaveAction({
    required this.localSave,
    required this.localAiTurn,
    required this.localHandoff,
    required this.onSave,
  });

  final LocalSaveState localSave;
  final LocalAiTurnState localAiTurn;
  final LocalHandoffState localHandoff;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final failure = localSave.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AonwHudIconButton(
          key: const ValueKey('save-game'),
          tooltip: localSave.inFlight
              ? context.aonwL10n.savingGame
              : context.aonwL10n.saveGame,
          onPressed:
              localSave.inFlight ||
                  localAiTurn.blocksGameplay ||
                  localHandoff.blocksGameplay
              ? null
              : onSave,
          icon: Icon(
            localSave.inFlight ? Icons.hourglass_top : Icons.save_outlined,
          ),
        ),
        if (localSave.phase == LocalSavePhase.saved)
          _SaveMessage(message: context.aonwL10n.gameSaved),
        if (failure != null)
          _SaveMessage(
            message: context.aonwL10n.saveFailure(failure.name),
            error: true,
          ),
      ],
    );
  }
}

final class _SaveMessage extends StatelessWidget {
  const _SaveMessage({required this.message, this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AonwPanel(
      padding: const EdgeInsets.all(AonwSpacing.xs),
      child: Text(
        message,
        key: const ValueKey('save-status'),
        style: error
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
    ),
  );
}
