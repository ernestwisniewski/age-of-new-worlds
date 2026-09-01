part of 'game_match_service.dart';

const _hostKickReason = 'host_removed';

Future<GameCommandOutcome> _kickParticipant(
  GameMatchService service,
  Session session,
  GameKickParticipantRequest request,
) {
  if (request.expectedRevision < 0) {
    throw _error('invalid_revision', 'expectedRevision must be non-negative.');
  }
  final input = _CommandInput(
    userIdentifier: _requireUser(session),
    matchId: _identifier(request.matchId, 'matchId'),
    clientCommandId: _identifier(request.clientCommandId, 'clientCommandId'),
    expectedRevision: request.expectedRevision,
    command: {
      'type': 'kickParticipant',
      'expectedRevision': request.expectedRevision,
      'playerId': _identifier(request.targetPlayerId, 'targetPlayerId'),
      'reason': _hostKickReason,
      'timeoutStreak': 0,
    },
  );
  return session.db.transaction(
    (transaction) => _kickTransaction(service, session, transaction, input),
  );
}

Future<GameCommandOutcome> _resignMatch(
  GameMatchService service,
  Session session,
  GameResignMatchRequest request,
) {
  if (request.expectedRevision < 0) {
    throw _error('invalid_revision', 'expectedRevision must be non-negative.');
  }
  final input = _CommandInput(
    userIdentifier: _requireUser(session),
    matchId: _identifier(request.matchId, 'matchId'),
    clientCommandId: _identifier(request.clientCommandId, 'clientCommandId'),
    expectedRevision: request.expectedRevision,
    command: const {},
  );
  return session.db.transaction(
    (transaction) => _resignTransaction(service, session, transaction, input),
  );
}

Future<GameCommandOutcome> _resignTransaction(
  GameMatchService service,
  Session session,
  Transaction transaction,
  _CommandInput input,
) async {
  final context = await _loadResignContext(session, transaction, input);
  final duplicate = context.duplicate;
  if (duplicate != null) {
    return _ledgerOutcome(context.match.publicId, duplicate, duplicate: true);
  }
  _requireRunningMatch(context.match);
  if (!_isActiveParticipant(context.participant)) {
    throw _error('not_participant', 'The account is not a match participant.');
  }
  final command = {
    'type': 'resignParticipant',
    'expectedRevision': input.expectedRevision,
    'playerId': context.participant.playerId,
  };
  final boundInput = _CommandInput(
    userIdentifier: input.userIdentifier,
    matchId: input.matchId,
    clientCommandId: input.clientCommandId,
    expectedRevision: input.expectedRevision,
    command: command,
  );
  final applied = _executeSystemCommand(service, context, command);
  final outcome = await _persistAppliedTurn(
    session,
    transaction,
    context,
    boundInput,
    applied,
  );
  if (applied.rejection == null) {
    await GameParticipant.db.updateRow(
      session,
      context.participant.copyWith(readyAt: null, resignedAt: applied.now),
      transaction: transaction,
    );
  }
  return outcome;
}

Future<_CommandContext> _loadResignContext(
  Session session,
  Transaction transaction,
  _CommandInput input,
) async {
  final match = await _matchByPublicId(
    session,
    input.matchId,
    transaction: transaction,
    lock: true,
  );
  final participant = await _participantForUser(
    session,
    match.id!,
    input.userIdentifier,
    transaction: transaction,
    lock: true,
  );
  if (participant == null) {
    throw _error('not_participant', 'The account is not a match participant.');
  }
  final duplicate = await _commandLedger(
    session,
    transaction,
    match.id!,
    participant.playerId,
    input.clientCommandId,
  );
  return _CommandContext(
    match: match,
    participant: participant,
    duplicate: duplicate,
  );
}

Future<GameCommandLedger?> _commandLedger(
  Session session,
  Transaction transaction,
  int matchId,
  String playerId,
  String clientCommandId,
) => GameCommandLedger.db.findFirstRow(
  session,
  where: (table) =>
      (table.matchId.equals(matchId)) &
      (table.playerId.equals(playerId)) &
      (table.clientCommandId.equals(clientCommandId)),
  transaction: transaction,
);

Future<GameCommandOutcome> _kickTransaction(
  GameMatchService service,
  Session session,
  Transaction transaction,
  _CommandInput input,
) async {
  final context = await _loadCommandContext(session, transaction, input);
  final duplicate = context.duplicate;
  if (duplicate != null) {
    return _ledgerOutcome(context.match.publicId, duplicate, duplicate: true);
  }
  if (context.match.hostPlayerId != context.participant.playerId) {
    throw _error(
      'host_required',
      'Only the match host can remove a participant.',
    );
  }
  final targetPlayerId = _string(
    input.command['playerId'],
    r'$.command.playerId',
  );
  if (targetPlayerId == context.participant.playerId) {
    throw _error('invalid_kick_target', 'The host cannot remove itself.');
  }
  final target = await _participantForPlayer(
    session,
    context.match.id!,
    targetPlayerId,
    transaction: transaction,
    lock: true,
  );
  if (target == null || !_isActiveParticipant(target)) {
    throw _error('participant_not_active', 'The participant is not active.');
  }
  final applied = _executeSystemCommand(service, context, input.command);
  final outcome = await _persistAppliedTurn(
    session,
    transaction,
    context,
    input,
    applied,
  );
  if (applied.rejection == null) {
    await GameParticipant.db.updateRow(
      session,
      target.copyWith(
        readyAt: null,
        kickedAt: applied.now,
        kickReason: _hostKickReason,
      ),
      transaction: transaction,
    );
  }
  return outcome;
}

_AppliedTurn _executeSystemCommand(
  GameMatchService service,
  _CommandContext context,
  Map<String, Object?> command,
) {
  final state = _persistedState(context.match);
  final content = _translateNative(
    () => service._native.prepareContent(
      mapDocument: context.match.mapDocument!,
      rulesetId: context.match.rulesetId,
      expectedMapHash: context.match.mapHash,
      expectedRulesetHash: context.match.rulesetHash,
    ),
  );
  final result = _translateNative(
    () => service._native.applySystemCommand(
      content: content,
      command: command,
      initialEventOffset: context.match.eventOffset,
      canonicalState: state,
    ),
  );
  return _parseAppliedTurn(result, context);
}
