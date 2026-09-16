part of 'serverpod_multiplayer_session.dart';

Future<MultiplayerMatchLobbyView> _createRemoteMatch(
  ServerpodMultiplayerSession session,
  MultiplayerMatchDocuments documents,
) async {
  session._ensureAuthenticated();
  try {
    final created = await session._client.game.createMatch(
      server.GameCreateMatchRequest(
        mapId: documents.mapId,
        mapDocument: documents.mapDocument,
        scenarioDocument: documents.scenarioDocument,
        rulesetId: documents.rulesetId,
        matchIdentityJson: documents.matchIdentityDocument,
        fogEnabled: documents.fogEnabled,
        creatorPlayerId: documents.creatorPlayerId,
      ),
    );
    final lobby = decodeServerLobby(
      await session._client.game.lobby(created.matchId),
    );
    _validateCreatedLobby(created, lobby, documents.creatorPlayerId);
    return lobby;
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

Future<MultiplayerMatchLobbyView> _joinRemoteMatch(
  ServerpodMultiplayerSession session, {
  required String matchId,
  required String playerId,
}) async {
  session._ensureAuthenticated();
  try {
    final joined = await session._client.game.joinMatch(
      server.GameJoinMatchRequest(matchId: matchId, playerId: playerId),
    );
    final lobby = decodeServerLobby(await session._client.game.lobby(matchId));
    _validateJoinedLobby(joined, lobby, playerId);
    return lobby;
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

Future<MultiplayerMatchLobbyView> _loadRemoteLobby(
  ServerpodMultiplayerSession session,
  String matchId,
) => _remoteLobbyCall(session, () => session._client.game.lobby(matchId));

Future<MultiplayerMatchLobbyView> _setRemoteReady(
  ServerpodMultiplayerSession session, {
  required String matchId,
  required bool ready,
}) => _remoteLobbyCall(
  session,
  () => session._client.game.setReady(matchId, ready),
);

Future<MultiplayerMatchLobbyView> _startRemoteMatch(
  ServerpodMultiplayerSession session,
  String matchId,
) => _remoteLobbyCall(session, () => session._client.game.startMatch(matchId));

Future<MultiplayerMatchLobbyView> _remoteLobbyCall(
  ServerpodMultiplayerSession session,
  Future<server.GameLobbyView> Function() operation,
) async {
  session._ensureAuthenticated();
  try {
    return decodeServerLobby(await operation());
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

void _validateCreatedLobby(
  server.GameMatchView created,
  MultiplayerMatchLobbyView lobby,
  String creatorPlayerId,
) {
  if (lobby.match.matchId == created.matchId &&
      lobby.match.revision == created.revision &&
      lobby.match.eventOffset == created.eventOffset &&
      lobby.currentParticipant.playerId == creatorPlayerId) {
    return;
  }
  throw const FormatException(
    'Created match and authoritative lobby do not agree.',
  );
}

Future<MultiplayerMatchView> _leaveRemoteLobby(
  ServerpodMultiplayerSession session,
  String matchId,
) async {
  session._ensureAuthenticated();
  try {
    final match = decodeServerMatch(
      await session._client.game.leaveLobby(matchId),
    );
    if (match.matchId != matchId) {
      throw const FormatException(
        'Leaving the lobby returned an inconsistent match.',
      );
    }
    return match;
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

Future<MultiplayerCommandView> _resignRemoteMatch(
  ServerpodMultiplayerSession session, {
  required String matchId,
  required String clientCommandId,
  required int expectedRevision,
}) async {
  session._ensureAuthenticated();
  try {
    return session._decoder.command(
      await session._client.game.resignMatch(
        server.GameResignMatchRequest(
          matchId: matchId,
          clientCommandId: clientCommandId,
          expectedRevision: expectedRevision,
        ),
      ),
    );
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

Future<MultiplayerCommandView> _kickRemoteParticipant(
  ServerpodMultiplayerSession session, {
  required String matchId,
  required String clientCommandId,
  required int expectedRevision,
  required String targetPlayerId,
}) async {
  session._ensureAuthenticated();
  try {
    return session._decoder.command(
      await session._client.game.kickParticipant(
        server.GameKickParticipantRequest(
          matchId: matchId,
          clientCommandId: clientCommandId,
          expectedRevision: expectedRevision,
          targetPlayerId: targetPlayerId,
        ),
      ),
    );
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}

void _validateJoinedLobby(
  server.GameResync joined,
  MultiplayerMatchLobbyView lobby,
  String playerId,
) {
  if (joined.matchId == lobby.match.matchId &&
      joined.playerId == lobby.currentParticipant.playerId &&
      joined.playerId == playerId) {
    return;
  }
  throw const FormatException(
    'Joined participant and authoritative lobby do not agree.',
  );
}
