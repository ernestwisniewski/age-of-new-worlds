import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../replay/application/replay_state.dart';
import '../../replay/presentation/replay_presentation_controller.dart';
import '../../save_game/application/local_save_state.dart';

typedef LocalSaveAvailabilityReader = Future<bool> Function();
typedef LocalGameResume = Future<LocalResumeResultView> Function();
typedef LocalReplayAvailabilityReader = Future<bool> Function();
typedef LocalReplayOpen = Future<ReplayOpenResultView> Function();

final class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    required this.onNewGame,
    required this.onOpenSettings,
    required this.onOpenHelp,
    this.onOpenMultiplayer,
    required this.hasLocalSave,
    required this.resumeLocalGame,
    required this.onResumed,
    required this.hasLocalReplay,
    required this.openReplay,
    required this.onReplayOpened,
    super.key,
  });

  final VoidCallback onNewGame;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHelp;
  final VoidCallback? onOpenMultiplayer;
  final LocalSaveAvailabilityReader hasLocalSave;
  final LocalGameResume resumeLocalGame;
  final VoidCallback onResumed;
  final LocalReplayAvailabilityReader hasLocalReplay;
  final LocalReplayOpen openReplay;
  final VoidCallback onReplayOpened;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

final class _MainMenuScreenState extends State<MainMenuScreen> {
  late Future<bool> _hasSave;
  late Future<bool> _hasReplay;
  var _resuming = false;
  var _openingReplay = false;
  LocalResumeFailureViewCode? _failure;
  ReplayFailureViewCode? _replayFailure;

  @override
  void initState() {
    super.initState();
    _hasSave = widget.hasLocalSave();
    _hasReplay = widget.hasLocalReplay();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: AonwPanel(
          semanticLabel: context.aonwL10n.mainMenuTitle,
          maxWidth: 420,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.aonwL10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AonwSpacing.xl),
              FutureBuilder<bool>(
                future: _hasSave,
                builder: (context, snapshot) => FilledButton.icon(
                  key: const ValueKey('continue-game'),
                  onPressed: snapshot.data == true && !_busy ? _resume : null,
                  icon: _resuming
                      ? const SizedBox.square(
                          dimension: AonwSizes.compactProgress,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: Text(
                    _resuming
                        ? context.aonwL10n.resumingGame
                        : context.aonwL10n.continueGame,
                  ),
                ),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('new-game'),
                onPressed: _busy ? null : widget.onNewGame,
                icon: const Icon(Icons.add),
                label: Text(context.aonwL10n.newGame),
              ),
              if (widget.onOpenMultiplayer case final openMultiplayer?) ...[
                const SizedBox(height: AonwSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('multiplayer'),
                  onPressed: _busy ? null : openMultiplayer,
                  icon: const Icon(Icons.public),
                  label: Text(context.aonwL10n.multiplayerTitle),
                ),
              ],
              const SizedBox(height: AonwSpacing.sm),
              FutureBuilder<bool>(
                future: _hasReplay,
                builder: (context, snapshot) => OutlinedButton.icon(
                  key: const ValueKey('open-replay'),
                  onPressed: snapshot.data == true && !_busy
                      ? _openReplay
                      : null,
                  icon: _openingReplay
                      ? const SizedBox.square(
                          dimension: AonwSizes.compactProgress,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: Text(
                    _openingReplay
                        ? context.aonwL10n.loadingReplay
                        : context.aonwL10n.replayTitle,
                  ),
                ),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('menu-help'),
                onPressed: _busy ? null : widget.onOpenHelp,
                icon: const Icon(Icons.help_outline),
                label: Text(context.aonwL10n.helpTitle),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('menu-settings'),
                onPressed: _busy ? null : widget.onOpenSettings,
                icon: const Icon(Icons.settings),
                label: Text(context.aonwL10n.settingsTitle),
              ),
              if (_failure case final failure?) ...[
                const SizedBox(height: AonwSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    context.aonwL10n.resumeFailure(failure.name),
                    key: const ValueKey('resume-failure'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              if (_replayFailure case final failure?) ...[
                const SizedBox(height: AonwSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    context.aonwL10n.replayFailure(failure.name),
                    key: const ValueKey('replay-failure'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _resume() async {
    setState(() {
      _resuming = true;
      _failure = null;
      _replayFailure = null;
    });
    final result = await widget.resumeLocalGame();
    if (!mounted) return;
    if (result.started) {
      widget.onResumed();
      return;
    }
    setState(() {
      _resuming = false;
      _failure = result.failure;
      _hasSave = widget.hasLocalSave();
    });
  }

  bool get _busy => _resuming || _openingReplay;

  Future<void> _openReplay() async {
    setState(() {
      _openingReplay = true;
      _failure = null;
      _replayFailure = null;
    });
    final result = await widget.openReplay();
    if (!mounted) return;
    if (result.started) {
      widget.onReplayOpened();
      setState(() => _openingReplay = false);
      return;
    }
    setState(() {
      _openingReplay = false;
      _replayFailure = result.failure;
      _hasReplay = widget.hasLocalReplay();
    });
  }
}
