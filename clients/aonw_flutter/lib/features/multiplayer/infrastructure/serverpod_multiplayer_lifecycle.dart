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
    final lobby = _decodeLobby(
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
    final lobby = _decodeLobby(await session._client.game.lobby(matchId));
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
    return _decodeLobby(await operation());
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
    final match = _decodeMatch(await session._client.game.leaveLobby(matchId));
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

MultiplayerMatchView _decodeMatch(server.GameMatchView value) {
  final phase = _decodeMatchPhase(value.state);
  _validateMatchIdentity(value);
  _validateMatchLifecycle(value, phase);
  _validateMatchOffsets(value);
  return MultiplayerMatchView(
    matchId: value.matchId,
    mapId: value.mapId,
    mapHash: value.mapHash,
    rulesetId: value.rulesetId,
    rulesetHash: value.rulesetHash,
    phase: phase,
    hostPlayerId: value.hostPlayerId,
    startedAt: value.startedAt?.toUtc(),
    revision: value.revision,
    eventOffset: value.eventOffset,
  );
}

MultiplayerMatchPhase _decodeMatchPhase(String value) => switch (value) {
  'lobby' => MultiplayerMatchPhase.lobby,
  'running' => MultiplayerMatchPhase.running,
  'finished' => MultiplayerMatchPhase.finished,
  'abandoned' => MultiplayerMatchPhase.abandoned,
  _ => throw const FormatException('The server returned an invalid match.'),
};

void _validateMatchIdentity(server.GameMatchView value) {
  if (value.matchId.isEmpty ||
      value.mapId.isEmpty ||
      value.mapHash.isEmpty ||
      value.rulesetId.isEmpty ||
      value.rulesetHash.isEmpty ||
      (value.hostPlayerId?.isEmpty ?? false)) {
    throw const FormatException('The server returned an invalid match.');
  }
}

void _validateMatchLifecycle(
  server.GameMatchView value,
  MultiplayerMatchPhase phase,
) {
  final waiting = phase == MultiplayerMatchPhase.lobby;
  if (waiting && (value.hostPlayerId == null || value.startedAt != null)) {
    throw const FormatException('The server returned an invalid match.');
  }
  if (!waiting && value.startedAt == null) {
    if (phase == MultiplayerMatchPhase.abandoned) return;
    throw const FormatException('The server returned an invalid match.');
  }
}

void _validateMatchOffsets(server.GameMatchView value) {
  if (value.revision < 0 || value.eventOffset < 0) {
    throw const FormatException('The server returned an invalid match.');
  }
}

MultiplayerMatchLobbyView _decodeLobby(server.GameLobbyView value) {
  final match = _decodeMatch(value.match);
  final seen = <String>{};
  final participants = [
    for (final participant in value.participants)
      _decodeLobbyParticipant(participant, seen),
  ];
  _validateLobbyRoster(match, participants);
  _validateCanStart(match, participants, value.canStart);
  return MultiplayerMatchLobbyView(
    match: match,
    participants: List.unmodifiable(participants),
    canStart: value.canStart,
  );
}

MultiplayerLobbyParticipantView _decodeLobbyParticipant(
  server.GameLobbyParticipantView value,
  Set<String> seen,
) {
  if (value.playerId.isEmpty || value.name.isEmpty) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  if (value.kind != 'human' && value.kind != 'ai') {
    throw const FormatException('The server returned an invalid lobby.');
  }
  if (!seen.add(value.playerId) ||
      (value.isCurrentUser && !value.isClaimed) ||
      (value.kind == 'ai' && !value.isReady)) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  return MultiplayerLobbyParticipantView(
    playerId: value.playerId,
    name: value.name,
    kind: value.kind,
    isHost: value.isHost,
    isClaimed: value.isClaimed,
    isReady: value.isReady,
    isCurrentUser: value.isCurrentUser,
  );
}

void _validateLobbyRoster(
  MultiplayerMatchView match,
  List<MultiplayerLobbyParticipantView> participants,
) {
  final current = participants.where((value) => value.isCurrentUser).toList();
  final hosts = participants.where((value) => value.isHost).toList();
  if (participants.isEmpty || current.length != 1 || hosts.length != 1) {
    throw const FormatException('The server returned an invalid lobby.');
  }
  if (hosts.single.playerId != match.hostPlayerId) {
    throw const FormatException('The server returned an invalid lobby.');
  }
}

void _validateCanStart(
  MultiplayerMatchView match,
  List<MultiplayerLobbyParticipantView> participants,
  bool canStart,
) {
  final current = participants.singleWhere((value) => value.isCurrentUser);
  final humans = participants.where((value) => value.kind == 'human');
  final expected =
      match.phase == MultiplayerMatchPhase.lobby &&
      current.isHost &&
      humans.every((value) => value.isClaimed && value.isReady);
  if (canStart != expected) {
    throw const FormatException('The server returned an invalid lobby.');
  }
}
