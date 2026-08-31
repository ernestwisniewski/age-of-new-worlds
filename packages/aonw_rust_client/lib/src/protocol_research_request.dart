part of 'protocol.dart';

/// Research-specific request constructors for the strict client protocol.
abstract final class AonwResearchRequest {
  static AonwClientRequest options({required int expectedRevision}) =>
      AonwClientRequest._({
        'type': 'query',
        'query': {
          'type': 'researchOptions',
          'expectedRevision': expectedRevision,
        },
      });

  static AonwClientRequest select({
    required int expectedRevision,
    required AonwTechnologyId technology,
  }) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': 'selectTechnology',
      'expectedRevision': expectedRevision,
      'technologyId': technology.name,
    },
  });
}
