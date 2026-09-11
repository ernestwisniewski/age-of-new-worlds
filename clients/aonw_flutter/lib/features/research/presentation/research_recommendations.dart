part of 'research_overlay.dart';

/// Order and estimates come directly from the current recipient query.
final class _ResearchRecommendations extends StatelessWidget {
  const _ResearchRecommendations({
    required this.options,
    required this.enabled,
    required this.onSelect,
  });

  final ResearchOptionsView options;
  final bool enabled;
  final ValueChanged<TechnologyIdView> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = (constraints.maxWidth / (280 * scale)).floor().clamp(
        1,
        3,
      );
      return ListView.builder(
        key: const ValueKey('research-recommendations'),
        itemCount: (options.recommendations.length / columns).ceil(),
        itemBuilder: (context, row) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++)
              Expanded(child: _card(context, row * columns + column)),
          ],
        ),
      );
    },
  );

  Widget _card(BuildContext context, int index) {
    if (index >= options.recommendations.length) return const SizedBox.shrink();
    final recommendation = options.recommendations[index];
    final option = options.options.firstWhere(
      (option) => option.technology == recommendation.technology,
    );
    final copy = ResearchCopy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AonwSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.recommendationRank(index + 1),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (recommendation.turnsRemaining case final turns?)
                Text(copy.recommendationTurns(turns)),
              for (final reason in recommendation.reasons)
                Text(copy.recommendationReason(reason)),
            ],
          ),
        ),
        _TechnologyOptionCard(
          option: option,
          enabled: enabled,
          onSelect: onSelect,
        ),
      ],
    );
  }
}
