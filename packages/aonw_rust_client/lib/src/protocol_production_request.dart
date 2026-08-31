part of 'protocol.dart';

/// Production-specific request constructors for the strict client protocol.
abstract final class AonwProductionRequest {
  static AonwClientRequest options({
    required int expectedRevision,
    required String cityId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'productionOptions',
      'expectedRevision': expectedRevision,
      'cityId': cityId,
    },
  });

  static AonwClientRequest strategicResources({
    required int expectedRevision,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'strategicResourceProjection',
      'expectedRevision': expectedRevision,
    },
  });

  static AonwClientRequest startBuilding({
    required int expectedRevision,
    required String cityId,
    required AonwCityBuildingType building,
  }) => _cityCommand('startBuilding', expectedRevision, cityId, {
    'building': building.name,
  });

  static AonwClientRequest startUnit({
    required int expectedRevision,
    required String cityId,
    required AonwUnitKind unit,
    int? resourceOptionIndex,
  }) => _cityCommand('startUnitProduction', expectedRevision, cityId, {
    'unit': unit.name,
    'resourceOptionIndex': resourceOptionIndex,
  });

  static AonwClientRequest startProject({
    required int expectedRevision,
    required String cityId,
    required AonwCityProjectType project,
  }) => _cityCommand('startCityProject', expectedRevision, cityId, {
    'project': project.name,
  });

  static AonwClientRequest startWonder({
    required int expectedRevision,
    required String cityId,
    required AonwWonderType wonder,
  }) => _cityCommand('startWonder', expectedRevision, cityId, {
    'wonder': wonder.name,
  });

  static AonwClientRequest setSpecialization({
    required int expectedRevision,
    required String cityId,
    required AonwCitySpecialization specialization,
  }) => _cityCommand('setCitySpecialization', expectedRevision, cityId, {
    'specialization': specialization.name,
  });

  static AonwClientRequest rush({
    required int expectedRevision,
    required String cityId,
  }) => _cityCommand('rushProduction', expectedRevision, cityId);

  static AonwClientRequest _cityCommand(
    String type,
    int expectedRevision,
    String cityId, [
    Map<String, Object?> fields = const {},
  ]) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': type,
      'expectedRevision': expectedRevision,
      'cityId': cityId,
      ...fields,
    },
  });
}
