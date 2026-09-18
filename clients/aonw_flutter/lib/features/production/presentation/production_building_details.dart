import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_detail_copy.dart';
import 'production_detail_requirements.dart';
import 'production_detail_widgets.dart';

final class ProductionBuildingDetails extends StatelessWidget {
  const ProductionBuildingDetails({
    required this.option,
    required this.effects,
    super.key,
  });
  final ProductionOptionView option;
  final BuildingProductionDetailsView effects;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionDetailCopy.of(context);
    final lines = copy.buildingEffects(effects);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _impact(copy),
        ProductionDetailRequirements(
          option: option,
          requirements: effects.requirements,
        ),
        ProductionDetailSection(
          title: copy.l10n.technologyDetailsEffects,
          children: [
            for (final line
                in lines.isEmpty
                    ? [copy.l10n.technologyDetailsNoEffects]
                    : lines)
              ProductionDetailLine(line),
          ],
        ),
      ],
    );
  }

  Widget _impact(ProductionDetailCopy copy) {
    final a = effects.current;
    final b = effects.completed;
    final rows = [
      (
        copy.text(ProductionDetailText.storedFood),
        a.foodDeposit,
        b.foodDeposit,
        AonwColorTokens.success,
      ),
      (
        copy.l10n.cityText('production'),
        a.production,
        b.production,
        AonwColorTokens.brand,
      ),
      (copy.name('gold'), a.gold, b.gold, AonwColorTokens.resourcesAccent),
      (
        copy.l10n.resourceText('science'),
        a.science,
        b.science,
        AonwColorTokens.scienceAccent,
      ),
      (
        copy.l10n.cityText('defense'),
        a.grossYield.defense,
        b.grossYield.defense,
        AonwColorTokens.info,
      ),
      (
        copy.text(ProductionDetailText.tileLimit),
        a.maxControlledHexes,
        b.maxControlledHexes,
        AonwColorTokens.info,
      ),
    ].where((row) => row.$2 != row.$3).toList();
    return ProductionDetailSection(
      title: copy.l10n.buildingDetailsYieldImpact,
      children: [
        if (rows.isNotEmpty)
          Text(
            '${copy.l10n.visualCurrentLabel} → ${copy.l10n.visualAfterLabel}',
            style: AonwTextStyles.bodySmall,
          ),
        if (rows.isEmpty)
          ProductionDetailLine(copy.l10n.buildingDetailsNoYieldChange),
        for (final row in rows)
          ProductionDetailComparison(
            label: row.$1,
            before: row.$2,
            after: row.$3,
            color: row.$4,
            beforeLabel: copy.l10n.visualCurrentLabel,
            afterLabel: copy.l10n.visualAfterLabel,
          ),
      ],
    );
  }
}
