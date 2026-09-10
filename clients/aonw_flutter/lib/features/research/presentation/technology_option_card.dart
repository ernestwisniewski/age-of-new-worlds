part of 'research_overlay.dart';

final class _TechnologyOptionCard extends StatelessWidget {
  const _TechnologyOptionCard({
    required this.option,
    required this.enabled,
    required this.onSelect,
  });

  final ResearchOptionView option;
  final bool enabled;
  final ValueChanged<TechnologyIdView> onSelect;

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final available =
        option.availability == TechnologyAvailabilityView.available;
    String technologies(List<TechnologyIdView> values) => values.isEmpty
        ? copy.text(ResearchText.none)
        : values.map(copy.technology).join(', ');
    final unlocks = option.unlocks.isEmpty
        ? copy.text(ResearchText.none)
        : option.unlocks.map(copy.unlock).join(', ');
    final percent = option.boostDiscountBasisPoints / 100;
    return Card.outlined(
      key: ValueKey(('research-option', option.technology.name)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.technology(option.technology),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(copy.availability(option.availability)),
            Text(
              '${copy.text(ResearchText.progress)}: ${option.progress} / '
              '${option.effectiveCost} · ${copy.text(ResearchText.boost)}: '
              '${percent.toStringAsFixed(percent.truncateToDouble() == percent ? 0 : 2)}%',
            ),
            Text(
              '${copy.text(ResearchText.prerequisites)}: '
              '${technologies(option.prerequisites)}',
            ),
            Text(
              '${copy.text(ResearchText.blockedBy)}: '
              '${technologies(option.blockedBy)}',
            ),
            Text('${copy.text(ResearchText.unlocks)}: $unlocks'),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: ValueKey(('select-technology', option.technology.name)),
                onPressed: enabled && available
                    ? () => onSelect(option.technology)
                    : null,
                child: Text(copy.text(ResearchText.choose)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
