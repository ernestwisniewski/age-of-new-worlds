part of 'game_match_service.dart';

/// Uses durable membership rather than active participation. Leaving gameplay
/// does not remove a completed match from the account's history. The cursor is
/// a stable membership order and is always scoped to the authenticated user.
Future<GameMatchHistoryPage> _matchHistory(
  Session session,
  int? beforeParticipantId,
) async {
  final user = _requireUser(session);
  if (beforeParticipantId != null && beforeParticipantId < 1) {
    throw _error('invalid_history_cursor', 'The history cursor is invalid.');
  }
  const pageSize = 50;
  final participants = await GameParticipant.db.find(
    session,
    where: (table) {
      var predicate =
          table.userIdentifier.equals(user) &
          table.match.state.equals('finished');
      if (beforeParticipantId != null) {
        predicate = predicate & (table.id < beforeParticipantId);
      }
      return predicate;
    },
    include: GameParticipant.include(match: GameMatch.include()),
    orderBy: (table) => table.id,
    orderDescending: true,
    limit: pageSize + 1,
  );
  final page = participants.take(pageSize).toList(growable: false);
  return GameMatchHistoryPage(
    entries: [for (final participant in page) _historyEntry(participant)],
    nextBeforeParticipantId: participants.length > pageSize
        ? page.last.id
        : null,
  );
}

GameMatchHistoryEntry _historyEntry(GameParticipant participant) {
  final match = participant.match!;
  return GameMatchHistoryEntry(
    match: _view(match),
    playerId: participant.playerId,
    turn: match.turn,
    endedAt: match.endedAt,
    outcomeCondition: match.outcomeCondition,
    winnerPlayerId: match.winnerPlayerId,
    resignedAt: participant.resignedAt,
    kickedAt: participant.kickedAt,
    replayAvailable: _hasReplayCheckpoint(match),
  );
}
