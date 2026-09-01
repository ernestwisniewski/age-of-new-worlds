import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';

final class RecipientEconomyValidator {
  const RecipientEconomyValidator(this.map);

  final MapView map;

  void validate(
    AonwPlayerEconomyView economy,
    List<AonwPlayerCityView> cities,
  ) {
    if (economy.gold < 0 || economy.warWeariness < 0) {
      throw const FormatException('Recipient economy account is negative.');
    }
    _validateAmounts(
      economy.strategicResourceStockpile,
      'strategic resource stockpile',
    );
    _validateAmounts(
      economy.strategicResourceOutput,
      'strategic resource output',
    );
    final output = _amountMap(economy.strategicResourceOutput);
    final sourceOutput = _validateSources(
      economy.strategicResourceSources,
      cities,
    );
    if (!_sameAmounts(output, sourceOutput)) {
      throw const FormatException(
        'Recipient strategic resource output does not match its sources.',
      );
    }
    _validateForecast(economy, cities);
  }

  void _validateAmounts(
    List<AonwPlayerStrategicResourceAmount> amounts,
    String label,
  ) {
    int? previousResourceIndex;
    for (final amount in amounts) {
      final unordered =
          previousResourceIndex != null &&
          previousResourceIndex >= amount.resource.index;
      if (!_isStockpiled(amount.resource) || amount.amount <= 0 || unordered) {
        throw FormatException('Recipient $label is invalid or not ordered.');
      }
      previousResourceIndex = amount.resource.index;
    }
  }

  Map<AonwResourceType, int> _validateSources(
    List<AonwPlayerStrategicResourceSource> sources,
    List<AonwPlayerCityView> cities,
  ) {
    final output = <AonwResourceType, int>{};
    final cityById = {for (final city in cities) city.id: city};
    _SourceKey? previous;
    for (final source in sources) {
      _validateSource(source, cityById[source.cityId]);
      final key = _sourceKey(source);
      if (previous != null && _compareSourceKeys(previous, key) >= 0) {
        throw const FormatException(
          'Recipient strategic resource sources are not ordered.',
        );
      }
      previous = key;
      output.update(
        source.resource,
        (amount) => amount + source.amountPerTurn,
        ifAbsent: () => source.amountPerTurn,
      );
    }
    return output;
  }

  void _validateSource(
    AonwPlayerStrategicResourceSource source,
    AonwPlayerCityView? city,
  ) {
    if (source.cityId.isEmpty || source.amountPerTurn <= 0) {
      throw const FormatException(
        'Recipient strategic resource source is invalid.',
      );
    }
    if (!map.isWithinBounds((
      col: source.coordinate.col,
      row: source.coordinate.row,
    ))) {
      throw const FormatException(
        'Recipient strategic resource source is outside the map.',
      );
    }
    if (city == null || !_cityControls(city, source.coordinate)) {
      throw const FormatException(
        'Recipient strategic resource source city is inconsistent.',
      );
    }
    if (!_matchesImprovement(source)) {
      throw const FormatException(
        'Recipient strategic resource source improvement is invalid.',
      );
    }
  }

  void _validateForecast(
    AonwPlayerEconomyView economy,
    List<AonwPlayerCityView> cities,
  ) {
    final forecast = economy.forecast;
    if (forecast.treasury != economy.gold ||
        forecast.cityIncome < 0 ||
        forecast.projectIncome < 0 ||
        forecast.grossIncome != forecast.cityIncome + forecast.projectIncome) {
      throw const FormatException('Recipient gold forecast is inconsistent.');
    }
    final cityIds = {
      for (final city in cities)
        if (city.ownedDetails != null) city.id,
    };
    final cityIncome = _validateGoldSources(
      forecast.citySources,
      cityIds,
      'city income',
    );
    final projectIncome = _validateGoldSources(
      forecast.projectSources,
      cityIds,
      'project income',
    );
    if (cityIncome != forecast.cityIncome ||
        projectIncome != forecast.projectIncome) {
      throw const FormatException(
        'Recipient gold forecast does not match its sources.',
      );
    }
    _validateUpkeep(forecast.upkeep);
    if (forecast.netPerTurn != forecast.grossIncome - forecast.upkeep.total) {
      throw const FormatException('Recipient net gold forecast is invalid.');
    }
    _validateStability(economy);
  }

  int _validateGoldSources(
    List<AonwGoldIncomeSource> sources,
    Set<String> cityIds,
    String label,
  ) {
    String? previousCityId;
    var total = 0;
    for (final source in sources) {
      if (source.cityId.isEmpty ||
          !cityIds.contains(source.cityId) ||
          source.amount <= 0 ||
          (previousCityId != null &&
              previousCityId.compareTo(source.cityId) >= 0)) {
        throw FormatException(
          'Recipient $label source is invalid or unordered.',
        );
      }
      previousCityId = source.cityId;
      total += source.amount;
    }
    return total;
  }

  void _validateUpkeep(AonwUnitUpkeepBreakdown upkeep) {
    _validateUpkeepSummary(upkeep);
    final totals = _upkeepSourceTotals(upkeep.sources);
    if (totals.paidCount != upkeep.paidUnitCount ||
        totals.amount != upkeep.total) {
      throw const FormatException(
        'Recipient unit upkeep does not match its sources.',
      );
    }
  }

  void _validateUpkeepSummary(AonwUnitUpkeepBreakdown upkeep) {
    final expectedPaid = upkeep.upkeepBearingUnitCount - upkeep.freeUnitCount;
    if (upkeep.upkeepBearingUnitCount < 0 ||
        upkeep.freeUnitCount < 0 ||
        upkeep.paidUnitCount != (expectedPaid > 0 ? expectedPaid : 0) ||
        upkeep.total < 0 ||
        upkeep.nextWorkerUpkeep < 0) {
      throw const FormatException('Recipient unit upkeep is inconsistent.');
    }
  }

  ({int paidCount, int amount}) _upkeepSourceTotals(
    List<AonwUnitUpkeepSource> sources,
  ) {
    int? previousKind;
    var paidCount = 0;
    var total = 0;
    for (final source in sources) {
      _validateUpkeepSource(source, previousKind);
      previousKind = source.kind.index;
      paidCount += source.paidUnitCount;
      total += source.amount;
    }
    return (paidCount: paidCount, amount: total);
  }

  void _validateUpkeepSource(AonwUnitUpkeepSource source, int? previousKind) {
    if (source.kind == AonwUnitKind.commander ||
        source.paidUnitCount <= 0 ||
        source.amount <= 0 ||
        (previousKind != null && previousKind >= source.kind.index)) {
      throw const FormatException(
        'Recipient unit upkeep source is invalid or unordered.',
      );
    }
  }

  void _validateStability(AonwPlayerEconomyView economy) {
    final stability = economy.forecast.stability;
    final sources = [
      stability.baseOrder,
      stability.buildingSources,
      stability.luxurySources,
      stability.technologySources,
      stability.artifactSources,
      stability.wonderSources,
    ];
    final costs = [
      stability.cityCost,
      stability.populationCost,
      stability.cohesionCost,
      stability.conqueredCityCost,
      stability.warWearinessCost,
      stability.hegemonyTax,
    ];
    if (sources.any((value) => value < 0) ||
        costs.any((value) => value < 0) ||
        stability.sourceTotal != sources.fold(0, (sum, value) => sum + value) ||
        stability.costTotal != costs.fold(0, (sum, value) => sum + value) ||
        stability.warWearinessCost != economy.warWeariness ||
        stability.effectiveNet !=
            stability.sourceTotal -
                stability.costTotal +
                stability.relativeStandingAdjustment) {
      throw const FormatException(
        'Recipient stability breakdown is inconsistent.',
      );
    }
  }
}

typedef _SourceKey = ({int col, int row, int resource});

_SourceKey _sourceKey(AonwPlayerStrategicResourceSource source) => (
  col: source.coordinate.col,
  row: source.coordinate.row,
  resource: source.resource.index,
);

int _compareSourceKeys(_SourceKey left, _SourceKey right) {
  final col = left.col.compareTo(right.col);
  if (col != 0) return col;
  final row = left.row.compareTo(right.row);
  return row != 0 ? row : left.resource.compareTo(right.resource);
}

Map<AonwResourceType, int> _amountMap(
  List<AonwPlayerStrategicResourceAmount> amounts,
) => {for (final amount in amounts) amount.resource: amount.amount};

bool _cityControls(AonwPlayerCityView city, AonwCoordinate coordinate) =>
    _coordinateKey(city.center) == _coordinateKey(coordinate) ||
    city.visibleControlledHexes.any(
      (candidate) => _coordinateKey(candidate) == _coordinateKey(coordinate),
    );

({int col, int row}) _coordinateKey(AonwCoordinate value) =>
    (col: value.col, row: value.row);

bool _matchesImprovement(AonwPlayerStrategicResourceSource source) =>
    switch (source.resource) {
      AonwResourceType.oil =>
        source.improvement == AonwFieldImprovementKind.oilWell,
      AonwResourceType.aluminium =>
        source.improvement == AonwFieldImprovementKind.bauxiteMine,
      _ => false,
    };

bool _isStockpiled(AonwResourceType resource) =>
    resource == AonwResourceType.oil || resource == AonwResourceType.aluminium;

bool _sameAmounts(
  Map<AonwResourceType, int> left,
  Map<AonwResourceType, int> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
