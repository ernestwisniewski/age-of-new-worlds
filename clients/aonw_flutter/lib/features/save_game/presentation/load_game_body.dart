part of 'load_game_screen.dart';

final class _LoadGameBody extends StatelessWidget {
  const _LoadGameBody({
    required this.availability,
    required this.loading,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.importing,
    required this.exportingSaveId,
    required this.activeSaveId,
    required this.activeReplayScenario,
    required this.resumeFailure,
    required this.replayFailure,
    required this.onResume,
    required this.onOpenReplay,
    required this.onStartSinglePlayer,
    required this.onImportSave,
    required this.onExportSave,
    required this.transferAction,
    required this.transferResult,
    required this.onlineIndex,
    required this.resumingOnline,
    required this.activeOnlineMatchId,
    required this.onlineFailureCode,
    required this.onResumeOnline,
    required this.onOpenMultiplayer,
  });

  final _LoadAvailability? availability;
  final bool loading;
  final bool busy;
  final bool resuming;
  final bool openingReplay;
  final bool importing;
  final String? exportingSaveId;
  final String? activeSaveId;
  final LocalGameScenarioView? activeReplayScenario;
  final LocalResumeFailureViewCode? resumeFailure;
  final ReplayFailureViewCode? replayFailure;
  final LocalArchiveAction onResume;
  final LocalReplayAction onOpenReplay;
  final VoidCallback onStartSinglePlayer;
  final VoidCallback? onImportSave;
  final LocalArchiveAction? onExportSave;
  final _LocalSaveTransferAction? transferAction;
  final LocalSaveTransferResultView? transferResult;
  final OnlineSaveIndexView onlineIndex;
  final bool resumingOnline;
  final String? activeOnlineMatchId;
  final String? onlineFailureCode;
  final Future<void> Function(String matchId) onResumeOnline;
  final VoidCallback? onOpenMultiplayer;

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
              _ImportAction(
                onPressed: onImportSave,
                enabled: !busy,
                active: importing,
              ),
              const SizedBox(height: AonwSpacing.lg),
              _LocalSaveSection(
                availability: availability,
                loading: loading,
                hasOnlineContent: _hasOnlineContent,
                busy: busy,
                resuming: resuming,
                openingReplay: openingReplay,
                exportingSaveId: exportingSaveId,
                activeSaveId: activeSaveId,
                activeReplayScenario: activeReplayScenario,
                onResume: onResume,
                onOpenReplay: onOpenReplay,
                onStartSinglePlayer: onStartSinglePlayer,
                onExportSave: onExportSave,
              ),
              _OnlineSaveSection(
                index: onlineIndex,
                busy: busy,
                resuming: resumingOnline,
                activeMatchId: activeOnlineMatchId,
                onResume: onResumeOnline,
                onOpenMultiplayer: onOpenMultiplayer,
              ),
              _LoadFailureMessages(
                onlineFailureCode: onlineFailureCode,
                resumeFailure: resumeFailure,
                replayFailure: replayFailure,
                transferAction: transferAction,
                transferResult: transferResult,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  bool get _hasOnlineContent => switch (onlineIndex.phase) {
    OnlineSaveIndexPhaseView.unavailable => false,
    OnlineSaveIndexPhaseView.ready =>
      onlineIndex.saves.isNotEmpty || onlineIndex.failureCode != null,
    _ => true,
  };
}

final class _LocalSaveSection extends StatelessWidget {
  const _LocalSaveSection({
    required this.availability,
    required this.loading,
    required this.hasOnlineContent,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.exportingSaveId,
    required this.activeSaveId,
    required this.activeReplayScenario,
    required this.onResume,
    required this.onOpenReplay,
    required this.onStartSinglePlayer,
    required this.onExportSave,
  });

  final _LoadAvailability? availability;
  final bool loading;
  final bool hasOnlineContent;
  final bool busy;
  final bool resuming;
  final bool openingReplay;
  final String? exportingSaveId;
  final String? activeSaveId;
  final LocalGameScenarioView? activeReplayScenario;
  final LocalArchiveAction onResume;
  final LocalReplayAction onOpenReplay;
  final VoidCallback onStartSinglePlayer;
  final LocalArchiveAction? onExportSave;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (availability?.hasContent != true && !hasOnlineContent) {
      return _EmptySaves(onStartSinglePlayer: onStartSinglePlayer);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in availability?.entries ?? const <_LoadEntry>[])
          Padding(
            padding: const EdgeInsets.only(bottom: AonwSpacing.md),
            child: _LocalSaveCard(
              entry: entry,
              busy: busy,
              resuming: resuming && activeSaveId == entry.save?.slot.id,
              openingReplay:
                  openingReplay && activeReplayScenario == entry.scenario,
              exporting: exportingSaveId == entry.save?.slot.id,
              onResume: entry.save == null
                  ? null
                  : () => onResume(entry.save!.slot),
              onOpenReplay: () => onOpenReplay(entry.scenario),
              onExportSave: onExportSave == null
                  ? null
                  : entry.save == null
                  ? null
                  : () => onExportSave!(entry.save!.slot),
            ),
          ),
      ],
    );
  }
}
