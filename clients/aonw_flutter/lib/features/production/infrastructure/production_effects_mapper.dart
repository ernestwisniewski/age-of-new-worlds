part of 'production_view_mapper.dart';

BuildingProductionDetailsView _buildingEffects(
  AonwBuildingProductionDetails value,
) {
  if (value.riverApplications < 0 ||
      value.riverApplications > value.maxRiverApplications ||
      value.foodDepositBasisPoints < 0) {
    throw const FormatException('Production building effects are invalid.');
  }
  return BuildingProductionDetailsView(
    requirements: _requirements(value.requirements),
    flatYield: _yieldValue(value.flatYield),
    riverYieldPerHex: _yieldValue(value.riverYieldPerHex),
    maxRiverApplications: value.maxRiverApplications,
    riverApplications: value.riverApplications,
    sciencePerTurn: value.sciencePerTurn,
    maxControlledHexesDelta: value.maxControlledHexesDelta,
    foodDepositBasisPoints: value.foodDepositBasisPoints,
    current: _cityOutput(value.current),
    completed: _cityOutput(value.completed),
  );
}

UnitProductionDetailsView _unitEffects(
  AonwProductionOption option,
  AonwUnitProductionDetails value,
) {
  final resources = _unitOption(
    AonwUnitProductionOption(
      option: option,
      resourceOptions: value.resourceOptions,
      affordableResourceOptionIndices: value.affordableResourceOptionIndices,
    ),
  );
  if (value.maximumMovementUnits < 0 ||
      value.baseUpkeep < 0 ||
      value.supplyCost < 0 ||
      value.supplyCapacity < 0 ||
      value.supplyUsedWithoutCityQueue < 0 ||
      value.presenceResources.toSet().length !=
          value.presenceResources.length) {
    throw const FormatException('Production unit effects are invalid.');
  }
  return UnitProductionDetailsView(
    baseCombat: _combatStats(value.baseCombat),
    effectiveCombat: _combatStats(value.effectiveCombat),
    maximumMovementUnits: value.maximumMovementUnits,
    baseUpkeep: value.baseUpkeep,
    supplyCost: value.supplyCost,
    supplyCapacity: value.supplyCapacity,
    supplyUsedWithoutCityQueue: value.supplyUsedWithoutCityQueue,
    presenceResources: [
      for (final item in value.presenceResources)
        MapResource.values.byName(item.name),
    ],
    presenceResourcesMet: value.presenceResourcesMet,
    coastMet: value.coastMet,
    resourceOptions: resources.resourceOptions,
    affordableResourceOptionIndices: resources.affordableResourceOptionIndices
        .toList(),
  );
}

WonderProductionDetailsView _wonderEffects(AonwWonderProductionDetails value) {
  if (value.empireGoldBasisPoints < 0 ||
      value.empireProductionBasisPoints < 0) {
    throw const FormatException('Production wonder multipliers are invalid.');
  }
  return WonderProductionDetailsView(
    requirements: _requirements(value.requirements),
    hostYield: _yieldValue(value.hostYield),
    empireYieldPerCity: _yieldValue(value.empireYieldPerCity),
    empireSciencePerCity: value.empireSciencePerCity,
    empireGoldBasisPoints: value.empireGoldBasisPoints,
    empireProductionBasisPoints: value.empireProductionBasisPoints,
    stabilityDelta: value.stabilityDelta,
    grantsFreeActiveTechnology: value.grantsFreeActiveTechnology,
    productionBurst: value.productionBurst,
    grantGold: value.grantGold,
  );
}

CombatStatsView _combatStats(AonwCombatStats value) => CombatStatsView(
  attack: value.attack,
  defense: value.defense,
  hitPoints: value.hitPoints,
  range: value.range,
  mobility: value.mobility,
  modifiers: [
    for (final modifier in value.modifiers)
      CombatModifierView(
        kind: CombatModifierKindView.values.byName(modifier.kind.name),
        label: modifier.label,
        target: CombatStatTargetView.values.byName(modifier.target.name),
        delta: modifier.delta,
      ),
  ],
);
