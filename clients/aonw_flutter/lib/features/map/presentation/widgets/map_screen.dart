import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../game/aonw_flame_game.dart';
import '../../../../game/map/map_display_options.dart';
import '../../../../l10n/l10n.dart';
import '../../../audio/presentation/game_audio_actions.dart';
import '../../../diplomacy/application/diplomacy_state.dart';
import '../../../local_game/application/local_ai_turn_state.dart';
import '../../../local_game/application/local_handoff_state.dart';
import '../../../local_game/presentation/local_handoff_overlay.dart';
import '../../../research/application/research_state.dart';
import '../../../save_game/application/local_save_state.dart';
import '../../../settings/application/client_gamepad_settings.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../turns/application/automatic_turn_flow.dart';
import '../../../turns/application/turn_action_state.dart';
import '../../../turns/application/turn_presentation_queue.dart';
import '../../../turns/presentation/turn_banner.dart';
import '../../../turns/presentation/turn_hud.dart';
import '../../../workers/read_model/worker_view.dart';
import '../../application/game_session_state.dart';
import '../../application/hex_inspection_state.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../city_planning_presentation.dart';
import '../geometry/odd_q_flat_top_geometry.dart';
import '../input/map_action_palette_intent.dart';
import '../input/map_gamepad_cursor.dart';
import '../input/map_gamepad_input.dart';
import '../input/map_gamepad_navigation.dart';
import '../input/map_hex_selection_palette_intent.dart';
import '../input/map_input.dart';
import '../input/map_keyboard_shortcuts.dart';
import '../input/map_viewport_intent.dart';
import '../map_action_palette_view.dart';
import '../map_audio.dart';
import '../map_feedback_labels.dart';
import '../map_hex_selection_palette_view.dart';
import '../map_presentation_controller.dart';
import '../map_render_snapshot.dart';
import 'flame_map_viewport.dart';
import 'hex_inspection_overlay.dart';
import 'map_gamepad_region.dart';
import 'map_hud_panels.dart';
import 'map_selection_overlay.dart';
import 'map_status.dart';
import 'network_game_status_overlay.dart';

part 'map_screen_action_palette.dart';
part 'map_screen_automation.dart';
part 'map_screen_hex_selection_palette.dart';
part 'map_screen_lifecycle.dart';
part 'map_screen_gamepad.dart';
part 'map_screen_cursor.dart';
part 'map_screen_keyboard.dart';
part 'map_screen_ready.dart';
part 'map_screen_scene.dart';
part 'map_screen_save.dart';
part 'map_screen_city_planning.dart';

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
  late final _cityPlanning = CityPlanningPresentation(
    onChanged: (value) => _flameGame.setCityPlanning(value),
  );
  bool _planningEnabled = false;
  late FocusNode _flameFocusNode;
  late AppLifecycleState _lifecycleState;
  late Ticker _gamepadTicker;
  late final MapGamepadNavigation _gamepadNavigation;
  ModalRoute<void>? _subscribedRoute;
  var _routeVisible = true;
  var _gamepadAvailable = true;
  var _flameGeneration = 0;
  var _gamepadOwnerGeneration = 0;
  var _keyboardInputGeneration = 0;
  StreamSubscription<MapInputCommand>? _inputSubscription;
  StreamSubscription<MapGamepadInput>? _continuousInputSubscription;
  final _gamepadCursor = MapGamepadCursor();
  ClientGamepadSettings _gamepadSettings = const ClientGamepadSettings();
  MapGamepadInput _gamepadInput = MapGamepadInput.idle;
  MapGamepadFrameController _gamepadFrames = MapGamepadFrameController();
  Duration? _lastGamepadElapsed;
  AonwLocalizations? _localizations;
  final _automaticFlow = AutomaticTurnFlow();
  Object? _automaticObserved;
  var _automaticGeneration = 0;
  var _automaticQueued = false;
  Object? _automaticOperation;
  var _automaticDirty = false;
  var _automaticDisposed = false;
  var _automaticSettingsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _gamepadTicker = createTicker(_tickGamepad);
    _flameFocusNode = FocusNode(debugLabel: 'AoNW Flame viewport')
      ..addListener(_invalidateKeyboardInput);
    _gamepadNavigation = MapGamepadNavigation(
      onOwnerChanged: () {
        _gamepadOwnerGeneration += 1;
        _automaticGeneration += 1;
        _requestAutomaticTurn();
        _flameGame.setKeyboardPanDirection(x: 0, y: 0);
        _gamepadFrames.prime(_gamepadInput);
      },
      returnToMap: _flameFocusNode.requestFocus,
    );
    _flameGame = widget.flameGameFactory();
    _flameGame.setSoundSink(context.playMapSound);
    _flameGame.setHexIntentSink(_handleHexIntent);
    _flameGame.setActionPaletteIntentSink(_handleActionPaletteIntent);
    _flameGame.setHexSelectionPaletteIntentSink(
      _handleHexSelectionPaletteIntent,
    );
    widget.controller.addListener(_synchronizeFlameScene);
    widget.controller.bindCommandEffects(_flameGame.waitForCommandEffects);
    widget.controller.bindInteractionSounds(_playInteractionSound);
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
    _localizations = context.aonwL10n;
    _subscribeToRoute();
    _synchronizeFlameScene();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _automaticOperation = null;
      _automaticGeneration += 1;
      _gamepadCursor.reset();
      _gamepadNavigation.setAvailable(false);
      oldWidget.controller.bindCommandEffects(null);
      oldWidget.controller.bindInteractionSounds(null);
      _flameGame.skipEffects();
      oldWidget.controller.removeListener(_synchronizeFlameScene);
      oldWidget.controller.cursor.removeListener(_synchronizeFlameCursor);
      widget.controller.addListener(_synchronizeFlameScene);
      widget.controller.bindCommandEffects(_flameGame.waitForCommandEffects);
      widget.controller.bindInteractionSounds(_playInteractionSound);
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
    _cityPlanning.dispose();
    _automaticDisposed = true;
    _automaticGeneration += 1;
    widget.controller.bindInteractionSounds(null);
    widget.controller.bindCommandEffects(null);
    _flameGame.skipEffects();
    _flameGame.setViewportActive(false);
    WidgetsBinding.instance.removeObserver(this);
    widget.routeObserver?.unsubscribe(this);
    widget.controller.removeListener(_synchronizeFlameScene);
    widget.controller.cursor.removeListener(_synchronizeFlameCursor);
    unawaited(_inputSubscription?.cancel());
    unawaited(_continuousInputSubscription?.cancel());
    _gamepadTicker.dispose();
    _gamepadNavigation.dispose();
    _flameGame.setHexIntentSink(null);
    _flameGame.setSoundSink(null);
    _flameGame.setActionPaletteIntentSink(null);
    _flameGame.setHexSelectionPaletteIntentSink(null);
    _flameFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _invalidateKeyboardInput();
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
  Widget build(BuildContext context) => MapGamepadNavigationScope(
    navigation: _gamepadNavigation,
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: _buildState,
    ),
  );

  Widget _buildState(BuildContext context, Widget? child) {
    final state = widget.controller.state;
    _applyClientSettings(context);
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
        :final inspection,
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
          inspection: inspection,
          controller: widget.controller,
          onInput: _handleInput,
          onTurnShortcut: _handleKeyboardTurnShortcut,
          canPanKeyboard: () => _keyboardMapInputAvailable,
          onOpenSettings: widget.onOpenSettings,
          flameGame: _flameGame,
          flameGeneration: _flameGeneration,
          flameFocusNode: _flameFocusNode,
          gamepadNavigation: _gamepadNavigation,
          onRetryFlame: _retryFlame,
        ),
    };
  }

  void _applyClientSettings(BuildContext context) {
    final settings = ClientSettingsScope.settingsOf(context);
    _flameGame.setReducedMotion(
      settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
    );
    _flameGame.setUnitMovementAnimations(settings.showUnitMovementAnimations);
    _flameGame.setCombatAnimations(settings.showCombatAnimations);
    _flameGame.setUnitIdleAnimations(settings.showUnitIdleAnimations);
    _flameGame.setRouteAnimations(settings.showRouteAnimations);
    _flameGame.setCameraSensitivity(settings.cameraSensitivity);
    _flameGame.setSmoothCameraMovement(settings.smoothCameraMovement);
    _flameGame.setCinematicCamera(settings.cinematicCamera);
    _flameGame.setMovementCameraOptions((
      focusOwn: settings.focusOwnUnitMovement,
      followOwn: settings.followOwnUnitMovement,
      focusForeign: settings.focusForeignUnitMovement,
      followForeign: settings.followForeignUnitMovement,
    ));
    _flameGame.setMapDisplayOptions(
      MapDisplayOptions(
        showCitySites: settings.showMapCitySites,
        showCityGrowth: settings.showMapCityGrowth,
        showGrid: settings.showMapGrid,
        showElevationWalls: settings.showMapElevationWalls,
        showTerrainIcons: settings.showMapTerrainIcons,
        showResourceIcons: settings.showMapResourceIcons,
        showHeightBadges: settings.showMapHeightBadges,
      ),
    );
    _planningEnabled = settings.showMapCitySites || settings.showMapCityGrowth;
    _synchronizeCityPlanning();
    _synchronizeGamepadSettings(settings.gamepad);
    final ready = ClientSettingsScope.isLoadedOf(context);
    final changed = _automaticFlow.configure(settings.automation);
    if (changed || ready != _automaticSettingsReady) {
      _automaticSettingsReady = ready;
      _automaticGeneration += 1;
      _requestAutomaticTurn();
    }
  }

  void _installFreshFlameGame() {
    _gamepadCursor.reset();
    widget.controller.silencePendingInteractionSounds();
    _flameGame.setSoundSink(null);
    _flameGame.skipEffects();
    _flameGame.setViewportActive(false);
    _flameGame.setHexIntentSink(null);
    _flameGame.setActionPaletteIntentSink(null);
    _flameGame.setHexSelectionPaletteIntentSink(null);
    _flameGame = widget.flameGameFactory();
    _flameGame.setSoundSink(context.playMapSound);
    widget.controller.bindCommandEffects(_flameGame.waitForCommandEffects);
    _flameGame.setHexIntentSink(_handleHexIntent);
    _flameGame.setActionPaletteIntentSink(_handleActionPaletteIntent);
    _flameGame.setHexSelectionPaletteIntentSink(
      _handleHexSelectionPaletteIntent,
    );
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
    final state = _mapInputReady(command);
    if (state == null) return;
    if (_gamepadNavigation.handlePanelKeyboardCommand(command)) return;
    if (command == MapInputCommand.inspectHex) {
      widget.controller.inspectHex(
        widget.controller.cursor.value ??
            state.interaction.selected ??
            _viewportCenterHex ??
            MapInputCursor.initial(state.scene.map),
      );
      return;
    }
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
        widget.controller.cancelInteraction();
      case MapInputCommand.inspectHex:
        _inspectCursor(state);
      case MapInputCommand.toggleMoveTargeting:
        widget.controller.toggleMoveTargeting();
      case MapInputCommand.toggleMapViewMode:
        widget.controller.toggleMapViewMode();
      case MapInputCommand.cursorUp:
      case MapInputCommand.cursorDown:
      case MapInputCommand.cursorLeft:
      case MapInputCommand.cursorRight:
        final current =
            widget.controller.cursor.value ??
            state.interaction.selected ??
            MapInputCursor.initial(state.scene.map);
        widget.controller.moveMapCursor(
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
      case MapHexLongPressIntent(:final coordinate, :final screenPosition):
        _openHexSelectionPalette(coordinate, screenPosition);
    }
  }
}
