import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:aonw_engine_client/src/protocol_pending_action.dart';
import 'package:aonw_engine_client/src/protocol_values.dart';

final class AonwPlayerStrategicResourceAmount {
  const AonwPlayerStrategicResourceAmount({
    required this.resource,
    required this.amount,
  });

  factory AonwPlayerStrategicResourceAmount.fromJson(Object? source) {
    final value = readObject(source, 'player strategic resource amount');
    requireKeys(value, const {
      'resource',
      'amount',
    }, 'player strategic resource amount');
    return AonwPlayerStrategicResourceAmount(
      resource: AonwResourceType.fromJson(value['resource']),
      amount: readInt(value['amount'], 'player strategic resource amount'),
    );
  }

  final AonwResourceType resource;
  final int amount;
}

final class AonwPlayerStrategicResourceSource {
  const AonwPlayerStrategicResourceSource({
    required this.cityId,
    required this.coordinate,
    required this.resource,
    required this.improvement,
    required this.amountPerTurn,
  });

  factory AonwPlayerStrategicResourceSource.fromJson(Object? source) {
    final value = readObject(source, 'player strategic resource source');
    requireKeys(value, const {
      'cityId',
      'coordinate',
      'resource',
      'improvement',
      'amountPerTurn',
    }, 'player strategic resource source');
    return AonwPlayerStrategicResourceSource(
      cityId: readString(value['cityId'], 'resource source city id'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      resource: AonwResourceType.fromJson(value['resource']),
      improvement: AonwFieldImprovementKind.fromJson(value['improvement']),
      amountPerTurn: readInt(
        value['amountPerTurn'],
        'resource source amount per turn',
      ),
    );
  }

  final String cityId;
  final AonwCoordinate coordinate;
  final AonwResourceType resource;
  final AonwFieldImprovementKind improvement;
  final int amountPerTurn;
}

final class AonwGoldIncomeSource {
  const AonwGoldIncomeSource({required this.cityId, required this.amount});

  factory AonwGoldIncomeSource.fromJson(Object? source) {
    final value = readObject(source, 'gold income source');
    requireKeys(value, const {'cityId', 'amount'}, 'gold income source');
    return AonwGoldIncomeSource(
      cityId: readString(value['cityId'], 'gold income source city id'),
      amount: readInt(value['amount'], 'gold income source amount'),
    );
  }

  final String cityId;
  final int amount;
}

final class AonwUnitUpkeepSource {
  const AonwUnitUpkeepSource({
    required this.kind,
    required this.paidUnitCount,
    required this.amount,
  });

  factory AonwUnitUpkeepSource.fromJson(Object? source) {
    final value = readObject(source, 'unit upkeep source');
    requireKeys(value, const {
      'kind',
      'paidUnitCount',
      'amount',
    }, 'unit upkeep source');
    return AonwUnitUpkeepSource(
      kind: AonwUnitKind.fromJson(value['kind']),
      paidUnitCount: readInt(value['paidUnitCount'], 'paid unit count'),
      amount: readInt(value['amount'], 'unit upkeep amount'),
    );
  }

  final AonwUnitKind kind;
  final int paidUnitCount;
  final int amount;
}

final class AonwUnitUpkeepBreakdown {
  AonwUnitUpkeepBreakdown({
    required this.upkeepBearingUnitCount,
    required this.freeUnitCount,
    required this.paidUnitCount,
    required this.total,
    required this.nextWorkerUpkeep,
    required List<AonwUnitUpkeepSource> sources,
  }) : sources = List.unmodifiable(sources);

  factory AonwUnitUpkeepBreakdown.empty() => AonwUnitUpkeepBreakdown(
    upkeepBearingUnitCount: 0,
    freeUnitCount: 0,
    paidUnitCount: 0,
    total: 0,
    nextWorkerUpkeep: 0,
    sources: const [],
  );

  factory AonwUnitUpkeepBreakdown.fromJson(Object? source) {
    final value = readObject(source, 'unit upkeep breakdown');
    requireKeys(value, const {
      'upkeepBearingUnitCount',
      'freeUnitCount',
      'paidUnitCount',
      'total',
      'nextWorkerUpkeep',
      'sources',
    }, 'unit upkeep breakdown');
    return AonwUnitUpkeepBreakdown(
      upkeepBearingUnitCount: readInt(
        value['upkeepBearingUnitCount'],
        'upkeep-bearing unit count',
      ),
      freeUnitCount: readInt(value['freeUnitCount'], 'free unit count'),
      paidUnitCount: readInt(value['paidUnitCount'], 'paid unit count'),
      total: readInt(value['total'], 'unit upkeep total'),
      nextWorkerUpkeep: readInt(
        value['nextWorkerUpkeep'],
        'next worker upkeep',
      ),
      sources: _economyViews(
        value['sources'],
        'unit upkeep sources',
        AonwUnitUpkeepSource.fromJson,
      ),
    );
  }

  final int upkeepBearingUnitCount;
  final int freeUnitCount;
  final int paidUnitCount;
  final int total;
  final int nextWorkerUpkeep;
  final List<AonwUnitUpkeepSource> sources;
}

enum AonwStabilityBand {
  content,
  stable,
  strained,
  unrest;

  factory AonwStabilityBand.fromJson(Object? source) {
    final wire = readString(source, 'stability band');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () => throw FormatException('Unknown stability band $wire.'),
    );
  }
}

final class AonwStabilityBreakdown {
  const AonwStabilityBreakdown({
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

  factory AonwStabilityBreakdown.empty() => const AonwStabilityBreakdown(
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
    band: AonwStabilityBand.stable,
  );

  factory AonwStabilityBreakdown.fromJson(Object? source) {
    final value = readObject(source, 'stability breakdown');
    const keys = {
      'baseOrder',
      'buildingSources',
      'luxurySources',
      'technologySources',
      'artifactSources',
      'wonderSources',
      'cityCost',
      'populationCost',
      'cohesionCost',
      'conqueredCityCost',
      'warWearinessCost',
      'hegemonyTax',
      'sourceTotal',
      'costTotal',
      'relativeStandingAdjustment',
      'effectiveNet',
      'band',
    };
    requireKeys(value, keys, 'stability breakdown');
    int integer(String key) => readInt(value[key], 'stability $key');
    return AonwStabilityBreakdown(
      baseOrder: integer('baseOrder'),
      buildingSources: integer('buildingSources'),
      luxurySources: integer('luxurySources'),
      technologySources: integer('technologySources'),
      artifactSources: integer('artifactSources'),
      wonderSources: integer('wonderSources'),
      cityCost: integer('cityCost'),
      populationCost: integer('populationCost'),
      cohesionCost: integer('cohesionCost'),
      conqueredCityCost: integer('conqueredCityCost'),
      warWearinessCost: integer('warWearinessCost'),
      hegemonyTax: integer('hegemonyTax'),
      sourceTotal: integer('sourceTotal'),
      costTotal: integer('costTotal'),
      relativeStandingAdjustment: integer('relativeStandingAdjustment'),
      effectiveNet: integer('effectiveNet'),
      band: AonwStabilityBand.fromJson(value['band']),
    );
  }

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
  final AonwStabilityBand band;
}

final class AonwEconomyForecast {
  AonwEconomyForecast({
    required this.treasury,
    required this.cityIncome,
    required this.projectIncome,
    required this.grossIncome,
    required this.netPerTurn,
    required List<AonwGoldIncomeSource> citySources,
    required List<AonwGoldIncomeSource> projectSources,
    required this.upkeep,
    required this.stability,
  }) : citySources = List.unmodifiable(citySources),
       projectSources = List.unmodifiable(projectSources);

  factory AonwEconomyForecast.empty({int treasury = 0, int warWeariness = 0}) =>
      AonwEconomyForecast(
        treasury: treasury,
        cityIncome: 0,
        projectIncome: 0,
        grossIncome: 0,
        netPerTurn: 0,
        citySources: const [],
        projectSources: const [],
        upkeep: AonwUnitUpkeepBreakdown.empty(),
        stability: AonwStabilityBreakdown(
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
          warWearinessCost: warWeariness,
          hegemonyTax: 0,
          sourceTotal: 0,
          costTotal: warWeariness,
          relativeStandingAdjustment: 0,
          effectiveNet: -warWeariness,
          band: AonwStabilityBand.stable,
        ),
      );

  factory AonwEconomyForecast.fromJson(Object? source) {
    final value = readObject(source, 'economy forecast');
    requireKeys(value, const {
      'treasury',
      'cityIncome',
      'projectIncome',
      'grossIncome',
      'netPerTurn',
      'citySources',
      'projectSources',
      'upkeep',
      'stability',
    }, 'economy forecast');
    return AonwEconomyForecast(
      treasury: readInt(value['treasury'], 'forecast treasury'),
      cityIncome: readInt(value['cityIncome'], 'forecast city income'),
      projectIncome: readInt(value['projectIncome'], 'forecast project income'),
      grossIncome: readInt(value['grossIncome'], 'forecast gross income'),
      netPerTurn: readInt(value['netPerTurn'], 'forecast net per turn'),
      citySources: _economyViews(
        value['citySources'],
        'forecast city sources',
        AonwGoldIncomeSource.fromJson,
      ),
      projectSources: _economyViews(
        value['projectSources'],
        'forecast project sources',
        AonwGoldIncomeSource.fromJson,
      ),
      upkeep: AonwUnitUpkeepBreakdown.fromJson(value['upkeep']),
      stability: AonwStabilityBreakdown.fromJson(value['stability']),
    );
  }

  final int treasury;
  final int cityIncome;
  final int projectIncome;
  final int grossIncome;
  final int netPerTurn;
  final List<AonwGoldIncomeSource> citySources;
  final List<AonwGoldIncomeSource> projectSources;
  final AonwUnitUpkeepBreakdown upkeep;
  final AonwStabilityBreakdown stability;
}

final class AonwPlayerEconomyView {
  AonwPlayerEconomyView({
    required this.gold,
    required this.warWeariness,
    required this.stabilityNet,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile,
    required List<AonwPlayerStrategicResourceAmount> strategicResourceOutput,
    required List<AonwPlayerStrategicResourceSource> strategicResourceSources,
    required this.forecast,
  }) : strategicResourceStockpile = List.unmodifiable(
         strategicResourceStockpile,
       ),
       strategicResourceOutput = List.unmodifiable(strategicResourceOutput),
       strategicResourceSources = List.unmodifiable(strategicResourceSources);

  factory AonwPlayerEconomyView.empty() => AonwPlayerEconomyView(
    gold: 0,
    warWeariness: 0,
    stabilityNet: 0,
    strategicResourceStockpile: const [],
    strategicResourceOutput: const [],
    strategicResourceSources: const [],
    forecast: AonwEconomyForecast.empty(),
  );

  factory AonwPlayerEconomyView.fromJson(Object? source) {
    final value = readObject(source, 'player economy view');
    requireKeys(value, const {
      'gold',
      'warWeariness',
      'stabilityNet',
      'strategicResourceStockpile',
      'strategicResourceOutput',
      'strategicResourceSources',
      'forecast',
    }, 'player economy view');
    return AonwPlayerEconomyView(
      gold: readInt(value['gold'], 'player gold'),
      warWeariness: readInt(value['warWeariness'], 'player war weariness'),
      stabilityNet: readInt(value['stabilityNet'], 'player stability'),
      strategicResourceStockpile: _economyViews(
        value['strategicResourceStockpile'],
        'player strategic resource stockpile',
        AonwPlayerStrategicResourceAmount.fromJson,
      ),
      strategicResourceOutput: _economyViews(
        value['strategicResourceOutput'],
        'player strategic resource output',
        AonwPlayerStrategicResourceAmount.fromJson,
      ),
      strategicResourceSources: _economyViews(
        value['strategicResourceSources'],
        'player strategic resource sources',
        AonwPlayerStrategicResourceSource.fromJson,
      ),
      forecast: AonwEconomyForecast.fromJson(value['forecast']),
    );
  }

  final int gold;
  final int warWeariness;
  final int stabilityNet;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceStockpile;
  final List<AonwPlayerStrategicResourceAmount> strategicResourceOutput;
  final List<AonwPlayerStrategicResourceSource> strategicResourceSources;
  final AonwEconomyForecast forecast;
}

List<T> _economyViews<T>(
  Object? value,
  String label,
  T Function(Object? value) parse,
) => readList(value, label, (item, _) => parse(item));
