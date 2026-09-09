import 'engine_game_session_context.dart';
import 'engine_game_session_operations.dart';

void ensureEngineQueryContext(
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
      (first.revision, first.stateDigest, first.mapHash, first.rulesetHash) !=
          (last.revision, last.stateDigest, last.mapHash, last.rulesetHash)) {
    throw const EngineSessionTransportException(
      code: 'session_superseded',
      message: 'The queried recipient state was replaced.',
    );
  }
}
