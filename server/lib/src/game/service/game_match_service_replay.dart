part of 'game_match_service.dart';

Future<GameReplayFrame> _replayFrame(
  GameMatchService service,
  Session session,
  String rawMatchId,
  int position,
) async {
  final access = await _replayAccess(session, rawMatchId, position);
  final result = await _readReplay(service, session, access, position);
  return GameReplayFrame(
    matchId: access.match.publicId,
    playerId: access.playerId,
    frameJson: jsonEncode({
      'type': 'replayFrame',
      'position': position,
      'entryCount': access.entryCount,
      'recipientPlayerId': access.playerId,
      'snapshot': result['snapshot'],
      'command': result['command'],
    }),
  );
}

Future<GamePlayerQueryOutcome> _replayQuery(
  GameMatchService service,
  Session session,
  GamePlayerQueryRequest request,
  int position,
) async {
  final access = await _replayAccess(session, request.matchId, position);
  _document(
    request.queryJson,
    'queryJson',
    maximumBytes: _maximumQueryDocumentBytes,
  );
  final query = _translateNative(
    () => decodeGameObjectDocument(request.queryJson, 'query'),
  );
  final result = await _readReplay(service, session, access, position);
  final match = access.match;
  final content = _translateNative(
    () => service._native.prepareContent(
      mapDocument: match.mapDocument!,
      rulesetId: match.rulesetId,
      expectedMapHash: match.mapHash,
      expectedRulesetHash: match.rulesetHash,
    ),
  );
  final outcome = _translateNative(
    () => service._native.queryPlayer(
      content: content,
      authenticatedActorPlayerId: access.playerId,
      query: query,
      canonicalState: _object(result['state'], 'replay.state'),
    ),
  );
  _validateQueryOutcome(outcome);
  return GamePlayerQueryOutcome(
    matchId: match.publicId,
    outcomeJson: jsonEncode(outcome),
  );
}

Future<_ReplayAccess> _replayAccess(
  Session session,
  String rawMatchId,
  int position,
) async {
  final user = _requireUser(session);
  final match = await _matchByPublicId(
    session,
    _identifier(rawMatchId, 'matchId'),
  );
  final participant = await _participantForUser(session, match.id!, user);
  if (participant == null || participant.leftAt != null) {
    throw _error('not_participant', 'The account is not a match participant.');
  }
  if (match.state != _matchStateFinished) {
    throw _error(
      'replay_unavailable',
      'Only completed matches can be replayed.',
    );
  }
  if (!_hasReplayCheckpoint(match)) {
    throw _error('replay_unavailable', 'This match has no replay checkpoint.');
  }
  final count = match.revision - match.initialRevision!;
  if (count < 0 || position < 0 || position > count) {
    throw _error('invalid_replay_position', 'The replay position is invalid.');
  }
  return _ReplayAccess(match, participant.playerId, count);
}

Future<Map<String, Object?>> _readReplay(
  GameMatchService service,
  Session session,
  _ReplayAccess access,
  int position,
) async {
  final match = access.match;
  final content = _translateNative(
    () => service._native.prepareContent(
      mapDocument: match.mapDocument!,
      rulesetId: match.rulesetId,
      expectedMapHash: match.mapHash,
      expectedRulesetHash: match.rulesetHash,
    ),
  );
  var result = _translateNative(
    () => service._native.replayBatch(
      content: content,
      behaviorFingerprint: match.replayBehaviorFingerprint!,
      initialState: decodeGameObjectDocument(
        match.initialStateJson!,
        'initialState',
      ),
      initialStateDigest: match.initialStateDigest!,
      initialEventOffset: 0,
      recipientPlayerId: access.playerId,
      steps: const [],
    ),
  );
  if (_replayRevision(result) != match.initialRevision) {
    throw _error('replay_mismatch');
  }
  Map<String, Object?>? selected = position == 0 ? result : null;
  var current = 0;
  while (current < access.entryCount) {
    final remainingToTarget = position > current ? position - current : 256;
    final limit = remainingToTarget < 256 ? remainingToTarget : 256;
    final rows = await GameReplayEntry.db.find(
      session,
      where: (table) =>
          table.matchId.equals(match.id!) &
          (table.revision > _replayRevision(result)),
      orderBy: (table) => table.revision,
      limit: limit,
    );
    if (rows.isEmpty) throw _error('replay_mismatch');
    result = _translateNative(
      () => service._native.replayBatch(
        content: content,
        behaviorFingerprint: match.replayBehaviorFingerprint!,
        initialState: _object(result['state'], 'replay.state'),
        initialStateDigest: _string(
          _object(result['stamp'], 'stamp')['stateDigest'],
          'digest',
        ),
        initialEventOffset: _nonNegativeInt(
          result['finalEventOffset'],
          'offset',
        ),
        recipientPlayerId: access.playerId,
        steps: rows.map(_replayStep).toList(growable: false),
      ),
    );
    current += rows.length;
    if (current == position) selected = result;
  }
  await _verifyReplayEnd(session, access, result, current);
  _translateNative(
    () => service._native.replayBatch(
      content: content,
      behaviorFingerprint: match.replayBehaviorFingerprint!,
      initialState: decodeGameObjectDocument(
        match.canonicalStateJson!,
        'finalState',
      ),
      initialStateDigest: _string(
        _object(result['stamp'], 'stamp')['stateDigest'],
        'digest',
      ),
      initialEventOffset: match.eventOffset,
      recipientPlayerId: access.playerId,
      steps: const [],
    ),
  );
  return selected ?? (throw _error('replay_mismatch'));
}

Map<String, Object?> _replayStep(GameReplayEntry entry) {
  if ((entry.commandKind == 'player' && entry.actorPlayerId == null) ||
      (entry.commandKind == 'system' && entry.actorPlayerId != null) ||
      !{'player', 'system'}.contains(entry.commandKind)) {
    throw _error('replay_mismatch');
  }
  return {
    'record': {
      'kind': entry.commandKind,
      if (entry.commandKind == 'player') 'actorPlayerId': entry.actorPlayerId,
      'command': decodeGameObjectDocument(entry.commandJson, 'replay.command'),
    },
    'revision': entry.revision,
    'stateDigest': entry.stateDigest,
    'initialEventOffset': entry.initialEventOffset,
    'finalEventOffset': entry.finalEventOffset,
  };
}

Future<void> _verifyReplayEnd(
  Session session,
  _ReplayAccess access,
  Map<String, Object?> result,
  int count,
) async {
  final match = access.match;
  final finalSnapshot = await _snapshot(session, match.id!, access.playerId);
  final snapshot = decodeGameObjectDocument(
    finalSnapshot.snapshotJson,
    'snapshot',
  );
  final stamp = _object(result['stamp'], 'stamp');
  final expected = _object(snapshot['stamp'], 'snapshot.stamp');
  final rows = await GameReplayEntry.db.count(
    session,
    where: (table) => table.matchId.equals(match.id!),
  );
  if (count != access.entryCount ||
      rows != count ||
      _replayRevision(result) != match.revision ||
      result['finalEventOffset'] != match.eventOffset ||
      stamp['stateDigest'] != expected['stateDigest']) {
    throw _error('replay_mismatch');
  }
}

int _replayRevision(Map<String, Object?> result) =>
    _nonNegativeInt(_object(result['stamp'], 'stamp')['revision'], 'revision');

final class _ReplayAccess {
  const _ReplayAccess(this.match, this.playerId, this.entryCount);
  final GameMatch match;
  final String playerId;
  final int entryCount;
}

bool _hasReplayCheckpoint(GameMatch match) =>
    match.initialStateJson != null &&
    match.initialStateDigest != null &&
    match.initialRevision != null &&
    match.replayBehaviorFingerprint != null &&
    match.mapDocument != null &&
    match.canonicalStateJson != null;
