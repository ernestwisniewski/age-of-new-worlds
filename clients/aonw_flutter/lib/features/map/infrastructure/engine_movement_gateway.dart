import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../application/movement_session_port.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import 'engine_game_session_context.dart';
import 'engine_game_session_operations.dart';
import 'movement_view_mapper.dart';

final class EngineMovementGateway {
  const EngineMovementGateway({
    MovementViewMapper mapper = const MovementViewMapper(),
  }) : _mapper = mapper;

  final MovementViewMapper _mapper;

  Future<ReachableView> reachable({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String unitId,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwClientRequest.reachable(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwReachableResult) {
        throw const FormatException('Expected a reachable result.');
      }
      return _mapper.reachable(
        result,
        map: context.map,
        expectedUnitId: unitId,
        expectedRevision: expectedRevision,
      );
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _invalidResponse(error, stackTrace);
    }
  }

  Future<RoutePlanView> routePlan({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final unit = requireControlledUnit(context, unitId);
      final response = await send(
        context,
        AonwClientRequest.routePlan(
          expectedRevision: expectedRevision,
          unitId: unitId,
          targetCol: target.col,
          targetRow: target.row,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwRoutePlanResult) {
        throw const FormatException('Expected a route-plan result.');
      }
      return _mapper.routePlan(
        result,
        map: context.map,
        unit: unit,
        expectedTarget: target,
        expectedRevision: expectedRevision,
      );
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _invalidResponse(error, stackTrace);
    }
  }

  Future<MoveUnitResultView> moveUnit({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      requireControlledUnit(context, unitId);
      final response = await send(
        context,
        AonwClientRequest.moveUnit(
          expectedRevision: expectedRevision,
          unitId: unitId,
          targetCol: target.col,
          targetRow: target.row,
        ),
      );
      final command = response.require<AonwCommandResponse>().result;
      final execution = _mapper.validateCommand(
        command,
        map: context.map,
        expectedUnitId: unitId,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      if (!command.accepted) {
        return MoveUnitResultView.rejected(
          code: _mapper.rejectionCode(command.rejection!),
        );
      }
      return MoveUnitResultView.accepted(player: player, execution: execution);
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _invalidResponse(error, stackTrace);
    }
  }
}

MovementSessionException _invalidResponse(
  FormatException error,
  StackTrace stackTrace,
) => MovementSessionException(
  code: 'invalid_session_protocol',
  message: 'The movement response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);

MovementSessionException _transportFailure(
  EngineSessionTransportException error,
) => MovementSessionException(
  code: error.code,
  message: 'The movement request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);
