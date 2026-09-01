import 'dart:async';

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
import '../application/local_save_transfer.dart';

part 'load_game_save_card.dart';
part 'load_game_online_card.dart';
part 'load_game_feedback.dart';
part 'load_game_body.dart';

typedef LocalSaveIndexReader = Future<List<LocalSaveSummaryView>> Function();
typedef LocalGameResume =
    Future<LocalResumeResultView> Function(LocalGameScenarioView scenario);
typedef LocalReplayAvailabilityReader =
    Future<bool> Function(LocalGameScenarioView scenario);
typedef LocalReplayOpen =
    Future<ReplayOpenResultView> Function(LocalGameScenarioView scenario);
typedef LocalSaveImport = Future<LocalSaveTransferResultView> Function();
typedef LocalSaveExport =
    Future<LocalSaveTransferResultView> Function(
      LocalGameScenarioView scenario,
    );
typedef LocalArchiveAction =
    Future<void> Function(LocalGameScenarioView scenario);
typedef OnlineSaveIndexReader = OnlineSaveIndexView Function();
typedef OnlineGameResume = Future<bool> Function(String matchId);

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
    this.onlineChanges,
    this.initializeOnline,
    this.onlineIndex = _unavailableOnlineIndex,
    this.resumeOnlineGame = _unavailableOnlineResume,
    this.onOpenMultiplayer,
    super.key,
  });

  final LocalSaveIndexReader listLocalSaves;
  final LocalGameResume resumeLocalGame;
  final VoidCallback onResumed;
  final LocalReplayAvailabilityReader hasLocalReplay;
  final LocalReplayOpen openReplay;
  final VoidCallback onReplayOpened;
  final VoidCallback onStartSinglePlayer;
  final LocalSaveImport? onImportSave;
  final LocalSaveExport? onExportSave;
  final Listenable? onlineChanges;
  final Future<void> Function()? initializeOnline;
  final OnlineSaveIndexReader onlineIndex;
  final OnlineGameResume resumeOnlineGame;
  final VoidCallback? onOpenMultiplayer;

  @override
  State<LoadGameScreen> createState() => _LoadGameScreenState();
}

final class _LoadGameScreenState extends State<LoadGameScreen> {
  late Future<_LoadAvailability> _availability;
  var _resuming = false;
  var _openingReplay = false;
  var _resumingOnline = false;
  var _transferring = false;
  LocalGameScenarioView? _activeScenario;
  LocalGameScenarioView? _transferScenario;
  String? _activeOnlineMatchId;
  String? _onlineFailureCode;
  LocalResumeFailureViewCode? _resumeFailure;
  ReplayFailureViewCode? _replayFailure;
  _LocalSaveTransferAction? _transferAction;
  LocalSaveTransferResultView? _transferResult;

  @override
  void initState() {
    super.initState();
    _availability = _readAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.initializeOnline?.call());
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineChanges = widget.onlineChanges;
    if (onlineChanges == null) return _buildScaffold(context);
    return ListenableBuilder(
      listenable: onlineChanges,
      builder: (context, child) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.aonwL10n.loadGameTitle)),
    body: AonwMenuBackdrop(
      child: SafeArea(
        top: false,
        child: FutureBuilder<_LoadAvailability>(
          future: _availability,
          builder: (context, snapshot) => _LoadGameBody(
            availability: snapshot.data,
            loading: snapshot.connectionState != ConnectionState.done,
            busy: _busy || _resumingOnline,
            resuming: _resuming,
            openingReplay: _openingReplay,
            importing:
                _transferring &&
                _transferAction == _LocalSaveTransferAction.importSave,
            exportingScenario:
                _transferring &&
                    _transferAction == _LocalSaveTransferAction.exportSave
                ? _transferScenario
                : null,
            activeScenario: _activeScenario,
            resumeFailure: _resumeFailure,
            replayFailure: _replayFailure,
            onResume: _resume,
            onOpenReplay: _openReplay,
            onStartSinglePlayer: widget.onStartSinglePlayer,
            transferAction: _transferAction,
            transferResult: _transferResult,
            onImportSave: widget.onImportSave == null ? null : _importSave,
            onExportSave: widget.onExportSave == null ? null : _exportSave,
            onlineIndex: widget.onlineIndex(),
            resumingOnline: _resumingOnline,
            activeOnlineMatchId: _activeOnlineMatchId,
            onlineFailureCode: _onlineFailureCode,
            onResumeOnline: _resumeOnline,
            onOpenMultiplayer: widget.onOpenMultiplayer,
          ),
        ),
      ),
    ),
  );

  bool get _busy => _resuming || _openingReplay || _transferring;

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
      _transferResult = null;
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
      _transferResult = null;
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

  Future<void> _resumeOnline(String matchId) async {
    setState(() {
      _resumingOnline = true;
      _activeOnlineMatchId = matchId;
      _onlineFailureCode = null;
      _resumeFailure = null;
      _replayFailure = null;
      _transferResult = null;
    });
    final opened = await widget.resumeOnlineGame(matchId);
    if (!mounted) return;
    setState(() {
      _resumingOnline = false;
      _activeOnlineMatchId = null;
      if (!opened) _onlineFailureCode = 'multiplayer_match_open_failed';
    });
  }

  Future<void> _importSave() => _runTransfer(
    action: _LocalSaveTransferAction.importSave,
    operation: widget.onImportSave!,
  );

  Future<void> _exportSave(LocalGameScenarioView scenario) => _runTransfer(
    action: _LocalSaveTransferAction.exportSave,
    scenario: scenario,
    operation: () => widget.onExportSave!(scenario),
  );

  Future<void> _runTransfer({
    required _LocalSaveTransferAction action,
    required Future<LocalSaveTransferResultView> Function() operation,
    LocalGameScenarioView? scenario,
  }) async {
    if (_transferring) return;
    setState(() {
      _transferring = true;
      _transferAction = action;
      _transferScenario = scenario;
      _transferResult = null;
      _onlineFailureCode = null;
      _resumeFailure = null;
      _replayFailure = null;
    });
    late final LocalSaveTransferResultView result;
    try {
      result = await operation();
    } on Object {
      result = LocalSaveTransferResultView.failed(
        action == _LocalSaveTransferAction.importSave
            ? LocalSaveTransferFailureViewCode.unreadable
            : LocalSaveTransferFailureViewCode.exportFailed,
      );
    }
    if (!mounted) return;
    setState(() {
      _transferring = false;
      _transferScenario = null;
      _transferResult = result;
      if (result.completed && action == _LocalSaveTransferAction.importSave) {
        _availability = _readAvailability();
      }
    });
  }
}

enum _LocalSaveTransferAction { importSave, exportSave }

OnlineSaveIndexView _unavailableOnlineIndex() =>
    const OnlineSaveIndexView(phase: OnlineSaveIndexPhaseView.unavailable);

Future<bool> _unavailableOnlineResume(String matchId) async => false;

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
