import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_view.dart';
import 'production_copy.dart';

final class ProductionBuildingChoices extends StatelessWidget {
  const ProductionBuildingChoices({
    required this.cityId,
    required this.options,
    required this.choice,
    super.key,
  });

  final String cityId;
  final List<ProductionOptionView> options;
  final Widget Function(ProductionOptionView) choice;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionCopy.of(context);
    final current = <ProductionOptionView>[];
    final future = <ProductionOptionView>[];
    final completed = <ProductionOptionView>[];
    for (final option in options) {
      if (option.availability.completedInCity) {
        completed.add(option);
      } else if (option.availability.technologyUnlocked) {
        current.add(option);
      } else {
        future.add(option);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (current.isNotEmpty) ...[
          Text(
            copy.text(ProductionText.buildings),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          _choices(current),
        ],
        if (future.isNotEmpty)
          ExpansionTile(
            key: ValueKey(('production-future-buildings', cityId)),
            tilePadding: EdgeInsets.zero,
            title: Text(copy.text(ProductionText.futureBuildings)),
            subtitle: Text(copy.text(ProductionText.futureBuildingsHint)),
            children: [_choices(future)],
          ),
        if (completed.isNotEmpty)
          ExpansionTile(
            key: ValueKey(('production-completed-buildings', cityId)),
            tilePadding: EdgeInsets.zero,
            title: Text(copy.text(ProductionText.completedBuildings)),
            children: [_choices(completed)],
          ),
      ],
    );
  }

  Widget _choices(List<ProductionOptionView> values) => Align(
    alignment: Alignment.centerLeft,
    child: Wrap(
      spacing: AonwSpacing.xs,
      runSpacing: AonwSpacing.xs,
      children: values.map(choice).toList(growable: false),
    ),
  );
}
