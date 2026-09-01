part of 'load_game_screen.dart';

final class _LocalSaveCard extends StatelessWidget {
  const _LocalSaveCard({
    required this.entry,
    required this.busy,
    required this.resuming,
    required this.openingReplay,
    required this.exporting,
    required this.onResume,
    required this.onOpenReplay,
    required this.onExportSave,
  });

  final _LoadEntry entry;
  final bool busy;
  final bool resuming;
  final bool openingReplay;
  final bool exporting;
  final VoidCallback? onResume;
  final VoidCallback onOpenReplay;
  final VoidCallback? onExportSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final save = entry.save;
    final compatible = save?.compatible == true;
    return Card(
      key: ValueKey('local-save-${entry.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              save?.slot.name ?? l10n.localScenarioName(entry.scenario.name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AonwSpacing.xs),
            Text(
              '${_modeName(context)} · '
              '${l10n.localScenarioName(entry.scenario.name)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AonwSpacing.xs),
            Text(
              _metadata(context, save),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AonwSpacing.md),
            _SaveCardActions(
              saveId: save?.slot.id ?? entry.id,
              scenario: entry.scenario,
              canResume: compatible && !busy,
              canReplay: entry.hasReplay && !busy,
              canExport: compatible && !busy,
              resuming: resuming,
              openingReplay: openingReplay,
              exporting: exporting,
              onResume: onResume,
              onOpenReplay: onOpenReplay,
              onExportSave: onExportSave,
            ),
          ],
        ),
      ),
    );
  }

  String _modeName(BuildContext context) => switch (entry.save?.gameMode) {
    LocalSaveGameModeView.singlePlayer => context.aonwL10n.singlePlayer,
    LocalSaveGameModeView.hotseat => context.aonwL10n.hotseat,
    null => context.aonwL10n.loadGame,
  };

  String _metadata(BuildContext context, LocalSaveSummaryView? save) {
    final l10n = context.aonwL10n;
    if (save?.compatible != true) {
      return l10n.resumeFailure(LocalResumeFailureViewCode.incompatible.name);
    }
    final savedAt = save!.slot.savedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(savedAt);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(savedAt),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '${l10n.multiplayerTurn(save.turn!)} · '
        '${l10n.turnModeName(save.turnMode!.name)} · $date $time';
  }
}

final class _SaveCardActions extends StatelessWidget {
  const _SaveCardActions({
    required this.saveId,
    required this.scenario,
    required this.canResume,
    required this.canReplay,
    required this.canExport,
    required this.resuming,
    required this.openingReplay,
    required this.exporting,
    required this.onResume,
    required this.onOpenReplay,
    required this.onExportSave,
  });

  final String saveId;
  final LocalGameScenarioView scenario;
  final bool canResume;
  final bool canReplay;
  final bool canExport;
  final bool resuming;
  final bool openingReplay;
  final bool exporting;
  final VoidCallback? onResume;
  final VoidCallback onOpenReplay;
  final VoidCallback? onExportSave;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AonwSpacing.sm,
    runSpacing: AonwSpacing.sm,
    children: [
      _ResumeSaveButton(
        saveId: saveId,
        enabled: canResume,
        active: resuming,
        onPressed: onResume,
      ),
      _OpenReplayButton(
        scenario: scenario,
        enabled: canReplay,
        active: openingReplay,
        onPressed: onOpenReplay,
      ),
      _ExportSaveButton(
        saveId: saveId,
        enabled: canExport,
        active: exporting,
        onPressed: onExportSave,
      ),
    ],
  );
}

final class _ResumeSaveButton extends StatelessWidget {
  const _ResumeSaveButton({
    required this.saveId,
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final String saveId;
  final bool enabled;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: ValueKey('continue-game-$saveId'),
    onPressed: enabled ? onPressed : null,
    icon: _ProgressIcon(active: active, fallback: Icons.play_arrow),
    label: Text(
      active ? context.aonwL10n.resumingGame : context.aonwL10n.continueGame,
    ),
  );
}

final class _OpenReplayButton extends StatelessWidget {
  const _OpenReplayButton({
    required this.scenario,
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final LocalGameScenarioView scenario;
  final bool enabled;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: ValueKey('open-replay-${scenario.name}'),
    onPressed: enabled ? onPressed : null,
    icon: _ProgressIcon(active: active, fallback: Icons.movie_filter_outlined),
    label: Text(
      active ? context.aonwL10n.loadingReplay : context.aonwL10n.replayTitle,
    ),
  );
}

final class _ExportSaveButton extends StatelessWidget {
  const _ExportSaveButton({
    required this.saveId,
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final String saveId;
  final bool enabled;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: onPressed == null ? context.aonwL10n.saveTransferUnavailable : '',
    child: OutlinedButton.icon(
      key: ValueKey('export-save-$saveId'),
      onPressed: enabled ? onPressed : null,
      icon: _ProgressIcon(
        active: active,
        fallback: Icons.file_download_outlined,
      ),
      label: Text(context.aonwL10n.exportSave),
    ),
  );
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
