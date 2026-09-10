part of 'match_history_section.dart';

final class _MatchHistoryCard extends StatelessWidget {
  const _MatchHistoryCard({
    required this.entry,
    this.onReplay,
    this.replaying = false,
  });

  final MatchHistoryEntryView entry;
  final VoidCallback? onReplay;
  final bool replaying;

  @override
  Widget build(BuildContext context) {
    final copy = context.aonwL10n;
    final endedAt = entry.endedAt;
    final condition = entry.outcomeCondition;
    return Card(
      key: ValueKey(('match-history-entry', entry.match.matchId)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mapName(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(copy.matchIdentifier(entry.match.matchId)),
            Text('${copy.historyText('turn')}: ${entry.turn}'),
            if (endedAt != null)
              Text(DateFormat.yMMMd(copy.localeName).format(endedAt.toLocal())),
            if (condition != null && condition.isNotEmpty)
              Text(
                copy.turnText(
                  'outcome${condition[0].toUpperCase()}${condition.substring(1)}',
                ),
              ),
            if (entry.winnerPlayerId case final winner?)
              Text(
                winner == entry.playerId
                    ? copy.historyText('won')
                    : copy.historyText('lost'),
              ),
            if (entry.resignedAt != null) Text(copy.historyText('resigned')),
            if (entry.kickedAt != null) Text(copy.historyText('removed')),
            if (entry.replayAvailable) _replayButton(context),
          ],
        ),
      ),
    );
  }

  Widget _replayButton(BuildContext context) {
    final copy = context.aonwL10n;
    return OutlinedButton.icon(
      key: ValueKey(('history-replay', entry.match.matchId)),
      onPressed: onReplay,
      icon: replaying
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.movie_filter_outlined),
      label: Text(replaying ? copy.loadingReplay : copy.replayTitle),
    );
  }

  String _mapName(BuildContext context) {
    final scenario = LocalGameCatalog.entries
        .where((scenario) => scenario.mapId == entry.match.mapId)
        .firstOrNull;
    return scenario == null
        ? entry.match.mapId
        : context.aonwL10n.localScenarioName(scenario.id.name);
  }
}
