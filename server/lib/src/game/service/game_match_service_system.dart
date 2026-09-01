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
