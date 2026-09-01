part of 'protocol_query.dart';

final class AonwCityFoundingOptionsResult extends AonwQueryResult {
  AonwCityFoundingOptionsResult({
    required this.stamp,
    required this.founderUnitId,
    required this.center,
    required List<AonwCoordinate> selectedControlledHexes,
    required List<AonwCoordinate> availableControlledHexes,
    required List<AonwCoordinate> rankedAvailableControlledHexes,
    required this.requiredControlledHexes,
    required this.maximumRadius,
  }) : selectedControlledHexes = List.unmodifiable(selectedControlledHexes),
       availableControlledHexes = List.unmodifiable(availableControlledHexes),
       rankedAvailableControlledHexes = List.unmodifiable(
         rankedAvailableControlledHexes,
       );

  factory AonwCityFoundingOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'founderUnitId',
      'center',
      'selectedControlledHexes',
      'availableControlledHexes',
      'rankedAvailableControlledHexes',
      'requiredControlledHexes',
      'maximumRadius',
    }, 'city founding options');
    return AonwCityFoundingOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      founderUnitId: readString(value['founderUnitId'], 'city founder unit id'),
      center: AonwCoordinate.fromJson(value['center']),
      selectedControlledHexes: _cityCoordinates(
        value['selectedControlledHexes'],
        'selected city founding hexes',
      ),
      availableControlledHexes: _cityCoordinates(
        value['availableControlledHexes'],
        'available city founding hexes',
      ),
      rankedAvailableControlledHexes: _cityCoordinates(
        value['rankedAvailableControlledHexes'],
        'ranked available city founding hexes',
      ),
      requiredControlledHexes: readUnsigned(
        value['requiredControlledHexes'],
        'required city founding hexes',
      ),
      maximumRadius: readUnsigned(
        value['maximumRadius'],
        'maximum city founding radius',
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String founderUnitId;
  final AonwCoordinate center;
  final List<AonwCoordinate> selectedControlledHexes;
  final List<AonwCoordinate> availableControlledHexes;
  final List<AonwCoordinate> rankedAvailableControlledHexes;
  final int requiredControlledHexes;
  final int maximumRadius;
}

final class AonwCityWorkedHexOptionsResult extends AonwQueryResult {
  AonwCityWorkedHexOptionsResult({
    required this.stamp,
    required this.cityId,
    required this.center,
    required List<AonwCoordinate> controlledHexes,
    required List<AonwCoordinate> availableHexes,
    required List<AonwCoordinate> selectedHexes,
    required List<AonwCoordinate> effectiveHexes,
    required this.limit,
  }) : controlledHexes = List.unmodifiable(controlledHexes),
       availableHexes = List.unmodifiable(availableHexes),
       selectedHexes = List.unmodifiable(selectedHexes),
       effectiveHexes = List.unmodifiable(effectiveHexes);

  factory AonwCityWorkedHexOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'center',
      'controlledHexes',
      'availableHexes',
      'selectedHexes',
      'effectiveHexes',
      'limit',
    }, 'city worked hex options');
    return AonwCityWorkedHexOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'worked hex city id'),
      center: AonwCoordinate.fromJson(value['center']),
      controlledHexes: _cityCoordinates(
        value['controlledHexes'],
        'controlled city hexes',
      ),
      availableHexes: _cityCoordinates(
        value['availableHexes'],
        'available worked hexes',
      ),
      selectedHexes: _cityCoordinates(
        value['selectedHexes'],
        'selected worked hexes',
      ),
      effectiveHexes: _cityCoordinates(
        value['effectiveHexes'],
        'effective worked hexes',
      ),
      limit: readUnsigned(value['limit'], 'worked hex limit'),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final AonwCoordinate center;
  final List<AonwCoordinate> controlledHexes;
  final List<AonwCoordinate> availableHexes;
  final List<AonwCoordinate> selectedHexes;
  final List<AonwCoordinate> effectiveHexes;
  final int limit;
}

final class AonwCityExpansionOptionsResult extends AonwQueryResult {
  AonwCityExpansionOptionsResult({
    required this.stamp,
    required this.cityId,
    required List<AonwCoordinate> controlledHexes,
    required this.preferredHex,
    required List<AonwCityExpansionCandidate> candidates,
  }) : controlledHexes = List.unmodifiable(controlledHexes),
       candidates = List.unmodifiable(candidates);

  factory AonwCityExpansionOptionsResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'controlledHexes',
      'preferredHex',
      'candidates',
    }, 'city expansion options');
    return AonwCityExpansionOptionsResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'expansion city id'),
      controlledHexes: _cityCoordinates(
        value['controlledHexes'],
        'controlled expansion hexes',
      ),
      preferredHex: value['preferredHex'] == null
          ? null
          : AonwCoordinate.fromJson(value['preferredHex']),
      candidates: readList(
        value['candidates'],
        'city expansion candidates',
        (item, _) => AonwCityExpansionCandidate.fromJson(item),
      ),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final List<AonwCoordinate> controlledHexes;
  final AonwCoordinate? preferredHex;
  final List<AonwCityExpansionCandidate> candidates;
}

final class AonwCityExpansionCandidate {
  const AonwCityExpansionCandidate({
    required this.coordinate,
    required this.score,
    required this.distance,
    required this.tileYield,
  });

  factory AonwCityExpansionCandidate.fromJson(Object? source) {
    final value = readObject(source, 'city expansion candidate');
    requireKeys(value, const {
      'coordinate',
      'score',
      'distance',
      'tileYield',
    }, 'city expansion candidate');
    return AonwCityExpansionCandidate(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      score: readInt(value['score'], 'city expansion score'),
      distance: readUnsigned(value['distance'], 'city expansion distance'),
      tileYield: AonwYieldValue.fromJson(value['tileYield']),
    );
  }

  final AonwCoordinate coordinate;
  final int score;
  final int distance;
  final AonwYieldValue tileYield;
}

final class AonwCityYieldResult extends AonwQueryResult {
  AonwCityYieldResult({
    required this.stamp,
    required this.cityId,
    required List<AonwCityYieldContribution> contributions,
    required this.total,
  }) : contributions = List.unmodifiable(contributions);

  factory AonwCityYieldResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'cityId',
      'contributions',
      'total',
    }, 'city yield');
    return AonwCityYieldResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      cityId: readString(value['cityId'], 'yield city id'),
      contributions: readList(
        value['contributions'],
        'city yield contributions',
        (item, _) => AonwCityYieldContribution.fromJson(item),
      ),
      total: AonwYieldValue.fromJson(value['total']),
    );
  }

  final AonwSessionStamp stamp;
  final String cityId;
  final List<AonwCityYieldContribution> contributions;
  final AonwYieldValue total;
}

enum AonwCityYieldContributionKind {
  center,
  population,
  worker,
  passiveImprovement,
  artifact;

  factory AonwCityYieldContributionKind.fromJson(Object? source) =>
      values.firstWhere(
        (value) => value.name == readString(source, 'city yield kind'),
        orElse: () => throw FormatException(
          'Unknown AoNW city yield contribution kind $source.',
        ),
      );
}

final class AonwYieldValue {
  const AonwYieldValue({
    required this.food,
    required this.production,
    required this.gold,
    required this.defense,
  });

  factory AonwYieldValue.fromJson(Object? source) {
    final value = readObject(source, 'yield value');
    requireKeys(value, const {
      'food',
      'production',
      'gold',
      'defense',
    }, 'yield value');
    return AonwYieldValue(
      food: readInt(value['food'], 'food yield'),
      production: readInt(value['production'], 'production yield'),
      gold: readInt(value['gold'], 'gold yield'),
      defense: readInt(value['defense'], 'defense yield'),
    );
  }

  final int food;
  final int production;
  final int gold;
  final int defense;
}

final class AonwCityYieldContribution {
  const AonwCityYieldContribution({
    required this.kind,
    required this.coordinate,
    required this.value,
  });

  factory AonwCityYieldContribution.fromJson(Object? source) {
    final value = readObject(source, 'city yield contribution');
    requireKeys(value, const {
      'kind',
      'coordinate',
      'value',
    }, 'city yield contribution');
    return AonwCityYieldContribution(
      kind: AonwCityYieldContributionKind.fromJson(value['kind']),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      value: AonwYieldValue.fromJson(value['value']),
    );
  }

  final AonwCityYieldContributionKind kind;
  final AonwCoordinate coordinate;
  final AonwYieldValue value;
}

List<AonwCoordinate> _cityCoordinates(Object? source, String label) =>
    readList(source, label, (item, _) => AonwCoordinate.fromJson(item));
