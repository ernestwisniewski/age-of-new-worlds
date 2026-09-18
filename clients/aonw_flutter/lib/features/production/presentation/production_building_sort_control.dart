import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../l10n/l10n.dart';
import 'production_building_sort.dart';

final class ProductionBuildingSortControl extends StatelessWidget {
  const ProductionBuildingSortControl({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ProductionBuildingSort value;
  final ValueChanged<ProductionBuildingSort> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AonwSpacing.sm),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: context.aonwL10n.cityProductionSortLabel,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AonwSpacing.sm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductionBuildingSort>(
          key: const ValueKey('production-building-sort'),
          value: value,
          isExpanded: true,
          itemHeight: null,
          menuMaxHeight: MediaQuery.sizeOf(context).height * 0.65,
          dropdownColor: AonwColorTokens.surface,
          style: AonwTextStyles.bodyStrong,
          items: [
            for (final mode in ProductionBuildingSort.values)
              DropdownMenuItem(
                value: mode,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
                  child: Text(
                    mode.label(context.aonwL10n),
                    key: ValueKey('sort-${mode.name}'),
                  ),
                ),
              ),
          ],
          onChanged: (mode) {
            if (mode != null) onChanged(mode);
          },
        ),
      ),
    ),
  );
}

final class ProductionBuildingHeader extends StatelessWidget {
  const ProductionBuildingHeader({
    required this.title,
    required this.sort,
    required this.onChanged,
    super.key,
  });
  final String title;
  final ProductionBuildingSort? sort;
  final ValueChanged<ProductionBuildingSort> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AonwSpacing.sm),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Text(title, style: AonwTextStyles.sectionHeader);
        final value = sort;
        if (value == null) return titleWidget;
        final control = ProductionBuildingSortControl(
          value: value,
          onChanged: onChanged,
        );
        if (constraints.maxWidth >= 600 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20) {
          return Row(
            children: [
              Expanded(child: titleWidget),
              SizedBox(width: 300, child: control),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleWidget,
            const SizedBox(height: AonwSpacing.sm),
            control,
          ],
        );
      },
    ),
  );
}
