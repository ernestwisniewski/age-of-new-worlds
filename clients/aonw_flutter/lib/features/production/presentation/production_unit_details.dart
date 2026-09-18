import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../read_model/production_details_view.dart';
import '../read_model/production_view.dart';
import 'production_detail_copy.dart';
import 'production_detail_requirements.dart';
import 'production_detail_widgets.dart';

final class ProductionUnitDetails extends StatelessWidget {
  const ProductionUnitDetails({
    required this.option,
    required this.effects,
    super.key,
  });
  final ProductionOptionView option;
  final UnitProductionDetailsView effects;

  @override
  Widget build(BuildContext context) {
    final copy = ProductionDetailCopy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _combat(copy),
        ProductionDetailRequirements(
          option: option,
          extra: [
            if (effects.presenceResources.isNotEmpty)
              ProductionDetailLine(
                copy.l10n.buildingDetailsRequirementResources(
                  copy.alternatives(
                    effects.presenceResources.map(
                      (item) => copy.name(item.name),
                    ),
                  ),
                ),
                met: effects.presenceResourcesMet,
              ),
            if (!effects.coastMet)
              ProductionDetailLine(
                copy.l10n.buildingDetailsRequirementCoastalAccess,
                met: false,
              ),
          ],
        ),
        _logistics(copy),
        if (effects.resourceOptions.isNotEmpty) _resources(copy),
      ],
    );
  }

  Widget _combat(ProductionDetailCopy copy) {
    final base = effects.baseCombat;
    final effective = effects.effectiveCombat;
    final rows = [
      (
        copy.l10n.eventCombatStatAttack,
        base.attack,
        effective.attack,
        AonwColorTokens.brand,
      ),
      (
        copy.l10n.eventCombatStatDefense,
        base.defense,
        effective.defense,
        AonwColorTokens.info,
      ),
      (
        copy.l10n.eventCombatStatHp,
        base.hitPoints,
        effective.hitPoints,
        AonwColorTokens.success,
      ),
      (
        copy.l10n.eventCombatStatRange,
        base.range,
        effective.range,
        AonwColorTokens.resourcesAccent,
      ),
    ];
    return ProductionDetailSection(
      title: copy.l10n.unitDetailsCombat,
      children: [
        Text(
          '${copy.text(ProductionDetailText.base)} → ${copy.text(ProductionDetailText.effective)}',
          style: AonwTextStyles.bodySmall,
        ),
        for (final row in rows)
          ProductionDetailComparison(
            label: row.$1,
            before: row.$2,
            after: row.$3,
            color: row.$4,
            beforeLabel: copy.text(ProductionDetailText.base),
            afterLabel: copy.text(ProductionDetailText.effective),
          ),
      ],
    );
  }

  Widget _logistics(ProductionDetailCopy copy) => ProductionDetailSection(
    title: copy.l10n.technologyDetailsEffects,
    children: [
      ProductionDetailLine(
        '${copy.text(ProductionDetailText.movement)}: ${copy.number(effects.maximumMovementUnits / 2)}',
      ),
      ProductionDetailLine(
        '${copy.text(ProductionDetailText.upkeep)}: ${copy.number(effects.baseUpkeep)}',
      ),
      ProductionDetailLine(
        '${copy.text(ProductionDetailText.supplyCost)}: ${copy.number(effects.supplyCost)}',
      ),
      ProductionDetailLine(
        '${copy.text(ProductionDetailText.supplyUsed)}: '
        '${copy.number(effects.supplyUsedWithoutCityQueue)} / ${copy.number(effects.supplyCapacity)}',
      ),
    ],
  );

  Widget _resources(ProductionDetailCopy copy) => ProductionDetailSection(
    title: copy.text(ProductionDetailText.resourceOptions),
    children: [
      for (var index = 0; index < effects.resourceOptions.length; index++)
        ProductionDetailLine(
          copy.stockpile(effects.resourceOptions[index]),
          met: effects.affordableResourceOptionIndices.contains(index),
        ),
    ],
  );
}
