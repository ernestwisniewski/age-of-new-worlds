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
