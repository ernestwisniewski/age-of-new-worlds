import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../cities/read_model/city_view.dart';
import '../../map/read_model/map_view.dart';
import '../read_model/production_details_view.dart';

enum ProductionDetailText {
  storedFood,
  tileLimit,
  base,
  effective,
  upkeep,
  supplyUsed,
  supplyCost,
  resourceOptions,
  riverApplications,
  movement,
}

final class ProductionDetailCopy {
  ProductionDetailCopy.of(BuildContext context) : l10n = context.aonwL10n;

  final AonwLocalizations l10n;

  String text(ProductionDetailText key) => l10n.productionDetailText(key.name);
  String number(num value) =>
      NumberFormat.decimalPattern(l10n.localeName).format(value);
  String signed(num value) => '${value > 0 ? '+' : ''}${number(value)}';
  String percent(int basisPoints) => '${signed(basisPoints / 100)}%';
  String name(String key) => l10n.presentationName(key);

  String alternatives(Iterable<String> values) {
    final items = values.toList();
    if (items.length < 2) return items.join();
    return l10n.commonListOr(
      items.take(items.length - 1).join(', '),
      items.last,
    );
  }

  String requirement(ProductionRequirementView value) => switch (value.kind) {
    ProductionRequirementKindView.coastalAccess =>
      l10n.buildingDetailsRequirementCoastalAccess,
    ProductionRequirementKindView.adjacentRiver =>
      l10n.wonderDetailsRequirementAdjacentRiver,
    ProductionRequirementKindView.adjacentMountain =>
      l10n.wonderDetailsRequirementAdjacentMountain,
    ProductionRequirementKindView.resourceAny =>
      l10n.buildingDetailsRequirementResources(
        alternatives(value.resources.map((item) => name(item.name))),
      ),
    ProductionRequirementKindView.hostTerrainAny =>
      l10n.wonderDetailsRequirementTerrain(
        alternatives(
          value.terrains.map((item) => l10n.hexInspectionTerrain(item.name)),
        ),
      ),
  };

  String stockpile(Map<MapResource, int> values) => values.entries
      .map((item) => '${name(item.key.name)} ${number(item.value)}')
      .join(' + ');

  List<String> yieldParts(YieldValueView value) => [
    if (value.food != 0) l10n.buildingDetailsYieldFood(signed(value.food)),
    if (value.production != 0)
      l10n.buildingDetailsYieldProduction(signed(value.production)),
    if (value.gold != 0) l10n.buildingDetailsYieldGold(signed(value.gold)),
    if (value.defense != 0)
      l10n.buildingDetailsYieldDefense(signed(value.defense)),
  ];

  List<String> buildingEffects(BuildingProductionDetailsView value) {
    final flat = yieldParts(value.flatYield);
    final river = yieldParts(value.riverYieldPerHex);
    return [
      if (flat.isNotEmpty) l10n.buildingDetailsFlatYieldEffect(flat.join(', ')),
      if (river.isNotEmpty) ...[
        l10n.buildingDetailsRiverHexYieldEffectWithMax(
          river.join(', '),
          value.maxRiverApplications,
        ),
        '${text(ProductionDetailText.riverApplications)}: ${number(value.riverApplications)}',
      ],
      if (value.sciencePerTurn != 0)
        l10n.buildingDetailsYieldScience(signed(value.sciencePerTurn)),
      if (value.maxControlledHexesDelta != 0)
        l10n.buildingDetailsMaxControlledHexesEffect(
          value.maxControlledHexesDelta,
        ),
      if (value.foodDepositBasisPoints != 10000)
        l10n.buildingDetailsFoodDepositMultiplierEffect(
          number((value.foodDepositBasisPoints - 10000) / 100),
        ),
    ];
  }

  List<String> wonderStanding(WonderProductionDetailsView value) {
    final host = yieldParts(value.hostYield);
    final empire = yieldParts(value.empireYieldPerCity);
    return [
      if (host.isNotEmpty)
        l10n.wonderDetailsHostCityFlatYieldEffect(host.join(', ')),
      if (empire.isNotEmpty)
        l10n.wonderDetailsEmpireFlatYieldEffect(empire.join(', ')),
      if (value.empireSciencePerCity != 0)
        l10n.wonderDetailsEmpireScienceEffect(
          signed(value.empireSciencePerCity),
        ),
      if (value.empireGoldBasisPoints != 0)
        l10n.wonderDetailsEmpireGoldMultiplierEffect(
          percent(value.empireGoldBasisPoints),
        ),
      if (value.empireProductionBasisPoints != 0)
        l10n.wonderDetailsEmpireProductionMultiplierEffect(
          percent(value.empireProductionBasisPoints),
        ),
    ];
  }

  List<String> wonderCompletion(WonderProductionDetailsView value) => [
    if (value.stabilityDelta != 0)
      l10n.wonderDetailsStabilityEffect(signed(value.stabilityDelta)),
    if (value.grantsFreeActiveTechnology) l10n.wonderDetailsGrantFreeTechnology,
    if (value.productionBurst != 0)
      l10n.wonderDetailsProductionBurst(value.productionBurst),
    if (value.grantGold != 0) l10n.wonderDetailsGrantGold(value.grantGold),
  ];
}
