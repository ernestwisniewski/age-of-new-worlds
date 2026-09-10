part of 'game_match_service.dart';

Future<void> _persistReplayEntry(
  Session session,
  Transaction transaction,
  GameMatch match,
  _AppliedTurn applied, {
  required String? actorPlayerId,
  required Map<String, Object?> command,
}) async {
  if (match.initialStateJson == null ||
      applied.rejection != null ||
      applied.revision == match.revision) {
    return;
  }
  if (applied.revision != match.revision + 1) {
    throw StateError('Replay entries must advance one canonical revision.');
  }
  await GameReplayEntry.db.insertRow(
    session,
    GameReplayEntry(
      matchId: match.id!,
      revision: applied.revision,
      actorPlayerId: actorPlayerId,
      commandKind: actorPlayerId == null ? 'system' : 'player',
      commandJson: jsonEncode(command),
      stateDigest: _string(
        applied.stamp['stateDigest'],
        r'$.stamp.stateDigest',
      ),
      initialEventOffset: applied.initialOffset,
      finalEventOffset: applied.finalOffset,
    ),
    transaction: transaction,
  );
}
