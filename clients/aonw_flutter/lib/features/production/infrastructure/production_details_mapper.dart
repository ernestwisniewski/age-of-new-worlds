part of 'production_view_mapper.dart';

extension ProductionDetailsMapper on ProductionViewMapper {
  ProductionDetailsView details(
    AonwProductionDetailsResult wire, {
    required MapView map,
    required PlayerMapView player,
    required String cityId,
    required ProductionTargetView target,
    required int expectedRevision,
  }) {
    _validateInspectionIdentity(
      wire.stamp,
      wire.cityId,
      map: map,
      player: player,
      cityId: cityId,
      revision: expectedRevision,
    );
    if (!sameProductionTarget(_target(wire.option.target), target)) {
      throw const FormatException(
        'Production details mismatch selected target.',
      );
    }
    _validateAvailability(wire.option);
    _validateForecastValues(wire.option.forecast);
    _validateForecastKind(wire.option);
    return ProductionDetailsView(
      stamp: _stamp(wire.stamp),
      cityId: cityId,
      option: _option(wire.option, wire.option.target.kind),
      effects: _effects(wire),
    );
  }

  ProductionBuildingRanksView buildingRanks(
    AonwProductionBuildingRanksResult wire, {
    required MapView map,
    required PlayerMapView player,
    required String cityId,
    required int expectedRevision,
  }) {
    _validateInspectionIdentity(
      wire.stamp,
      wire.cityId,
      map: map,
      player: player,
      cityId: cityId,
      revision: expectedRevision,
    );
    final seen = <AonwCityBuildingType>{};
    for (final rank in wire.buildings) {
      if (!seen.add(rank.building) || rank.turnsForScore <= 0) {
        throw const FormatException('Production building rank is invalid.');
      }
    }
    if (seen.length != AonwCityBuildingType.values.length) {
      throw const FormatException('Production building ranks are incomplete.');
    }
    return ProductionBuildingRanksView(
      stamp: _stamp(wire.stamp),
      cityId: cityId,
      buildings: [
        for (final rank in wire.buildings)
          ProductionBuildingRankView(
            building: rank.building.name,
            turnsForScore: rank.turnsForScore,
            recommended: rank.recommended,
            bestReturn: rank.bestReturn,
            growth: rank.growth,
            industry: rank.industry,
            science: rank.science,
            defenseMilitary: rank.defenseMilitary,
            economy: rank.economy,
          ),
      ],
    );
  }
}

void _validateInspectionIdentity(
  AonwSessionStamp stamp,
  String responseCity, {
  required MapView map,
  required PlayerMapView player,
  required String cityId,
  required int revision,
}) {
  _validateStamp(stamp, map: map, revision: revision);
  if (responseCity != cityId ||
      player.controlledCityById(cityId) == null ||
      player.stamp.revision != revision ||
      player.stamp.stateDigest != stamp.stateDigest ||
      player.stamp.rulesetHash != stamp.rulesetHash) {
    throw const FormatException(
      'Production inspection mismatches recipient state.',
    );
  }
}

ProductionTargetEffectsView _effects(
  AonwProductionDetailsResult wire,
) => switch ((wire.option.target.kind, wire.effects)) {
  (
    AonwCityProductionTargetKind.building,
    final AonwBuildingProductionDetails value,
  ) =>
    _buildingEffects(value),
  (AonwCityProductionTargetKind.unit, final AonwUnitProductionDetails value) =>
    _unitEffects(wire.option, value),
  (
    AonwCityProductionTargetKind.wonder,
    final AonwWonderProductionDetails value,
  ) =>
    _wonderEffects(value),
  (AonwCityProductionTargetKind.project, AonwProjectProductionDetails()) =>
    const ProjectProductionDetailsView(),
  _ => throw const FormatException('Production effect kind mismatches target.'),
};

List<ProductionRequirementStatusView> _requirements(
  List<AonwProductionRequirementStatus> values,
) => [
  for (final value in values)
    ProductionRequirementStatusView(
      met: value.met,
      requirement: _requirement(value.requirement),
    ),
];

ProductionRequirementView _requirement(AonwProductionRequirement value) {
  final resource = value.kind == AonwProductionRequirementKind.resourceAny;
  final terrain = value.kind == AonwProductionRequirementKind.hostTerrainAny;
  if (resource != value.resources.isNotEmpty ||
      terrain != value.terrains.isNotEmpty ||
      value.resources.toSet().length != value.resources.length ||
      value.terrains.toSet().length != value.terrains.length) {
    throw const FormatException('Production site requirement is invalid.');
  }
  return ProductionRequirementView(
    kind: ProductionRequirementKindView.values.byName(value.kind.name),
    resources: [
      for (final item in value.resources) MapResource.values.byName(item.name),
    ],
    terrains: [
      for (final item in value.terrains) MapTerrain.values.byName(item.name),
    ],
  );
}

YieldValueView _yieldValue(AonwYieldValue value) => YieldValueView(
  food: value.food,
  production: value.production,
  gold: value.gold,
  defense: value.defense,
);

ProductionCityOutputView _cityOutput(AonwProductionCityOutput value) {
  if (value.production < 0 ||
      value.science < 0 ||
      value.maxControlledHexes < 0) {
    throw const FormatException('Production city output is invalid.');
  }
  return ProductionCityOutputView(
    grossYield: _yieldValue(value.grossYield),
    foodDeposit: value.foodDeposit,
    production: value.production,
    gold: value.gold,
    science: value.science,
    maxControlledHexes: value.maxControlledHexes,
  );
}
