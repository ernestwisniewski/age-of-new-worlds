part of 'game_match_service.dart';

Future<bool> _finalizeTimedOutTurn(
  GameMatchService service,
  Session session, {
  required String matchId,
  required DateTime now,
}) => session.db.transaction(
  (transaction) => _finalizeTimedOutTurnTransaction(
    service,
    session,
    transaction,
    matchId: _identifier(matchId, 'matchId'),
    now: now.toUtc(),
  ),
);

Future<bool> _finalizeTimedOutTurnTransaction(
  GameMatchService service,
  Session session,
  Transaction transaction, {
  required String matchId,
  required DateTime now,
}) async {
  final match = await _matchByPublicId(
    session,
    matchId,
    transaction: transaction,
    lock: true,
  );
  final deadline = match.turnDeadlineAt;
  if (match.state != _matchStateRunning ||
      deadline == null ||
      deadline.toUtc().isAfter(now)) {
    return false;
  }
  final state = _persistedState(match);
  final selection = _timeoutSelection(state);
  if (selection.skippedPlayerIds.isEmpty) {
    throw StateError('An expired turn has no participants left to finalize.');
  }
  final participant = await _timeoutOutcomeRecipient(
    session,
    transaction,
    match.id!,
  );
  final command = {
    'type': 'finalizeTimedOutTurn',
    'expectedRevision': match.revision,
    'playerIds': selection.playerIds,
    'skippedPlayerIds': selection.skippedPlayerIds,
    'nextTurnStartedAt': now.toIso8601String(),
  };
  final context = _CommandContext(
    match: match,
    participant: participant,
    duplicate: null,
  );
  final applied = _executeSystemCommand(service, context, command);
  if (applied.rejection != null) {
    throw StateError('The canonical engine rejected an expired turn scope.');
  }
  await _persistSystemTurn(session, transaction, context, applied);
  return true;
}

Future<GameParticipant> _timeoutOutcomeRecipient(
  Session session,
  Transaction transaction,
  int matchId,
) async {
  final participants = await _matchParticipants(
    session,
    matchId,
    transaction: transaction,
    lock: true,
  );
  final active = participants.where(_isActiveParticipant).toList()
    ..sort(_compareParticipantJoinOrder);
  if (active.isEmpty) {
    throw StateError('An expired match has no active recipient.');
  }
  return active.first;
}

Future<void> _persistSystemTurn(
  Session session,
  Transaction transaction,
  _CommandContext context,
  _AppliedTurn applied,
) async {
  await _updateMatch(session, transaction, context.match, applied);
  await _insertEvents(session, transaction, context.match.id!, applied);
  await _persistRecipientSnapshots(
    session,
    context.match.id!,
    applied.finalOffset,
    applied.recipients,
    applied.now,
    transaction,
  );
}

_TimedOutTurnSelection _timeoutSelection(Map<String, Object?> state) {
  final identity = _object(state['matchIdentity'], r'$.state.matchIdentity');
  final lifecycle = _object(state['turnLifecycle'], r'$.state.turnLifecycle');
  final required = _playerIdSet(
    lifecycle['requiredSubmissionPlayerIds'],
    r'$.state.turnLifecycle.requiredSubmissionPlayerIds',
  );
  final submitted = _playerIdSet(
    lifecycle['submittedPlayerIds'],
    r'$.state.turnLifecycle.submittedPlayerIds',
  );
  final removed = {
    ..._playerIdSet(
      lifecycle['kickedPlayerIds'],
      r'$.state.turnLifecycle.kickedPlayerIds',
    ),
    ..._playerIdSet(
      lifecycle['resignedPlayerIds'],
      r'$.state.turnLifecycle.resignedPlayerIds',
    ),
  };
  final playerIds =
      _list(identity['participants'], r'$.state.matchIdentity.participants')
          .map((value) => _timeoutParticipantId(value, required, removed))
          .whereType<String>()
          .toList(growable: false);
  return _TimedOutTurnSelection(
    playerIds: playerIds,
    skippedPlayerIds: [
      for (final playerId in playerIds)
        if (!submitted.contains(playerId)) playerId,
    ],
  );
}

String? _timeoutParticipantId(
  Object? value,
  Set<String> required,
  Set<String> removed,
) {
  final participant = _object(value, r'$.state.matchIdentity.participant');
  final playerId = _identifier(
    _string(participant['id'], r'$.state.matchIdentity.participant.id'),
    'playerId',
  );
  return !removed.contains(playerId) &&
          (required.isEmpty || required.contains(playerId))
      ? playerId
      : null;
}

Set<String> _playerIdSet(Object? value, String path) {
  final result = <String>{};
  for (final (index, item) in _list(value, path).indexed) {
    final playerId = _identifier(_string(item, '$path[$index]'), 'playerId');
    if (!result.add(playerId)) {
      throw StateError('Canonical turn lifecycle contains a duplicate player.');
    }
  }
  return result;
}

final class _TimedOutTurnSelection {
  const _TimedOutTurnSelection({
    required this.playerIds,
    required this.skippedPlayerIds,
  });

  final List<String> playerIds;
  final List<String> skippedPlayerIds;
}
