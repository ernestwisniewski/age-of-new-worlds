import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../application/movement_session_port.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import 'movement_view_mapper.dart';
import 'rust_game_session_context.dart';
import 'rust_game_session_operations.dart';

final class RustMovementGateway {
  const RustMovementGateway({
    MovementViewMapper mapper = const MovementViewMapper(),
  }) : _mapper = mapper;

  final MovementViewMapper _mapper;

  Future<ReachableView> reachable({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required RustRequestSender send,
  }) async {
    try {
      final response = await send(
        context.session,
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
    } on MovementSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw _invalidResponse(error, stackTrace);
    }
  }

  Future<RoutePlanView> routePlan({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
    required RustRequestSender send,
  }) async {
    try {
      final unit = requireControlledUnit(context, unitId);
      final response = await send(
        context.session,
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
    } on MovementSessionException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw _invalidResponse(error, stackTrace);
    }
  }

  Future<MoveUnitResultView> moveUnit({
    required RustGameSessionContext context,
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
    required RustRequestSender send,
    required RustPatchApplier applyPatch,
  }) async {
    try {
      requireControlledUnit(context, unitId);
      final response = await send(
        context.session,
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
    } on MovementSessionException {
      rethrow;
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
