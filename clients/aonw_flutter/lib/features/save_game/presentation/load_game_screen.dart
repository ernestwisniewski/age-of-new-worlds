import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../replay/application/replay_state.dart';
import '../../replay/presentation/replay_presentation_controller.dart';
import '../application/local_save_state.dart';

typedef LocalSaveAvailabilityReader = Future<bool> Function();
typedef LocalGameResume = Future<LocalResumeResultView> Function();
typedef LocalReplayAvailabilityReader = Future<bool> Function();
typedef LocalReplayOpen = Future<ReplayOpenResultView> Function();

final class LoadGameScreen extends StatefulWidget {
  const LoadGameScreen({
    required this.hasLocalSave,
    required this.resumeLocalGame,
    required this.onResumed,
    required this.hasLocalReplay,
    required this.openReplay,
    required this.onReplayOpened,
    required this.onStartSinglePlayer,
    this.onImportSave,
    this.onExportSave,
    super.key,
  });

  final LocalSaveAvailabilityReader hasLocalSave;
  final LocalGameResume resumeLocalGame;
  final VoidCallback onResumed;
  final LocalReplayAvailabilityReader hasLocalReplay;
  final LocalReplayOpen openReplay;
  final VoidCallback onReplayOpened;
  final VoidCallback onStartSinglePlayer;
  final VoidCallback? onImportSave;
  final VoidCallback? onExportSave;

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

final class _LoadGameScreenState extends State<LoadGameScreen> {
  late Future<_LoadAvailability> _availability;
  var _resuming = false;
  var _openingReplay = false;
  LocalResumeFailureViewCode? _resumeFailure;
  ReplayFailureViewCode? _replayFailure;

  @override
  void initState() {
    super.initState();
    _availability = _readAvailability();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.aonwL10n.loadGameTitle)),
    body: AonwMenuBackdrop(
      child: SafeArea(
        top: false,
        child: FutureBuilder<_LoadAvailability>(
          future: _availability,
          builder: (context, snapshot) => _LoadGameBody(
            availability: snapshot.data,
            loading: snapshot.connectionState != ConnectionState.done,
            busy: _busy,
            resuming: _resuming,
            openingReplay: _openingReplay,
            resumeFailure: _resumeFailure,
            replayFailure: _replayFailure,
            onResume: _resume,
            onOpenReplay: _openReplay,
            onStartSinglePlayer: widget.onStartSinglePlayer,
            onImportSave: widget.onImportSave,
            onExportSave: widget.onExportSave,
          ),
        ),
      ),
    ),
  );

  bool get _busy => _resuming || _openingReplay;

  Future<_LoadAvailability> _readAvailability() async {
    final values = await Future.wait([
      widget.hasLocalSave(),
      widget.hasLocalReplay(),
    ]);
    return _LoadAvailability(hasSave: values[0], hasReplay: values[1]);
  }

  Future<void> _resume() async {
    setState(() {
      _resuming = true;
      _resumeFailure = null;
      _replayFailure = null;
    });
    final result = await widget.resumeLocalGame();
    if (!mounted) return;
    if (result.started) {
      setState(() => _resuming = false);
      widget.onResumed();
      return;
    }
    setState(() {
      _resuming = false;
      _resumeFailure = result.failure;
      _availability = _readAvailability();
    });
  }

  Future<void> _openReplay() async {
    setState(() {
      _openingReplay = true;
      _resumeFailure = null;
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
      _availability = _readAvailability();
    });
  }
}

final class _LoadAvailability {
  const _LoadAvailability({required this.hasSave, required this.hasReplay});

  final bool hasSave;
  final bool hasReplay;

  bool get hasContent => hasSave || hasReplay;
}

final class _LoadGameBody extends StatelessWidget {
  const _LoadGameBody({
    required this.availability,
    required this.loading,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.resumeFailure,
    required this.replayFailure,
    required this.onResume,
    required this.onOpenReplay,
    required this.onStartSinglePlayer,
    required this.onImportSave,
    required this.onExportSave,
  });

  final _LoadAvailability? availability;
  final bool loading;
  final bool busy;
  final bool resuming;
  final bool openingReplay;
  final LocalResumeFailureViewCode? resumeFailure;
  final ReplayFailureViewCode? replayFailure;
  final VoidCallback onResume;
  final VoidCallback onOpenReplay;
  final VoidCallback onStartSinglePlayer;
  final VoidCallback? onImportSave;
  final VoidCallback? onExportSave;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AonwSpacing.lg),
    children: [
      Center(
        child: AonwPanel(
          semanticLabel: context.aonwL10n.loadGameTitle,
          maxWidth: 760,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImportAction(onPressed: onImportSave),
              const SizedBox(height: AonwSpacing.lg),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (availability?.hasContent != true)
                _EmptySaves(onStartSinglePlayer: onStartSinglePlayer)
              else
                _LocalSaveCard(
                  availability: availability!,
                  busy: busy,
                  resuming: resuming,
                  openingReplay: openingReplay,
                  onResume: onResume,
                  onOpenReplay: onOpenReplay,
                  onExportSave: onExportSave,
                ),
              if (resumeFailure case final failure?) ...[
                const SizedBox(height: AonwSpacing.md),
                _FailureMessage(
                  key: const ValueKey('resume-failure'),
                  message: context.aonwL10n.resumeFailure(failure.name),
                ),
              ],
              if (replayFailure case final failure?) ...[
                const SizedBox(height: AonwSpacing.md),
                _FailureMessage(
                  key: const ValueKey('replay-failure'),
                  message: context.aonwL10n.replayFailure(failure.name),
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

final class _ImportAction extends StatelessWidget {
  const _ImportAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: onPressed == null ? context.aonwL10n.saveTransferUnavailable : '',
    child: OutlinedButton.icon(
      key: const ValueKey('import-save'),
      onPressed: onPressed,
      icon: const Icon(Icons.file_upload_outlined),
      label: Text(context.aonwL10n.importSave),
    ),
  );
}

final class _EmptySaves extends StatelessWidget {
  const _EmptySaves({required this.onStartSinglePlayer});

  final VoidCallback onStartSinglePlayer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.folder_off_outlined, size: 42),
      const SizedBox(height: AonwSpacing.md),
      Text(context.aonwL10n.loadGameEmpty),
      const SizedBox(height: AonwSpacing.lg),
      FilledButton.icon(
        key: const ValueKey('empty-start-single-player'),
        onPressed: onStartSinglePlayer,
        icon: const Icon(Icons.add),
        label: Text(context.aonwL10n.singlePlayer),
      ),
    ],
  );
}

final class _LocalSaveCard extends StatelessWidget {
  const _LocalSaveCard({
    required this.availability,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.onResume,
    required this.onOpenReplay,
    required this.onExportSave,
  });

  final _LoadAvailability availability;
  final bool busy;
  final bool resuming;
  final bool openingReplay;
  final VoidCallback onResume;
  final VoidCallback onOpenReplay;
  final VoidCallback? onExportSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loadGameSingleLabel(l10n.localScenarioName('starterDuel')),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AonwSpacing.md),
            Wrap(
              spacing: AonwSpacing.sm,
              runSpacing: AonwSpacing.sm,
              children: [
                FilledButton.icon(
                  key: const ValueKey('continue-game'),
                  onPressed: availability.hasSave && !busy ? onResume : null,
                  icon: _ProgressIcon(
                    active: resuming,
                    fallback: Icons.play_arrow,
                  ),
                  label: Text(resuming ? l10n.resumingGame : l10n.continueGame),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('open-replay'),
                  onPressed: availability.hasReplay && !busy
                      ? onOpenReplay
                      : null,
                  icon: _ProgressIcon(
                    active: openingReplay,
                    fallback: Icons.movie_filter_outlined,
                  ),
                  label: Text(
                    openingReplay ? l10n.loadingReplay : l10n.replayTitle,
                  ),
                ),
                Tooltip(
                  message: onExportSave == null
                      ? l10n.saveTransferUnavailable
                      : '',
                  child: OutlinedButton.icon(
                    key: const ValueKey('export-save'),
                    onPressed: availability.hasSave && !busy
                        ? onExportSave
                        : null,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(l10n.exportSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProgressIcon extends StatelessWidget {
  const _ProgressIcon({required this.active, required this.fallback});

  final bool active;
  final IconData fallback;

  @override
  Widget build(BuildContext context) => active
      ? const SizedBox.square(
          dimension: AonwSizes.compactProgress,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(fallback);
}

final class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
