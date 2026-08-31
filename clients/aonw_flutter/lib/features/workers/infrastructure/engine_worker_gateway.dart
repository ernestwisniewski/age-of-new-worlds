import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/worker_session_port.dart';
import '../read_model/worker_view.dart';
import 'worker_view_mapper.dart';

final class EngineWorkerGateway {
  const EngineWorkerGateway({
    WorkerViewMapper mapper = const WorkerViewMapper(),
  }) : _mapper = mapper;

  final WorkerViewMapper _mapper;

  Future<WorkerOptionsView> options({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required String unitId,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      final worker = context.player.controlledUnitById(unitId);
      if (worker == null) {
        throw const FormatException('Worker is not recipient-controlled.');
      }
      final response = await send(
        context,
        AonwWorkerRequest.options(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      );
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwWorkerOptionsResult) {
        throw const FormatException('Expected worker options.');
      }
      return _mapper.options(
        result,
        map: context.map,
        worker: worker,
        expectedRevision: expectedRevision,
      );
    } on WorkerSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }

  Future<WorkerCommandResultView> execute({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required WorkerActionView action,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      if (context.player.controlledUnitById(action.unitId) == null) {
        throw const FormatException('Worker is not recipient-controlled.');
      }
      final response = await send(context, _request(action, expectedRevision));
      final command = response.require<AonwCommandResponse>().result;
      final mapped = _mapper.command(
        command,
        map: context.map,
        action: action,
        expectedRevision: expectedRevision,
        currentRevision: context.player.stamp.revision,
      );
      final player = await applyPatch(context, command);
      return mapped.rejection == null
          ? WorkerCommandResultView.accepted(
              player: player,
              automation: mapped.automation,
            )
          : WorkerCommandResultView.rejected(rejectionCode: mapped.rejection!);
    } on WorkerSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw _protocolFailure(error, stackTrace);
    }
  }
}

AonwClientRequest _request(WorkerActionView action, int expectedRevision) =>
    switch (action) {
      SelectWorkerImprovementActionView(:final unitId, :final improvement) =>
        AonwWorkerRequest.selectImprovement(
          expectedRevision: expectedRevision,
          unitId: unitId,
          improvement: AonwFieldImprovementKind.values.byName(improvement.name),
        ),
      ConfirmWorkerImprovementActionView(:final unitId, :final improvement) =>
        AonwWorkerRequest.confirmImprovement(
          expectedRevision: expectedRevision,
          unitId: unitId,
          improvement: AonwFieldImprovementKind.values.byName(improvement.name),
        ),
      CancelWorkerJobActionView(:final unitId) => AonwWorkerRequest.cancelJob(
        expectedRevision: expectedRevision,
        unitId: unitId,
      ),
      AssignWorkerToHexActionView(:final unitId) =>
        AonwWorkerRequest.assignToHex(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      CancelWorkerAssignmentActionView(:final unitId) =>
        AonwWorkerRequest.cancelAssignment(
          expectedRevision: expectedRevision,
          unitId: unitId,
        ),
      BuildRoadActionView(:final unitId) => AonwWorkerRequest.buildRoad(
        expectedRevision: expectedRevision,
        unitId: unitId,
      ),
      AutomateWorkerActionView(:final unitId) => AonwWorkerRequest.automate(
        expectedRevision: expectedRevision,
        unitId: unitId,
      ),
    };

WorkerSessionException _transportFailure(
  EngineSessionTransportException error,
) => WorkerSessionException(
  code: error.code,
  message: 'The worker request could not be completed.',
  diagnosticCause: error.diagnosticCause,
  diagnosticStackTrace: error.diagnosticStackTrace,
  resyncedPlayer: error.resyncedPlayer,
);

WorkerSessionException _protocolFailure(
  FormatException error,
  StackTrace stackTrace,
) => WorkerSessionException(
  code: 'invalid_session_protocol',
  message: 'The worker response is incompatible with this client.',
  diagnosticCause: error,
  diagnosticStackTrace: stackTrace,
);
