part of 'match_outcome_overlay.dart';

List<Widget> _outcomeMetrics(BuildContext context, _OutcomeSurface value) {
  final l10n = context.aonwL10n;
  final progress = value.progress;
  final condition = value.outcome.condition;
  final winner = value.outcome.winnerPlayerId;
  if (progress != null && condition == GameOutcomeConditionView.domination) {
    final entry = progress.domination
        .where((entry) => entry.playerId == winner)
        .firstOrNull;
    if (entry != null) {
      return [
        _OutcomeMetric(
          accent: value.tone.color,
          label: l10n.outcomePresentationText('control'),
          value: '${entry.controlledPassableHexes}/${entry.totalPassableHexes}',
          fraction: entry.totalPassableHexes == 0
              ? null
              : entry.controlledPassableHexes / entry.totalPassableHexes,
        ),
        _OutcomeMetric(
          accent: value.tone.color,
          label: l10n.resourceText('holdTurns'),
          value: '${entry.holdTurns}/${progress.dominationRequiredHoldTurns}',
        ),
        _OutcomeMetric(
          accent: value.tone.color,
          label: l10n.outcomePresentationText('threshold'),
          value: '${progress.dominationRequiredControlPercent}%',
        ),
      ];
    }
  }
  if (progress != null &&
      condition == GameOutcomeConditionView.cultural &&
      winner != null &&
      winner == value.actorPlayerId) {
    return [
      _OutcomeMetric(
        accent: value.tone.color,
        label: l10n.resourceText('artifacts'),
        value:
            '${progress.ownCultural.uniqueStoredArtifacts}'
            '/${progress.culturalRequiredArtifacts}',
      ),
      _OutcomeMetric(
        accent: value.tone.color,
        label: l10n.resourceText('holdTurns'),
        value:
            '${progress.ownCultural.holdTurns}'
            '/${progress.culturalRequiredHoldTurns}',
      ),
    ];
  }
  return _scoreMetrics(l10n, value);
}

List<Widget> _scoreMetrics(AonwLocalizations l10n, _OutcomeSurface value) {
  final scores = value.outcome.scoreByPlayerId.entries.toList()
    ..sort((left, right) {
      final order = right.value.compareTo(left.value);
      return order == 0 ? left.key.compareTo(right.key) : order;
    });
  if (scores.isEmpty) return const [];
  final maximum = scores.first.value;
  return [
    const SizedBox(height: AonwSpacing.lg),
    Text(l10n.outcomeFinalScore),
    for (final score in scores)
      _OutcomeMetric(
        accent: value.tone.color,
        key: ValueKey(('outcome-score', score.key)),
        label: value.playerNames[score.key] ?? score.key,
        value: score.value.toString(),
        fraction: maximum > 0 && score.value >= 0
            ? score.value / maximum
            : null,
      ),
  ];
}

final class _OutcomeMetric extends StatelessWidget {
  const _OutcomeMetric({
    required this.label,
    required this.value,
    required this.accent,
    this.fraction,
    super.key,
  });

  final Color accent;
  final String label;
  final String value;
  final double? fraction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AonwSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label)),
            const SizedBox(width: AonwSpacing.md),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: Text(value, textAlign: TextAlign.end),
              ),
            ),
          ],
        ),
        if (fraction case final amount?) ...[
          const SizedBox(height: AonwSpacing.xs),
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: amount.clamp(0, 1),
              minHeight: 5,
              color: accent,
              backgroundColor: AonwColorTokens.surfaceDeep,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ],
    ),
  );
}
