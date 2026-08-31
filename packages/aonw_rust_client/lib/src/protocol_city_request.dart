part of 'protocol.dart';

/// City-specific request constructors for the strict client protocol.
abstract final class AonwCityRequest {
  static AonwClientRequest foundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'cityFoundingOptions',
      'expectedRevision': expectedRevision,
      'founderUnitId': founderUnitId,
    },
  });

  static AonwClientRequest workedHexOptions({
    required int expectedRevision,
    required String cityId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'cityWorkedHexOptions',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
    },
  });

  static AonwClientRequest expansionOptions({
    required int expectedRevision,
    required String cityId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'cityExpansionOptions',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
    },
  });

  static AonwClientRequest cityYield({
    required int expectedRevision,
    required String cityId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'cityYield',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
    },
  });

  static AonwClientRequest found({
    required int expectedRevision,
    required String founderUnitId,
    required List<AonwCoordinate> controlledHexes,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'foundCity',
      'expectedRevision': expectedRevision,
      'founderUnitId': founderUnitId,
      'controlledHexes': [
        for (final coordinate in controlledHexes)
          {'col': coordinate.col, 'row': coordinate.row},
      ],
    },
  });

  static AonwClientRequest toggleWorkedHex({
    required int expectedRevision,
    required String cityId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'toggleWorkedHex',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });

  static AonwClientRequest selectExpansionHex({
    required int expectedRevision,
    required String cityId,
    required int targetCol,
    required int targetRow,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'selectCityExpansionHex',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
      'target': {'col': targetCol, 'row': targetRow},
    },
  });
}
