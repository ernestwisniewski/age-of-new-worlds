import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/turn_session_port.dart';
import '../read_model/turn_command_view.dart';
import 'turn_view_mapper.dart';

final class EngineTurnGateway {
  const EngineTurnGateway({TurnViewMapper mapper = const TurnViewMapper()})
    : _mapper = mapper;

  final TurnViewMapper _mapper;

  Future<TurnCommandResultView> execute({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required EngineRequestSender send,
    required EnginePatchApplier applyPatch,
  }) async {
    try {
      final context = readContext();
      final response = await send(
        context,
        AonwClientRequest.endTurn(expectedRevision: expectedRevision),
      );
      final command = response.require<AonwCommandResponse>().result;
      if (!command.accepted) {
        return _rejected(context, command, applyPatch);
      }
      final execution = _mapper.accepted(
        command,
        map: context.map,
        expectedRevision: expectedRevision,
      );
      final player = await applyPatch(context, command);
      return TurnCommandResultView.accepted(
        player: player,
        activities: execution.activities,
        evidence: execution.evidence,
      );
    } on TurnSessionException {
      rethrow;
    } on EngineSessionTransportException catch (error) {
      throw _transportFailure(error);
    } on FormatException catch (error, stackTrace) {
      throw TurnSessionException(
        code: 'invalid_session_protocol',
        message: 'The turn response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  Future<TurnCommandResultView> _rejected(
    EngineGameSessionContext context,
    AonwCommandResult command,
    EnginePatchApplier applyPatch,
  ) async {
    final rejection = _mapper.rejected(
      command,
      map: context.map,
      currentRevision: context.player.stamp.revision,
    );
    await applyPatch(context, command);
    return TurnCommandResultView.rejected(code: rejection);
  }
}

TurnSessionException _transportFailure(EngineSessionTransportException error) =>
    TurnSessionException(
      code: error.code,
      message: 'The turn request could not be completed.',
      diagnosticCause: error.diagnosticCause,
      diagnosticStackTrace: error.diagnosticStackTrace,
      resyncedPlayer: error.resyncedPlayer,
    );
