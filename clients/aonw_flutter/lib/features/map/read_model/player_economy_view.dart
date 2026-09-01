import 'map_view.dart';
import 'pending_action_view.dart';

final class PlayerStrategicResourceAmountView {
  const PlayerStrategicResourceAmountView({
    required this.resource,
    required this.amount,
  });

  final MapResource resource;
  final int amount;
}

final class PlayerStrategicResourceSourceView {
  const PlayerStrategicResourceSourceView({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  final String cityId;
  final MapHexCoordinate coordinate;
  final MapResource resource;
  final FieldImprovementKind improvement;
  final int amountPerTurn;
}

final class PlayerGoldIncomeSourceView {
  const PlayerGoldIncomeSourceView({
    required this.cityId,
    required this.amount,
  });

  final String cityId;
  final int amount;
}

enum PlayerEconomyUnitKindView {
  commander,
  warrior,
  archer,
  settler,
  worker,
  merchant,
  scout,
  spearman,
  cavalry,
  catapult,
  heavyInfantry,
  fieldCannon,
  rifleman,
  tank,
  scoutShip,
  warship,
  reconPlane,
}

final class PlayerUnitUpkeepSourceView {
  const PlayerUnitUpkeepSourceView({
    required this.kind,
    required this.paidUnitCount,
    required this.amount,
  });

  final PlayerEconomyUnitKindView kind;
  final int paidUnitCount;
  final int amount;
}

final class PlayerUnitUpkeepView {
  PlayerUnitUpkeepView({
    required this.upkeepBearingUnitCount,
    required this.freeUnitCount,
    required this.paidUnitCount,
    required this.total,
    required this.nextWorkerUpkeep,
    required List<PlayerUnitUpkeepSourceView> sources,
  }) : sources = List.unmodifiable(sources);

  final int upkeepBearingUnitCount;
  final int freeUnitCount;
  final int paidUnitCount;
  final int total;
  final int nextWorkerUpkeep;
  final List<PlayerUnitUpkeepSourceView> sources;
}

enum PlayerStabilityBandView { content, stable, strained, unrest }

final class PlayerStabilityBreakdownView {
  const PlayerStabilityBreakdownView({
    required this.baseOrder,
    required this.buildingSources,
    required this.luxurySources,
    required this.technologySources,
    required this.artifactSources,
    required this.wonderSources,
    required this.cityCost,
    required this.populationCost,
    required this.cohesionCost,
    required this.conqueredCityCost,
    required this.warWearinessCost,
    required this.hegemonyTax,
    required this.sourceTotal,
    required this.costTotal,
    required this.relativeStandingAdjustment,
    required this.effectiveNet,
    required this.band,
  });

  final int baseOrder;
  final int buildingSources;
  final int luxurySources;
  final int technologySources;
  final int artifactSources;
  final int wonderSources;
  final int cityCost;
  final int populationCost;
  final int cohesionCost;
  final int conqueredCityCost;
  final int warWearinessCost;
  final int hegemonyTax;
  final int sourceTotal;
  final int costTotal;
  final int relativeStandingAdjustment;
  final int effectiveNet;
  final PlayerStabilityBandView band;
}

final class PlayerEconomyForecastView {
  PlayerEconomyForecastView({
    required this.treasury,
    required this.cityIncome,
    required this.projectIncome,
    required this.grossIncome,
    required this.netPerTurn,
    required List<PlayerGoldIncomeSourceView> citySources,
    required List<PlayerGoldIncomeSourceView> projectSources,
    required this.upkeep,
    required this.stability,
  }) : citySources = List.unmodifiable(citySources),
       projectSources = List.unmodifiable(projectSources);

  factory PlayerEconomyForecastView.empty() => PlayerEconomyForecastView(
    treasury: 0,
    cityIncome: 0,
    projectIncome: 0,
    grossIncome: 0,
    netPerTurn: 0,
    citySources: const [],
    projectSources: const [],
    upkeep: PlayerUnitUpkeepView(
      upkeepBearingUnitCount: 0,
      freeUnitCount: 0,
      paidUnitCount: 0,
      total: 0,
      nextWorkerUpkeep: 0,
      sources: const [],
    ),
    stability: const PlayerStabilityBreakdownView(
      baseOrder: 0,
      buildingSources: 0,
      luxurySources: 0,
      technologySources: 0,
      artifactSources: 0,
      wonderSources: 0,
      cityCost: 0,
      populationCost: 0,
      cohesionCost: 0,
      conqueredCityCost: 0,
      warWearinessCost: 0,
      hegemonyTax: 0,
      sourceTotal: 0,
      costTotal: 0,
      relativeStandingAdjustment: 0,
      effectiveNet: 0,
      band: PlayerStabilityBandView.stable,
    ),
  );

  final int treasury;
  final int cityIncome;
  final int projectIncome;
  final int grossIncome;
  final int netPerTurn;
  final List<PlayerGoldIncomeSourceView> citySources;
  final List<PlayerGoldIncomeSourceView> projectSources;
  final PlayerUnitUpkeepView upkeep;
  final PlayerStabilityBreakdownView stability;
}

final class PlayerEconomyView {
  PlayerEconomyView({
    required this.gold,
    required this.warWeariness,
    required this.stabilityNet,
    required List<PlayerStrategicResourceAmountView> strategicResourceStockpile,
    required List<PlayerStrategicResourceAmountView> strategicResourceOutput,
    required List<PlayerStrategicResourceSourceView> strategicResourceSources,
    required this.forecast,
  }) : strategicResourceStockpile = List.unmodifiable(
         strategicResourceStockpile,
       ),
       strategicResourceOutput = List.unmodifiable(strategicResourceOutput),
       strategicResourceSources = List.unmodifiable(strategicResourceSources);

  factory PlayerEconomyView.empty() => PlayerEconomyView(
    gold: 0,
    warWeariness: 0,
    stabilityNet: 0,
    strategicResourceStockpile: const [],
    strategicResourceOutput: const [],
    strategicResourceSources: const [],
    forecast: PlayerEconomyForecastView.empty(),
  );

  final int gold;
  final int warWeariness;
  final int stabilityNet;
  final List<PlayerStrategicResourceAmountView> strategicResourceStockpile;
  final List<PlayerStrategicResourceAmountView> strategicResourceOutput;
  final List<PlayerStrategicResourceSourceView> strategicResourceSources;
  final PlayerEconomyForecastView forecast;

  int stockpiledAmountFor(MapResource resource) {
    for (final amount in strategicResourceStockpile) {
      if (amount.resource == resource) return amount.amount;
    }
    return 0;
  }

  int outputPerTurnFor(MapResource resource) {
    for (final amount in strategicResourceOutput) {
      if (amount.resource == resource) return amount.amount;
    }
    return 0;
  }
}
