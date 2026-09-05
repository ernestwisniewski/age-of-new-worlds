import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../game/aonw_flame_game.dart';
import '../../../l10n/l10n.dart';
import '../../map/application/map_interaction_state.dart';
import '../../map/presentation/map_feedback_labels.dart';
import '../../map/presentation/map_render_snapshot.dart';
import '../../settings/presentation/client_settings_scope.dart';
import '../application/replay_state.dart';
import '../read_model/replay_frame_view.dart';
import 'replay_presentation_controller.dart';

final class ReplayScreen extends StatefulWidget {
  const ReplayScreen({
    required this.controller,
    this.flameGameFactory = AonwFlameGame.new,
    super.key,
  });

  final ReplayPresentationController controller;
  final AonwFlameGame Function() flameGameFactory;

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

final class _ReplayScreenState extends State<ReplayScreen>
    with WidgetsBindingObserver {
  late AonwFlameGame _game;
  late AppLifecycleState _lifecycleState;
  ReplayFrameView? _lastFrame;
  var _effectEpoch = 0;
  AonwLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _game = widget.flameGameFactory();
    widget.controller.waitForCommandEffects = _game.waitForCommandEffects;
    widget.controller.addListener(_synchronizeScene);
    _synchronizeScene();
    _synchronizeLifecycle();
  }

  @override
  void didUpdateWidget(ReplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.waitForCommandEffects = null;
      _game.skipEffects();
      oldWidget.controller.removeListener(_synchronizeScene);
      widget.controller.addListener(_synchronizeScene);
    }
    if (oldWidget.flameGameFactory != widget.flameGameFactory) {
      _game.skipEffects();
      _game.setViewportActive(false);
      _game = widget.flameGameFactory();
    }
    widget.controller.waitForCommandEffects = _game.waitForCommandEffects;
    _synchronizeScene();
    _synchronizeLifecycle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state != AppLifecycleState.resumed) widget.controller.pause();
    _synchronizeLifecycle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.pause();
    widget.controller.waitForCommandEffects = null;
    _game.skipEffects();
    widget.controller.removeListener(_synchronizeScene);
    _game.setViewportActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ClientSettingsScope.settingsOf(context);
    _game.setReducedMotion(
      settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
    );
    _game.setCameraSensitivity(settings.cameraSensitivity);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => switch (widget.controller.state) {
            ReplayIdle() || ReplayLoading() => const Center(
              child: CircularProgressIndicator(key: ValueKey('replay-loading')),
            ),
            ReplayFailure(:final code) => _ReplayFailure(code: code),
            ReplayReady() => _ReplayPlayer(
              state: widget.controller.state as ReplayReady,
              controller: widget.controller,
              game: _game,
            ),
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localizations = context.aonwL10n;
    _synchronizeScene();
  }

  void _synchronizeScene() {
    switch (widget.controller.state) {
      case ReplayReady(:final frame, :final speed):
        if (!identical(_lastFrame, frame) && frame.command == null) {
          _effectEpoch++;
        }
        _lastFrame = frame;
        _game.setEffectPlaybackSpeed(speed.multiplier);
        _game.sceneSink.replaceScene(
          MapRenderSnapshot(
            map: frame.scene.map,
            interaction: const MapInteractionState(),
            reference: frame.scene.reference,
            player: frame.scene.player,
            commandFrame: frame.command,
            effectEpoch: _effectEpoch,
            feedbackLabels: switch (_localizations) {
              final l10n? => buildMapFeedbackLabels(
                frame.scene.player.recentFeedback,
                l10n,
              ),
              null => const MapFeedbackLabels.empty(),
            },
          ),
        );
      case ReplayIdle() || ReplayLoading() || ReplayFailure():
        _lastFrame = null;
        _game.sceneSink.clearScene();
    }
  }

  void _synchronizeLifecycle() {
    _game.setViewportActive(_lifecycleState == AppLifecycleState.resumed);
  }
}

final class _ReplayPlayer extends StatelessWidget {
  const _ReplayPlayer({
    required this.state,
    required this.controller,
    required this.game,
  });

  final ReplayReady state;
  final ReplayPresentationController controller;
  final AonwFlameGame game;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: Semantics(
          label: context.aonwL10n.replayMapLabel,
          child: RepaintBoundary(
            child: GameWidget<AonwFlameGame>(
              key: const ValueKey('replay-viewport'),
              game: game,
              autofocus: false,
              addRepaintBoundary: false,
            ),
          ),
        ),
      ),
      Positioned(
        left: AonwSpacing.md,
        top: AonwSpacing.md,
        child: AonwPanel(
          semanticLabel: context.aonwL10n.replayTitle,
          padding: const EdgeInsets.symmetric(
            horizontal: AonwSpacing.sm,
            vertical: AonwSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('close-replay'),
                tooltip: context.aonwL10n.backToMenu,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              Text(
                context.aonwL10n.replayTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: AonwSpacing.md,
        right: AonwSpacing.md,
        bottom: AonwSpacing.md,
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
    child: Row(
      children: [
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
        Expanded(
          child: Slider(
            key: const ValueKey('replay-seek'),
            value: state.frame.position.toDouble(),
            min: 0,
            max: state.frame.entryCount.toDouble().clamp(1, double.infinity),
            divisions: state.frame.entryCount > 0
                ? state.frame.entryCount
                : null,
            label: context.aonwL10n.replayProgress(
              state.frame.position,
              state.frame.entryCount,
            ),
            onChanged: state.isSeeking
                ? null
                : (value) => controller.seek(value.round()),
          ),
        ),
        Text(
          context.aonwL10n.replayProgress(
            state.frame.position,
            state.frame.entryCount,
          ),
          key: const ValueKey('replay-progress'),
        ),
        const SizedBox(width: AonwSpacing.sm),
        OutlinedButton(
          key: const ValueKey('replay-speed'),
          onPressed: state.isSeeking ? null : controller.cycleSpeed,
          child: Text(
            context.aonwL10n.replaySpeed(_speedLabel(state.speed.multiplier)),
          ),
        ),
      ],
    ),
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
