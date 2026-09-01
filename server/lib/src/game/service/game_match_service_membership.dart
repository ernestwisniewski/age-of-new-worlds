part of 'game_match_service.dart';

Future<GameResync> _joinMatch(Session session, GameJoinMatchRequest request) {
  final claim = _ParticipantClaim(
    userIdentifier: _requireUser(session),
    matchId: _identifier(request.matchId, 'matchId'),
    playerId: _identifier(request.playerId, 'playerId'),
  );
  return session.db.transaction(
    (transaction) => _joinTransaction(session, transaction, claim),
  );
}

Future<GameResync> _joinTransaction(
  Session session,
  Transaction transaction,
  _ParticipantClaim claim,
) async {
  final match = await _matchByPublicId(
    session,
    claim.matchId,
    transaction: transaction,
    lock: true,
  );
  final existingUser = await _participantForUser(
    session,
    match.id!,
    claim.userIdentifier,
    transaction: transaction,
    lock: true,
  );
  _assertUserCanClaim(existingUser, claim.playerId);
  if (match.state != _matchStateLobby && existingUser == null) {
    throw _error(
      'match_already_started',
      'New participant seats cannot be claimed after the match starts.',
    );
  }
  _requireHumanSeat(match, claim.playerId);
  final snapshot = await _snapshot(
    session,
    match.id!,
    claim.playerId,
    transaction: transaction,
    lock: true,
  );
  final existingPlayer = await _participantForPlayer(
    session,
    match.id!,
    claim.playerId,
    transaction: transaction,
    lock: true,
  );
  _assertPlayerCanBeClaimed(existingPlayer, claim.userIdentifier);
  if (existingUser == null) {
    await _insertParticipant(session, transaction, match.id!, claim);
  }
  return _resyncView(match.publicId, claim.playerId, snapshot);
}

void _assertUserCanClaim(GameParticipant? existing, String playerId) {
  if (existing != null && existing.playerId != playerId) {
    throw _error(
      'already_joined',
      'The authenticated account already owns another participant.',
    );
  }
}

void _assertPlayerCanBeClaimed(
  GameParticipant? existing,
  String userIdentifier,
) {
  if (existing != null && existing.userIdentifier != userIdentifier) {
    throw _error(
      'participant_claimed',
      'This match participant already belongs to another account.',
    );
  }
}

Future<void> _insertParticipant(
  Session session,
  Transaction transaction,
  int matchId,
  _ParticipantClaim claim,
) => GameParticipant.db.insertRow(
  session,
  GameParticipant(
    matchId: matchId,
    userIdentifier: claim.userIdentifier,
    playerId: claim.playerId,
    joinedAt: DateTime.now().toUtc(),
    readyAt: null,
    leftAt: null,
    resignedAt: null,
    kickedAt: null,
    kickReason: null,
  ),
  transaction: transaction,
);

Future<List<GameMatchView>> _listMatches(Session session) async {
  final participants = await GameParticipant.db.find(
    session,
    where: (table) => table.userIdentifier.equals(_requireUser(session)),
    limit: 100,
    orderBy: (table) => table.joinedAt,
    orderDescending: true,
  );
  final matches = <GameMatchView>[];
  for (final participant in participants) {
    final match = await GameMatch.db.findById(session, participant.matchId);
    if (match != null) matches.add(_view(match));
  }
  return matches;
}

Future<GameResync> _resync(Session session, String rawMatchId) async {
  final userIdentifier = _requireUser(session);
  final match = await _matchByPublicId(
    session,
    _identifier(rawMatchId, 'matchId'),
  );
  final participant = await _participant(session, match.id!, userIdentifier);
  final snapshot = await _snapshot(session, match.id!, participant.playerId);
  return _resyncView(match.publicId, participant.playerId, snapshot);
}

GameResync _resyncView(
  String matchId,
  String playerId,
  GameRecipientSnapshot snapshot,
) => GameResync(
  matchId: matchId,
  playerId: playerId,
  eventOffset: snapshot.eventOffset,
  snapshotJson: snapshot.snapshotJson,
);

final class _ParticipantClaim {
  const _ParticipantClaim({
    required this.userIdentifier,
    required this.matchId,
    required this.playerId,
  });

  final String userIdentifier;
  final String matchId;
  final String playerId;
}
