part of 'game_match_service.dart';

const _lobbyRefreshInterval = Duration(seconds: 2);
const _lobbyConnectionLifetime = Duration(seconds: 15);

/// A separate lease belongs to each authenticated subscription. Closing an old
/// tab must not disconnect another tab or a newly reclaimed participant seat.
Stream<GameLobbyView> _watchLobby(Session session, String rawMatchId) async* {
  final userIdentifier = _requireUser(session);
  final matchId = _identifier(rawMatchId, 'matchId');
  final match = await _matchByPublicId(session, matchId);
  final participant = await _participant(session, match.id!, userIdentifier);
  if (match.state != _matchStateLobby) {
    yield await _lobby(session, matchId);
    return;
  }
  final now = DateTime.now().toUtc();
  await GameLobbyConnection.db.deleteWhere(
    session,
    where: (table) =>
        table.matchId.equals(match.id!) & (table.expiresAt <= now),
  );
  var connection = await GameLobbyConnection.db.insertRow(
    session,
    GameLobbyConnection(
      matchId: match.id!,
      participantId: participant.id!,
      userIdentifier: userIdentifier,
      joinedAt: participant.joinedAt,
      expiresAt: now.add(_lobbyConnectionLifetime),
    ),
  );
  try {
    while (true) {
      final current = await _participant(session, match.id!, userIdentifier);
      if (current.id != participant.id ||
          current.joinedAt != participant.joinedAt) {
        throw _error('not_participant', 'The lobby membership has changed.');
      }
      connection = await GameLobbyConnection.db.updateRow(
        session,
        connection.copyWith(
          expiresAt: DateTime.now().toUtc().add(_lobbyConnectionLifetime),
        ),
      );
      final lobby = await _lobby(session, matchId);
      yield lobby;
      if (lobby.match.state != _matchStateLobby) return;
      await Future<void>.delayed(_lobbyRefreshInterval);
    }
  } finally {
    await GameLobbyConnection.db.deleteRow(session, connection);
  }
}

typedef _ConnectedLobbyParticipant = (int, String, DateTime);

Future<Set<_ConnectedLobbyParticipant>> _connectedLobbyParticipants(
  Session session,
  int matchId, {
  Transaction? transaction,
}) async {
  final now = DateTime.now().toUtc();
  final connections = await GameLobbyConnection.db.find(
    session,
    where: (table) => table.matchId.equals(matchId) & (table.expiresAt > now),
    transaction: transaction,
  );
  return {
    for (final connection in connections)
      (
        connection.participantId,
        connection.userIdentifier,
        connection.joinedAt,
      ),
  };
}
