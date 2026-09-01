part of 'load_game_screen.dart';

final class _OnlineSaveSection extends StatelessWidget {
  const _OnlineSaveSection({
    required this.index,
    required this.busy,
    required this.resuming,
    required this.activeMatchId,
    required this.onResume,
    required this.onOpenMultiplayer,
  });

  final OnlineSaveIndexView index;
  final bool busy;
  final bool resuming;
  final String? activeMatchId;
  final Future<void> Function(String matchId) onResume;
  final VoidCallback? onOpenMultiplayer;

  @override
  Widget build(BuildContext context) => switch (index.phase) {
    OnlineSaveIndexPhaseView.unavailable => const SizedBox.shrink(),
    OnlineSaveIndexPhaseView.loading => _OnlineLoading(
      label: context.aonwL10n.loadingMultiplayer,
    ),
    OnlineSaveIndexPhaseView.signedOut => _OnlineSignedOut(
      failureCode: index.failureCode,
      onOpenMultiplayer: onOpenMultiplayer,
    ),
    OnlineSaveIndexPhaseView.failed => _FailureMessage(
      message: context.aonwL10n.multiplayerFailure(
        index.failureCode ?? 'unexpected_failure',
      ),
    ),
    OnlineSaveIndexPhaseView.ready => _OnlineSaveList(
      saves: index.saves,
      failureCode: index.failureCode,
      busy: busy,
      resuming: resuming,
      activeMatchId: activeMatchId,
      onResume: onResume,
    ),
  };
}

final class _OnlineLoading extends StatelessWidget {
  const _OnlineLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AonwSpacing.md),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: AonwSizes.compactProgress,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AonwSpacing.sm),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

final class _OnlineSignedOut extends StatelessWidget {
  const _OnlineSignedOut({
    required this.failureCode,
    required this.onOpenMultiplayer,
  });

  final String? failureCode;
  final VoidCallback? onOpenMultiplayer;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('online-saves-signed-out'),
    child: Padding(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.aonwL10n.multiplayerAuthenticationTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (failureCode case final code?) ...[
            const SizedBox(height: AonwSpacing.xs),
            Text(context.aonwL10n.multiplayerFailure(code)),
          ],
          const SizedBox(height: AonwSpacing.md),
          OutlinedButton.icon(
            key: const ValueKey('open-online-sign-in'),
            onPressed: onOpenMultiplayer,
            icon: const Icon(Icons.login),
            label: Text(context.aonwL10n.signIn),
          ),
        ],
      ),
    ),
  );
}

final class _OnlineSaveList extends StatelessWidget {
  const _OnlineSaveList({
    required this.saves,
    required this.failureCode,
    required this.busy,
    required this.resuming,
    required this.activeMatchId,
    required this.onResume,
  });

  final List<OnlineSaveSummaryView> saves;
  final String? failureCode;
  final bool busy;
  final bool resuming;
  final String? activeMatchId;
  final Future<void> Function(String matchId) onResume;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final save in saves) ...[
        _OnlineSaveCard(
          save: save,
          busy: busy,
          resuming: resuming && activeMatchId == save.matchId,
          onResume: () => onResume(save.matchId),
        ),
        const SizedBox(height: AonwSpacing.md),
      ],
      if (failureCode case final code?)
        _FailureMessage(message: context.aonwL10n.multiplayerFailure(code)),
    ],
  );
}

final class _OnlineSaveCard extends StatelessWidget {
  const _OnlineSaveCard({
    required this.save,
    required this.busy,
    required this.resuming,
    required this.onResume,
  });

  final OnlineSaveSummaryView save;
  final bool busy;
  final bool resuming;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('online-save-${save.matchId}'),
    child: Padding(
      padding: const EdgeInsets.all(AonwSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.aonwL10n.multiplayerTitle} · ${_mapName(context)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AonwSpacing.xs),
          Text(context.aonwL10n.matchIdentifier(save.matchId)),
          const SizedBox(height: AonwSpacing.xs),
          Text(context.aonwL10n.multiplayerMatchPhase(save.phase.name)),
          const SizedBox(height: AonwSpacing.md),
          _OnlineSaveActions(
            matchId: save.matchId,
            enabled: !busy,
            resuming: resuming,
            onResume: onResume,
          ),
        ],
      ),
    ),
  );

  String _mapName(BuildContext context) {
    for (final entry in LocalGameCatalog.entries) {
      if (entry.mapId == save.mapId) {
        return context.aonwL10n.localScenarioName(entry.id.name);
      }
    }
    return save.mapId;
  }
}

final class _OnlineSaveActions extends StatelessWidget {
  const _OnlineSaveActions({
    required this.matchId,
    required this.enabled,
    required this.resuming,
    required this.onResume,
  });

  final String matchId;
  final bool enabled;
  final bool resuming;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AonwSpacing.sm,
    runSpacing: AonwSpacing.sm,
    children: [
      FilledButton.icon(
        key: ValueKey('continue-online-$matchId'),
        onPressed: enabled ? onResume : null,
        icon: _ProgressIcon(active: resuming, fallback: Icons.public),
        label: Text(
          resuming
              ? context.aonwL10n.resumingGame
              : context.aonwL10n.continueGame,
        ),
      ),
      Tooltip(
        message: context.aonwL10n.replayFailure(
          ReplayFailureViewCode.unavailable.name,
        ),
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.movie_filter_outlined),
          label: Text(context.aonwL10n.replayTitle),
        ),
      ),
      Tooltip(
        message: context.aonwL10n.saveTransferUnavailable,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.file_download_outlined),
          label: Text(context.aonwL10n.exportSave),
        ),
      ),
    ],
  );
}
