import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_economy_view.dart';

PlayerEconomyView mapPlayerEconomyView(AonwPlayerEconomyView economy) =>
    PlayerEconomyView(
      gold: economy.gold,
      warWeariness: economy.warWeariness,
      stabilityNet: economy.stabilityNet,
      strategicResourceStockpile: [
        for (final amount in economy.strategicResourceStockpile)
          PlayerStrategicResourceAmountView(
            resource: MapResource.values.byName(amount.resource.name),
            amount: amount.amount,
          ),
      ],
      strategicResourceOutput: [
        for (final amount in economy.strategicResourceOutput)
          PlayerStrategicResourceAmountView(
            resource: MapResource.values.byName(amount.resource.name),
            amount: amount.amount,
          ),
      ],
      strategicResourceSources: [
        for (final source in economy.strategicResourceSources)
          PlayerStrategicResourceSourceView(
            cityId: source.cityId,
            coordinate: (
              col: source.coordinate.col,
              row: source.coordinate.row,
            ),
            resource: MapResource.values.byName(source.resource.name),
            improvement: FieldImprovementKind.values.byName(
              source.improvement.name,
            ),
            amountPerTurn: source.amountPerTurn,
          ),
      ],
      forecast: _mapForecast(economy.forecast),
    );

PlayerEconomyForecastView _mapForecast(
  AonwEconomyForecast forecast,
) => PlayerEconomyForecastView(
  treasury: forecast.treasury,
  cityIncome: forecast.cityIncome,
  projectIncome: forecast.projectIncome,
  grossIncome: forecast.grossIncome,
  netPerTurn: forecast.netPerTurn,
  citySources: [
    for (final source in forecast.citySources)
      PlayerGoldIncomeSourceView(cityId: source.cityId, amount: source.amount),
  ],
  projectSources: [
    for (final source in forecast.projectSources)
      PlayerGoldIncomeSourceView(cityId: source.cityId, amount: source.amount),
  ],
  upkeep: PlayerUnitUpkeepView(
    upkeepBearingUnitCount: forecast.upkeep.upkeepBearingUnitCount,
    freeUnitCount: forecast.upkeep.freeUnitCount,
    paidUnitCount: forecast.upkeep.paidUnitCount,
    total: forecast.upkeep.total,
    nextWorkerUpkeep: forecast.upkeep.nextWorkerUpkeep,
    sources: [
      for (final source in forecast.upkeep.sources)
        PlayerUnitUpkeepSourceView(
          kind: PlayerEconomyUnitKindView.values.byName(source.kind.name),
          paidUnitCount: source.paidUnitCount,
          amount: source.amount,
        ),
    ],
  ),
  stability: PlayerStabilityBreakdownView(
    baseOrder: forecast.stability.baseOrder,
    buildingSources: forecast.stability.buildingSources,
    luxurySources: forecast.stability.luxurySources,
    technologySources: forecast.stability.technologySources,
    artifactSources: forecast.stability.artifactSources,
    wonderSources: forecast.stability.wonderSources,
    cityCost: forecast.stability.cityCost,
    populationCost: forecast.stability.populationCost,
    cohesionCost: forecast.stability.cohesionCost,
    conqueredCityCost: forecast.stability.conqueredCityCost,
    warWearinessCost: forecast.stability.warWearinessCost,
    hegemonyTax: forecast.stability.hegemonyTax,
    sourceTotal: forecast.stability.sourceTotal,
    costTotal: forecast.stability.costTotal,
    relativeStandingAdjustment: forecast.stability.relativeStandingAdjustment,
    effectiveNet: forecast.stability.effectiveNet,
    band: PlayerStabilityBandView.values.byName(forecast.stability.band.name),
  ),
);
