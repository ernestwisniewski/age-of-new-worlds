part of 'engine_production_gateway.dart';

extension EngineProductionInspection on EngineProductionGateway {
  Future<ProductionDetailsView> details({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String cityId,
    required ProductionTargetView target,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      if (context.player.controlledCityById(cityId) == null) {
        throw const FormatException('Production city is not controlled.');
      }
      final result = await _query<AonwProductionDetailsResult>(
        context,
        AonwProductionRequest.details(
          expectedRevision: expectedRevision,
          cityId: cityId,
          target: _wireTarget(target),
        ),
        send,
      );
      return _mapper.details(
        result,
        map: context.map,
        player: context.player,
        cityId: cityId,
        target: target,
        expectedRevision: expectedRevision,
      );
    } on ProductionSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

AonwCityProductionTarget _wireTarget(ProductionTargetView target) =>
    switch (target) {
      BuildingProductionTargetView(:final building) =>
        AonwCityProductionTarget.building(
          AonwCityBuildingType.values.byName(building),
        ),
      UnitProductionTargetView(:final unit) => AonwCityProductionTarget.unit(
        AonwUnitKind.values.byName(unit.name),
      ),
      WonderProductionTargetView(:final wonder) =>
        AonwCityProductionTarget.wonder(AonwWonderType.values.byName(wonder)),
      ProjectProductionTargetView(:final project) =>
        AonwCityProductionTarget.project(
          AonwCityProjectType.values.byName(project),
        ),
    };

Future<
  (
    AonwProductionOptionsResult,
    AonwStrategicResourceProjectionResult,
    AonwProductionBuildingRanksResult,
  )
>
_overviewQueries(
  EngineGameSessionContext context,
  int expectedRevision,
  String cityId,
  EngineRequestSender send,
) async {
  final options = await _query<AonwProductionOptionsResult>(
    context,
    AonwProductionRequest.options(
      expectedRevision: expectedRevision,
      cityId: cityId,
    ),
    send,
  );
  final resources = await _query<AonwStrategicResourceProjectionResult>(
    context,
    AonwProductionRequest.strategicResources(
      expectedRevision: expectedRevision,
    ),
    send,
  );
  final ranks = await _query<AonwProductionBuildingRanksResult>(
    context,
    AonwProductionRequest.buildingRanks(
      expectedRevision: expectedRevision,
      cityId: cityId,
    ),
    send,
  );
  return (options, resources, ranks);
}
