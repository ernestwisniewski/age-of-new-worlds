import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../../replay/application/replay_state.dart';
import '../../replay/presentation/replay_presentation_controller.dart';
import '../application/local_save_state.dart';
import '../application/local_save_summary.dart';

part 'load_game_save_card.dart';

typedef LocalSaveIndexReader = Future<List<LocalSaveSummaryView>> Function();
typedef LocalGameResume =
    Future<LocalResumeResultView> Function(LocalGameScenarioView scenario);
typedef LocalReplayAvailabilityReader =
    Future<bool> Function(LocalGameScenarioView scenario);
typedef LocalReplayOpen =
    Future<ReplayOpenResultView> Function(LocalGameScenarioView scenario);
typedef LocalSaveExport = void Function(LocalGameScenarioView scenario);
typedef LocalArchiveAction =
    Future<void> Function(LocalGameScenarioView scenario);

final class LoadGameScreen extends StatefulWidget {
  const LoadGameScreen({
    required this.listLocalSaves,
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

  final LocalSaveIndexReader listLocalSaves;
  final LocalGameResume resumeLocalGame;
  final VoidCallback onResumed;
  final LocalReplayAvailabilityReader hasLocalReplay;
  final LocalReplayOpen openReplay;
  final VoidCallback onReplayOpened;
  final VoidCallback onStartSinglePlayer;
  final VoidCallback? onImportSave;
  final LocalSaveExport? onExportSave;

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

final class _LoadGameScreenState extends State<LoadGameScreen> {
  late Future<_LoadAvailability> _availability;
  var _resuming = false;
  var _openingReplay = false;
  LocalGameScenarioView? _activeScenario;
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
            activeScenario: _activeScenario,
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
    final saves = await widget.listLocalSaves();
    final savesByScenario = {for (final save in saves) save.scenario: save};
    final replayAvailability = await Future.wait([
      for (final entry in LocalGameCatalog.entries)
        widget.hasLocalReplay(entry.id),
    ]);
    return _LoadAvailability([
      for (var index = 0; index < LocalGameCatalog.entries.length; index += 1)
        if (savesByScenario[LocalGameCatalog.entries[index].id] != null ||
            replayAvailability[index])
          _LoadEntry(
            scenario: LocalGameCatalog.entries[index].id,
            save: savesByScenario[LocalGameCatalog.entries[index].id],
            hasReplay: replayAvailability[index],
          ),
    ]);
  }

  Future<void> _resume(LocalGameScenarioView scenario) async {
    setState(() {
      _resuming = true;
      _activeScenario = scenario;
      _resumeFailure = null;
      _replayFailure = null;
    });
    final result = await widget.resumeLocalGame(scenario);
    if (!mounted) return;
    if (result.started) {
      setState(() {
        _resuming = false;
        _activeScenario = null;
      });
      widget.onResumed();
      return;
    }
    setState(() {
      _resuming = false;
      _activeScenario = null;
      _resumeFailure = result.failure;
      _availability = _readAvailability();
    });
  }

  Future<void> _openReplay(LocalGameScenarioView scenario) async {
    setState(() {
      _openingReplay = true;
      _activeScenario = scenario;
      _resumeFailure = null;
      _replayFailure = null;
    });
    final result = await widget.openReplay(scenario);
    if (!mounted) return;
    if (result.started) {
      widget.onReplayOpened();
      setState(() {
        _openingReplay = false;
        _activeScenario = null;
      });
      return;
    }
    setState(() {
      _openingReplay = false;
      _activeScenario = null;
      _replayFailure = result.failure;
      _availability = _readAvailability();
    });
  }
}

final class _LoadAvailability {
  _LoadAvailability(List<_LoadEntry> entries)
    : entries = List.unmodifiable(entries);

  final List<_LoadEntry> entries;

  bool get hasContent => entries.isNotEmpty;
}

final class _LoadEntry {
  const _LoadEntry({
    required this.scenario,
    required this.save,
    required this.hasReplay,
  });

  final LocalGameScenarioView scenario;
  final LocalSaveSummaryView? save;
  final bool hasReplay;
}

final class _LoadGameBody extends StatelessWidget {
  const _LoadGameBody({
    required this.availability,
    required this.loading,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.activeScenario,
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
  final LocalGameScenarioView? activeScenario;
  final LocalResumeFailureViewCode? resumeFailure;
  final ReplayFailureViewCode? replayFailure;
  final LocalArchiveAction onResume;
  final LocalArchiveAction onOpenReplay;
  final VoidCallback onStartSinglePlayer;
  final VoidCallback? onImportSave;
  final LocalSaveExport? onExportSave;

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
                for (final entry in availability!.entries) ...[
                  _LocalSaveCard(
                    entry: entry,
                    busy: busy,
                    resuming: resuming && activeScenario == entry.scenario,
                    openingReplay:
                        openingReplay && activeScenario == entry.scenario,
                    onResume: () => onResume(entry.scenario),
                    onOpenReplay: () => onOpenReplay(entry.scenario),
                    onExportSave: onExportSave == null
                        ? null
                        : () => onExportSave!(entry.scenario),
                  ),
                  const SizedBox(height: AonwSpacing.md),
                ],
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
