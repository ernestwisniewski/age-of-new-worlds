part of 'research_overlay.dart';

final class _ResearchCatalog extends StatelessWidget {
  const _ResearchCatalog({
    required this.options,
    required this.enabled,
    required this.onSelect,
  });

  final List<ResearchOptionView> options;
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
      return FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: ListView.builder(
          key: const ValueKey('research-options'),
          itemCount: (options.length / columns).ceil(),
          itemBuilder: (context, row) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < columns; column++)
                Expanded(child: _card(row * columns + column)),
            ],
          ),
        ),
      );
    },
  );

  Widget _card(int index) => index >= options.length
      ? const SizedBox.shrink()
      : _TechnologyOptionCard(
          option: options[index],
          enabled: enabled,
          onSelect: onSelect,
        );
}
