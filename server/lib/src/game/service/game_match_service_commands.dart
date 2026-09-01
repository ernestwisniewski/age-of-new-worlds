part of 'game_match_service.dart';

Future<GameCommandOutcome> _submitTurn(
  GameMatchService service,
  Session session,
  GameSubmitTurnRequest request,
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
      'type': 'submitTurn',
      'expectedRevision': request.expectedRevision,
    },
  );
  return _applyInput(service, session, input);
}

Future<GameCommandOutcome> _applyCommand(
  GameMatchService service,
  Session session,
  GamePlayerCommandRequest request,
) {
  _document(
    request.commandJson,
    'commandJson',
    maximumBytes: _maximumCommandDocumentBytes,
  );
  final (command, expectedRevision) = _translateNative(() {
    final command = decodeGameObjectDocument(
      request.commandJson,
      r'$.commandJson',
    );
    return (
      command,
      _nonNegativeInt(
        command['expectedRevision'],
        r'$.commandJson.expectedRevision',
      ),
    );
  });
  final input = _CommandInput(
    userIdentifier: _requireUser(session),
    matchId: _identifier(request.matchId, 'matchId'),
    clientCommandId: _identifier(request.clientCommandId, 'clientCommandId'),
    expectedRevision: expectedRevision,
    command: command,
  );
  return _applyInput(service, session, input);
}

Future<GameCommandOutcome> _applyInput(
  GameMatchService service,
  Session session,
  _CommandInput input,
) {
  return session.db.transaction(
    (transaction) => _submitTransaction(service, session, transaction, input),
  );
}

Future<GameCommandOutcome> _submitTransaction(
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
  final applied = _executeCommand(service, context, input);
  return _persistAppliedTurn(session, transaction, context, input, applied);
}

Future<_CommandContext> _loadCommandContext(
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
  _requireRunningMatch(match);
  final participant = await _participant(
    session,
    match.id!,
    input.userIdentifier,
    transaction: transaction,
  );
  final duplicate = await GameCommandLedger.db.findFirstRow(
    session,
    where: (table) =>
        (table.matchId.equals(match.id!)) &
        (table.playerId.equals(participant.playerId)) &
        (table.clientCommandId.equals(input.clientCommandId)),
    transaction: transaction,
  );
  return _CommandContext(
    match: match,
    participant: participant,
    duplicate: duplicate,
  );
}

_AppliedTurn _executeCommand(
  GameMatchService service,
  _CommandContext context,
  _CommandInput input,
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
    () => service._native.applyPlayerCommand(
      content: content,
      authenticatedActorPlayerId: context.participant.playerId,
      command: input.command,
      initialEventOffset: context.match.eventOffset,
      canonicalState: state,
    ),
  );
  return _parseAppliedTurn(result, context);
}

Map<String, Object?> _persistedState(GameMatch match) {
  final mapDocument = match.mapDocument;
  final canonicalStateJson = match.canonicalStateJson;
  if (mapDocument == null || canonicalStateJson == null) {
    throw StateError('Game match server-only state is unavailable.');
  }
  return decodeGameObjectDocument(canonicalStateJson, r'$.canonicalState');
}

_AppliedTurn _parseAppliedTurn(
  Map<String, Object?> result,
  _CommandContext context,
) {
  final initialOffset = _nonNegativeInt(
    result['initialEventOffset'],
    r'$.result.initialEventOffset',
  );
  final finalOffset = _nonNegativeInt(
    result['finalEventOffset'],
    r'$.result.finalEventOffset',
  );
  final events = _list(result['events'], r'$.result.events');
  _validateEventRange(
    context.match.eventOffset,
    initialOffset,
    finalOffset,
    events,
  );
  final stamp = _object(result['stamp'], r'$.result.stamp');
  final nextState = _object(result['state'], r'$.result.state');
  final recipients = _recipientOutcomes(result['recipients']);
  final caller = recipients[context.participant.playerId];
  if (caller == null) {
    throw StateError('Native host omitted the authenticated recipient.');
  }
  return _AppliedTurn(
    initialOffset: initialOffset,
    finalOffset: finalOffset,
    events: events,
    stamp: stamp,
    revision: _nonNegativeInt(stamp['revision'], r'$.result.stamp.revision'),
    nextState: nextState,
    facts: _matchFacts(nextState),
    recipients: recipients,
    caller: caller,
    rejection: result['rejection'],
    now: DateTime.now().toUtc(),
  );
}

void _validateEventRange(
  int persistedOffset,
  int initialOffset,
  int finalOffset,
  List<Object?> events,
) {
  if (initialOffset != persistedOffset || finalOffset < initialOffset) {
    throw StateError('Native host returned an inconsistent event range.');
  }
  if (finalOffset - initialOffset != events.length) {
    throw StateError('Native host event count does not match its offsets.');
  }
}

Future<GameCommandOutcome> _persistAppliedTurn(
  Session session,
  Transaction transaction,
  _CommandContext context,
  _CommandInput input,
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
  final ledger = await _insertLedger(
    session,
    transaction,
    context,
    input,
    applied,
  );
  return _ledgerOutcome(context.match.publicId, ledger, duplicate: false);
}

Future<void> _updateMatch(
  Session session,
  Transaction transaction,
  GameMatch match,
  _AppliedTurn applied,
) => GameMatch.db.updateRow(
  session,
  match.copyWith(
    canonicalStateJson: jsonEncode(applied.nextState),
    state: applied.facts.state,
    turn: applied.facts.turn,
    endedAt: applied.facts.finished ? match.endedAt ?? applied.now : null,
    outcomeCondition: applied.facts.outcomeCondition,
    winnerPlayerId: applied.facts.winnerPlayerId,
    revision: applied.revision,
    eventOffset: applied.finalOffset,
    updatedAt: applied.now,
  ),
  transaction: transaction,
);

Future<void> _insertEvents(
  Session session,
  Transaction transaction,
  int matchId,
  _AppliedTurn applied,
) async {
  if (applied.events.isEmpty) return;
  await GameEvent.db.insert(
    session,
    applied.eventRows(matchId),
    transaction: transaction,
  );
}

Future<GameCommandLedger> _insertLedger(
  Session session,
  Transaction transaction,
  _CommandContext context,
  _CommandInput input,
  _AppliedTurn applied,
) => GameCommandLedger.db.insertRow(
  session,
  GameCommandLedger(
    matchId: context.match.id!,
    playerId: context.participant.playerId,
    clientCommandId: input.clientCommandId,
    expectedRevision: input.expectedRevision,
    initialEventOffset: applied.initialOffset,
    finalEventOffset: applied.finalOffset,
    requestJson: jsonEncode(input.command),
    recipientOutcomeJson: applied.safeOutcomeJson,
    createdAt: applied.now,
  ),
  transaction: transaction,
);

final class _CommandInput {
  const _CommandInput({
    required this.userIdentifier,
    required this.matchId,
    required this.clientCommandId,
    required this.expectedRevision,
    required this.command,
  });

  final String userIdentifier;
  final String matchId;
  final String clientCommandId;
  final int expectedRevision;
  final Map<String, Object?> command;
}

final class _CommandContext {
  const _CommandContext({
    required this.match,
    required this.participant,
    required this.duplicate,
  });

  final GameMatch match;
  final GameParticipant participant;
  final GameCommandLedger? duplicate;
}

final class _AppliedTurn {
  const _AppliedTurn({
    required this.initialOffset,
    required this.finalOffset,
    required this.events,
    required this.stamp,
    required this.revision,
    required this.nextState,
    required this.facts,
    required this.recipients,
    required this.caller,
    required this.rejection,
    required this.now,
  });

  final int initialOffset;
  final int finalOffset;
  final List<Object?> events;
  final Map<String, Object?> stamp;
  final int revision;
  final Map<String, Object?> nextState;
  final _MatchFacts facts;
  final Map<String, Map<String, Object?>> recipients;
  final Map<String, Object?> caller;
  final Object? rejection;
  final DateTime now;

  String get safeOutcomeJson =>
      jsonEncode({'stamp': stamp, 'rejection': rejection, 'recipient': caller});

  List<GameEvent> eventRows(int matchId) => [
    for (var index = 0; index < events.length; index++)
      GameEvent(
        matchId: matchId,
        offset: initialOffset + index + 1,
        eventJson: jsonEncode(events[index]),
        createdAt: now,
      ),
  ];
}
