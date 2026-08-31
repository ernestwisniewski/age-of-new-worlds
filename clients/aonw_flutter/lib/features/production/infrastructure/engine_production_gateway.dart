import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/production_session_port.dart';
import '../read_model/production_view.dart';
import 'production_view_mapper.dart';

final class EngineProductionGateway {
  const EngineProductionGateway({
    ProductionViewMapper mapper = const ProductionViewMapper(),
  }) : _mapper = mapper;

  final ProductionViewMapper _mapper;

  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  overview({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String cityId,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      if (context.player.controlledCityById(cityId) == null) {
        throw const FormatException('Production city is not controlled.');
      }
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
      return (
        options: _mapper.options(
          options,
          map: context.map,
          player: context.player,
          cityId: cityId,
          expectedRevision: expectedRevision,
        ),
        resources: _mapper.resources(
          resources,
          map: context.map,
          player: context.player,
          expectedRevision: expectedRevision,
        ),
      );
    } on ProductionSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<ProductionCommandResultView> execute({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required ProductionActionView action,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      if (context.player.controlledCityById(action.cityId) == null) {
        throw const FormatException('Production city is not controlled.');
      }
      final response = await send(context, _request(action, expectedRevision));
      final command = response.require<AonwCommandResponse>().result;
      final mapped = _mapper.command(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      return mapped.rejection == null
          ? ProductionCommandResultView.accepted(player: player)
          : ProductionCommandResultView.rejected(
              rejectionCode: mapped.rejection!,
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

Future<T> _query<T extends AonwQueryResult>(
  EngineGameSessionContext context,
  AonwClientRequest request,
  EngineRequestSender send,
) async {
  final response = await send(context, request);
  final result = response.require<AonwQueryResponse>().result;
  if (result is! T) throw FormatException('Expected production query $T.');
  return result;
}

AonwClientRequest _request(ProductionActionView action, int expectedRevision) =>
    switch (action) {
      StartBuildingActionView(:final cityId, :final building) =>
        AonwProductionRequest.startBuilding(
          expectedRevision: expectedRevision,
          cityId: cityId,
          building: AonwCityBuildingType.values.byName(building),
        ),
      StartUnitProductionActionView(
        :final cityId,
        :final unit,
        :final resourceOptionIndex,
      ) =>
        AonwProductionRequest.startUnit(
          expectedRevision: expectedRevision,
          cityId: cityId,
          unit: AonwUnitKind.values.byName(unit.name),
          resourceOptionIndex: resourceOptionIndex,
        ),
      StartCityProjectActionView(:final cityId, :final project) =>
        AonwProductionRequest.startProject(
          expectedRevision: expectedRevision,
          cityId: cityId,
          project: AonwCityProjectType.values.byName(project),
        ),
      StartWonderActionView(:final cityId, :final wonder) =>
        AonwProductionRequest.startWonder(
          expectedRevision: expectedRevision,
          cityId: cityId,
          wonder: AonwWonderType.values.byName(wonder),
        ),
      SetCitySpecializationActionView(:final cityId, :final specialization) =>
        AonwProductionRequest.setSpecialization(
          expectedRevision: expectedRevision,
          cityId: cityId,
          specialization: AonwCitySpecialization.values.byName(specialization),
        ),
      RushProductionActionView(:final cityId) => AonwProductionRequest.rush(
        expectedRevision: expectedRevision,
        cityId: cityId,
      ),
    };

ProductionSessionException _transportFailure(
  EngineSessionTransportException error,
) => ProductionSessionException(
  code: error.code,
  message: 'The production request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

ProductionSessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => ProductionSessionException(
  code: 'invalid_session_protocol',
  message: 'The production response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
