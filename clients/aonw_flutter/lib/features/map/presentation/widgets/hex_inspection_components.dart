import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../cities/read_model/city_view.dart';

final class HexInspectionSection extends StatelessWidget {
  const HexInspectionSection({
    required this.title,
    required this.children,
    super.key,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        ...children,
      ],
    ),
  );
}

final class HexInspectionYield extends StatelessWidget {
  const HexInspectionYield({required this.value, super.key});
  final YieldValueView value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in [
          ('food', value.food),
          ('production', value.production),
          ('gold', value.gold),
          ('defense', value.defense),
        ])
          Text('${l10n.cityText(entry.$1)}: ${entry.$2}'),
      ],
    );
  }
}
