import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/infrastructure/engine_game_session_context.dart';
import '../../map/infrastructure/engine_game_session_operations.dart';
import '../application/turn_session_port.dart';
import '../read_model/pending_turn_actions_view.dart';
import 'pending_turn_actions_view_mapper.dart';

final class EnginePendingTurnActionsGateway {
  const EnginePendingTurnActionsGateway();

  Future<PendingTurnActionsView> query({
    required EngineGameSessionContextReader readContext,
    required int expectedRevision,
    required EngineRequestSender send,
  }) async {
    try {
      final context = readContext();
      if (context.actorPlayerId != context.player.actorPlayerId) {
        throw const FormatException(
          'Pending turn actions recipient is inconsistent.',
        );
      }
      final response = await send(
        context,
        AonwClientRequest.pendingTurnActions(
          expectedRevision: expectedRevision,
        ),
      );
      _ensureRecipient(context, readContext());
      final result = response.require<AonwQueryResponse>().result;
      if (result is! AonwPendingTurnActionsResult) {
        throw const FormatException('Expected pending turn actions response.');
      }
      return const PendingTurnActionsViewMapper().fromWire(
        result,
        map: context.map,
        player: context.player,
        expectedRevision: expectedRevision,
      );
    } on EngineSessionTransportException catch (error) {
      throw TurnSessionException(
        code: error.code,
        message: 'The pending turn actions request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    } on FormatException catch (error, stackTrace) {
      throw TurnSessionException(
        code: 'invalid_session_protocol',
        message:
            'The pending turn actions response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}

void _ensureRecipient(
  EngineGameSessionContext before,
  EngineGameSessionContext after,
) {
  final first = before.player.stamp;
  final last = after.player.stamp;
  if (!identical(before.session, after.session) ||
      (
            before.generation,
            before.actorPlayerId,
            before.map.mapId,
            before.map.contentHash,
          ) !=
          (
            after.generation,
            after.actorPlayerId,
            after.map.mapId,
            after.map.contentHash,
          ) ||
      after.actorPlayerId != after.player.actorPlayerId ||
      (first.revision, first.stateDigest, first.mapHash, first.rulesetHash) !=
          (last.revision, last.stateDigest, last.mapHash, last.rulesetHash)) {
    throw const EngineSessionTransportException(
      code: 'session_superseded',
      message: 'The pending turn actions recipient state was replaced.',
    );
  }
}
