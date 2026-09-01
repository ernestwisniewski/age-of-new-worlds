part of 'game_match_service.dart';

Future<GameLobbyView> _lobby(Session session, String rawMatchId) async {
  final userIdentifier = _requireUser(session);
  final match = await _matchByPublicId(
    session,
    _identifier(rawMatchId, 'matchId'),
  );
  final participant = await _participant(session, match.id!, userIdentifier);
  final participants = await _matchParticipants(session, match.id!);
  return _lobbyView(match, participant, participants);
}

Future<GameLobbyView> _setReady(
  Session session,
  String rawMatchId,
  bool ready,
) {
  final userIdentifier = _requireUser(session);
  final matchId = _identifier(rawMatchId, 'matchId');
  return session.db.transaction((transaction) async {
    final match = await _matchByPublicId(
      session,
      matchId,
      transaction: transaction,
      lock: true,
    );
    _requireLobby(match);
    final participant = await _participant(
      session,
      match.id!,
      userIdentifier,
      transaction: transaction,
    );
    final now = DateTime.now().toUtc();
    final updated = await GameParticipant.db.updateRow(
      session,
      participant.copyWith(readyAt: ready ? now : null),
      transaction: transaction,
    );
    final participants = await _matchParticipants(
      session,
      match.id!,
      transaction: transaction,
      lock: true,
    );
    return _lobbyView(match, updated, participants);
  });
}

Future<GameLobbyView> _startMatch(Session session, String rawMatchId) {
  final userIdentifier = _requireUser(session);
  final matchId = _identifier(rawMatchId, 'matchId');
  return session.db.transaction((transaction) async {
    final match = await _matchByPublicId(
      session,
      matchId,
      transaction: transaction,
      lock: true,
    );
    _requireLobby(match);
    final caller = await _participant(
      session,
      match.id!,
      userIdentifier,
      transaction: transaction,
    );
    if (caller.playerId != match.hostPlayerId) {
      throw _error('host_required', 'Only the lobby host can start the match.');
    }
    final participants = await _matchParticipants(
      session,
      match.id!,
      transaction: transaction,
      lock: true,
    );
    final lobby = _lobbyView(match, caller, participants);
    if (!lobby.canStart) {
      throw _error(
        'lobby_not_ready',
        'Every human participant must claim a seat and be ready.',
      );
    }
    final now = DateTime.now().toUtc();
    final started = await GameMatch.db.updateRow(
      session,
      match.copyWith(state: _matchStateRunning, startedAt: now, updatedAt: now),
      transaction: transaction,
    );
    return _lobbyView(started, caller, participants);
  });
}

Future<List<GameParticipant>> _matchParticipants(
  Session session,
  int matchId, {
  Transaction? transaction,
  bool lock = false,
}) => GameParticipant.db.find(
  session,
  where: (table) => table.matchId.equals(matchId),
  transaction: transaction,
  lockMode: lock ? LockMode.forUpdate : null,
  lockBehavior: lock ? LockBehavior.wait : null,
);

void _requireLobby(GameMatch match) {
  if (match.state != _matchStateLobby) {
    throw _error(
      'match_already_started',
      'The match is no longer accepting lobby changes.',
    );
  }
}

GameLobbyView _lobbyView(
  GameMatch match,
  GameParticipant caller,
  List<GameParticipant> claims,
) {
  final hostPlayerId = match.hostPlayerId;
  if (hostPlayerId == null) {
    throw StateError('Lobby host identity is unavailable.');
  }
  final canonical = _canonicalParticipants(match);
  final claimsByPlayer = {for (final claim in claims) claim.playerId: claim};
  final participants = <GameLobbyParticipantView>[];
  var everyHumanReady = true;
  for (final (index, value) in canonical.indexed) {
    final participant = _object(
      value,
      r'$.state.matchIdentity.participants'
      '[$index]',
    );
    final playerId = _identifier(
      _string(participant['id'], r'$.participant.id'),
      'playerId',
    );
    final kind = _string(participant['kind'], r'$.participant.kind');
    final claim = claimsByPlayer[playerId];
    final human = kind == 'human';
    final ready = !human || claim?.readyAt != null;
    if (human && (claim == null || !ready)) everyHumanReady = false;
    participants.add(
      GameLobbyParticipantView(
        playerId: playerId,
        name: _string(participant['name'], r'$.participant.name'),
        kind: kind,
        isHost: playerId == hostPlayerId,
        isClaimed: claim != null,
        isReady: ready,
        isCurrentUser: claim?.userIdentifier == caller.userIdentifier,
      ),
    );
  }
  return GameLobbyView(
    match: _view(match),
    participants: participants,
    canStart:
        match.state == _matchStateLobby &&
        caller.playerId == hostPlayerId &&
        everyHumanReady,
  );
}

void _requireHumanSeat(GameMatch match, String playerId) {
  _requireHumanParticipant(_canonicalParticipants(match), playerId);
}

void _requireHumanParticipantState(
  Map<String, Object?> state,
  String playerId,
) {
  final identity = _object(state['matchIdentity'], r'$.state.matchIdentity');
  _requireHumanParticipant(
    _list(identity['participants'], r'$.state.matchIdentity.participants'),
    playerId,
  );
}

void _requireHumanParticipant(List<Object?> participants, String playerId) {
  final participant = participants
      .map((value) => _object(value, r'$.state.matchIdentity.participant'))
      .where((value) => _string(value['id'], r'$.participant.id') == playerId)
      .firstOrNull;
  if (participant == null) {
    throw _error('participant_not_found', 'Match participant was not found.');
  }
  if (_string(participant['kind'], r'$.participant.kind') != 'human') {
    throw _error(
      'participant_not_claimable',
      'Computer-controlled participant seats cannot be claimed.',
    );
  }
}

List<Object?> _canonicalParticipants(GameMatch match) {
  final state = _persistedState(match);
  final identity = _object(state['matchIdentity'], r'$.state.matchIdentity');
  return _list(identity['participants'], r'$.state.matchIdentity.participants');
}
