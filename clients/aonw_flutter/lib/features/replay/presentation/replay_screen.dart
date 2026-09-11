import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../game/aonw_flame_game.dart';
import '../../../l10n/l10n.dart';
import '../../map/application/game_session_state.dart';
import '../../map/presentation/input/map_input.dart';
import '../../map/presentation/map_presentation_controller.dart';
import '../../map/presentation/widgets/map_screen.dart';
import '../application/replay_state.dart';
import '../read_model/replay_frame_view.dart';
import 'replay_presentation_controller.dart';

final class ReplayScreen extends StatefulWidget {
  const ReplayScreen({
    required this.controller,
    this.flameGameFactory = AonwFlameGame.new,
    this.routeObserver,
    this.inputSource,
    super.key,
  });

  final ReplayPresentationController controller;
  final AonwFlameGame Function() flameGameFactory;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final MapInputSource? inputSource;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

final class _ReplayScreenState extends State<ReplayScreen>
    with WidgetsBindingObserver, RouteAware {
  late AonwFlameGame _game;
  late AonwFlameGame Function() _provideGame;
  bool _viewerRetired = false;
  MapPresentationController? _viewer;
  ReplayFrameView? _lastFrame;
  ModalRoute<void>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = widget.flameGameFactory();
    final game = _game;
    _provideGame = () => game;
    widget.controller.waitForCommandEffects = _waitForPresentedEffects;
    widget.controller.addListener(_synchronizeFrame);
    _synchronizeFrame();
  }

  Future<void> _waitForPresentedEffects() async {
    // MapScreen applies the new command when its widget rebuilds this frame.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await _game.waitForCommandEffects();
  }

  @override
  void didUpdateWidget(ReplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeObserver != widget.routeObserver) {
      oldWidget.routeObserver?.unsubscribe(this);
      _subscribedRoute = null;
      _subscribeToRoute();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.waitForCommandEffects = null;
      oldWidget.controller.removeListener(_synchronizeFrame);
      _lastFrame = null;
      widget.controller.addListener(_synchronizeFrame);
    }
    if (oldWidget.flameGameFactory != widget.flameGameFactory) {
      _game.skipEffects();
      _game.setViewportActive(false);
      _game = widget.flameGameFactory();
      final game = _game;
      _provideGame = () => game;
    }
    widget.controller.waitForCommandEffects = _waitForPresentedEffects;
    _synchronizeFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) widget.controller.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.routeObserver?.unsubscribe(this);
    widget.controller.removeListener(_synchronizeFrame);
    widget.controller.pause();
    widget.controller.waitForCommandEffects = null;
    _viewer?.dispose();
    _game.skipEffects();
    _game.setViewportActive(false);
    super.dispose();
  }

  void _synchronizeFrame() {
    final state = widget.controller.state;
    if (state is! ReplayReady) {
      _lastFrame = null;
      _viewer?.dispose();
      _viewer = null;
      _game.skipEffects();
      return;
    }
    _game.setEffectPlaybackSpeed(state.speed.multiplier);
    if (state.isSeeking) {
      // Pending queries belong to the old frame even when seeking to itself.
      _viewer?.dispose();
      _viewerRetired = true;
      _game.skipEffects();
      return;
    }
    if (identical(_lastFrame, state.frame) && !_viewerRetired) return;
    _lastFrame = state.frame;
    final previous = _viewer?.state;
    _viewer?.dispose();
    _viewerRetired = false;
    _viewer = widget.controller.createMapViewer(
      state.frame,
      viewMode: previous is GameSessionReady
          ? previous.interaction.viewMode
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => switch (widget.controller.state) {
          ReplayIdle() || ReplayLoading() => const Center(
            child: CircularProgressIndicator(key: ValueKey('replay-loading')),
          ),
          ReplayFailure(:final code) => _ReplayFailure(code: code),
          ReplayReady() =>
            _viewer == null
                ? const _ReplayFailure(code: ReplayFailureViewCode.unavailable)
                : _ReplayPlayer(
                    state: widget.controller.state as ReplayReady,
                    controller: widget.controller,
                    viewer: _viewer!,
                    gameFactory: _provideGame,
                    routeObserver: widget.routeObserver,
                    inputSource: widget.inputSource,
                  ),
        },
      ),
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRoute();
  }

  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _subscribedRoute) return;
    widget.routeObserver?.unsubscribe(this);
    _subscribedRoute = route;
    widget.routeObserver?.subscribe(this, route);
    if (!route.isCurrent) widget.controller.pause();
  }

  @override
  void didPushNext() => widget.controller.pause();
  @override
  void didPop() => widget.controller.pause();
}

final class _ReplayPlayer extends StatelessWidget {
  const _ReplayPlayer({
    required this.state,
    required this.controller,
    required this.viewer,
    required this.gameFactory,
    required this.routeObserver,
    required this.inputSource,
  });

  final ReplayReady state;
  final ReplayPresentationController controller;
  final MapPresentationController viewer;
  final AonwFlameGame Function() gameFactory;
  final RouteObserver<ModalRoute<void>>? routeObserver;
  final MapInputSource? inputSource;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: constraints.biggest),
            child: Semantics(
              key: const ValueKey('replay-viewport'),
              label: context.aonwL10n.replayMapLabel,
              child: MapScreen(
                controller: viewer,
                autoLoad: false,
                interactionEnabled: !state.isSeeking,
                flameGameFactory: gameFactory,
                routeObserver: routeObserver,
                inputSource: inputSource,
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: _ReplayControls(state: state, controller: controller),
      ),
    ],
  );
}

final class _ReplayControls extends StatelessWidget {
  const _ReplayControls({required this.state, required this.controller});

  final ReplayReady state;
  final ReplayPresentationController controller;

  @override
  Widget build(BuildContext context) => AonwPanel(
    semanticLabel: context.aonwL10n.replayControls,
    padding: const EdgeInsets.all(AonwSpacing.sm),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buttons(context),
        Slider(
          key: const ValueKey('replay-seek'),
          value: state.frame.position.toDouble(),
          min: 0,
          max: state.frame.entryCount.toDouble().clamp(1, double.infinity),
          divisions: state.frame.entryCount > 0 ? state.frame.entryCount : null,
          label: context.aonwL10n.replayProgress(
            state.frame.position,
            state.frame.entryCount,
          ),
          onChanged: state.isSeeking
              ? null
              : (value) => controller.seek(value.round()),
        ),
      ],
    ),
  );

  Widget _buttons(BuildContext context) => Wrap(
    spacing: AonwSpacing.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: WrapAlignment.center,
    children: [
      IconButton(
        key: const ValueKey('close-replay'),
        tooltip: context.aonwL10n.backToMenu,
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      Text(context.aonwL10n.replayTitle),
      IconButton.filled(
        key: ValueKey(state.isPlaying ? 'pause-replay' : 'play-replay'),
        tooltip: state.isPlaying
            ? context.aonwL10n.pauseReplay
            : context.aonwL10n.playReplay,
        onPressed: state.isSeeking
            ? null
            : state.isPlaying
            ? controller.pause
            : controller.play,
        icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
      Text(
        context.aonwL10n.replayProgress(
          state.frame.position,
          state.frame.entryCount,
        ),
        key: const ValueKey('replay-progress'),
      ),
      OutlinedButton(
        key: const ValueKey('replay-speed'),
        onPressed: state.isSeeking ? null : controller.cycleSpeed,
        child: Text(
          context.aonwL10n.replaySpeed(_speedLabel(state.speed.multiplier)),
        ),
      ),
    ],
  );
}

final class _ReplayFailure extends StatelessWidget {
  const _ReplayFailure({required this.code});

  final ReplayFailureViewCode code;

  @override
  Widget build(BuildContext context) => Center(
    child: AonwMessagePanel(
      semanticLabel: context.aonwL10n.replayUnavailable,
      title: context.aonwL10n.replayTitle,
      message: context.aonwL10n.replayFailure(code.name),
      actionLabel: context.aonwL10n.backToMenu,
      onAction: () => Navigator.of(context).pop(),
    ),
  );
}

String _speedLabel(double speed) => speed == speed.roundToDouble()
    ? speed.toInt().toString()
    : speed.toStringAsFixed(1);
