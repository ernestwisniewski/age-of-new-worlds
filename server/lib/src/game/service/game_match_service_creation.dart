part of 'game_match_service.dart';

Future<GameMatchView> _createMatch(
  GameMatchService service,
  Session session,
  GameCreateMatchRequest request,
) async {
  final userIdentifier = _requireUser(session);
  final mapId = _identifier(request.mapId, 'mapId');
  final rulesetId = _identifier(request.rulesetId, 'rulesetId');
  final creatorPlayerId = _identifier(
    request.creatorPlayerId,
    'creatorPlayerId',
  );
  _validateCreateDocuments(request);
  final identity = decodeGameObjectDocument(
    request.matchIdentityJson,
    r'$.matchIdentityJson',
  );
  final content = _translateNative(
    () => service._native.prepareContent(
      mapDocument: request.mapDocument,
      rulesetId: rulesetId,
    ),
  );
  final created = _translateNative(
    () => service._native.createMatch(
      content: content,
      scenarioDocument: request.scenarioDocument,
      matchIdentity: identity,
      fogEnabled: request.fogEnabled,
    ),
  );
  final prepared = _preparedCreation(
    request: request,
    created: created,
    content: content,
    mapId: mapId,
    rulesetId: rulesetId,
    creatorPlayerId: creatorPlayerId,
    userIdentifier: userIdentifier,
  );
  return session.db.transaction(
    (transaction) => _persistCreatedMatch(session, transaction, prepared),
  );
}

void _validateCreateDocuments(GameCreateMatchRequest request) {
  _document(request.mapDocument, 'mapDocument');
  _document(request.scenarioDocument, 'scenarioDocument');
  _document(
    request.matchIdentityJson,
    'matchIdentityJson',
    maximumBytes: _maximumIdentityDocumentBytes,
  );
}

_PreparedCreation _preparedCreation({
  required GameCreateMatchRequest request,
  required Map<String, Object?> created,
  required PreparedGameContent content,
  required String mapId,
  required String rulesetId,
  required String creatorPlayerId,
  required String userIdentifier,
}) {
  final state = _object(created['state'], r'$.result.state');
  final projection = _object(created['projection'], r'$.result.projection');
  final stamp = _object(projection['stamp'], r'$.projection.stamp');
  final recipients = _recipientSnapshots(projection['recipients']);
  if (!recipients.containsKey(creatorPlayerId)) {
    throw _error(
      'creator_not_participant',
      'The creator player is not present in the validated match identity.',
    );
  }
  return _PreparedCreation(
    mapId: mapId,
    rulesetId: rulesetId,
    creatorPlayerId: creatorPlayerId,
    userIdentifier: userIdentifier,
    mapDocument: request.mapDocument,
    content: content,
    state: state,
    facts: _matchFacts(state),
    revision: _nonNegativeInt(stamp['revision'], r'$.stamp.revision'),
    recipients: recipients,
  );
}

Future<GameMatchView> _persistCreatedMatch(
  Session session,
  Transaction transaction,
  _PreparedCreation prepared,
) async {
  final now = DateTime.now().toUtc();
  final row = await GameMatch.db.insertRow(
    session,
    prepared.matchRow(now),
    transaction: transaction,
  );
  await GameParticipant.db.insertRow(
    session,
    GameParticipant(
      matchId: row.id!,
      userIdentifier: prepared.userIdentifier,
      playerId: prepared.creatorPlayerId,
      joinedAt: now,
      readyAt: null,
      leftAt: null,
      resignedAt: null,
      kickedAt: null,
      kickReason: null,
    ),
    transaction: transaction,
  );
  await GameRecipientSnapshot.db.insert(
    session,
    prepared.snapshotRows(row.id!, now),
    transaction: transaction,
  );
  return _view(row);
}

final class _PreparedCreation {
  const _PreparedCreation({
    required this.mapId,
    required this.rulesetId,
    required this.creatorPlayerId,
    required this.userIdentifier,
    required this.mapDocument,
    required this.content,
    required this.state,
    required this.facts,
    required this.revision,
    required this.recipients,
  });

  final String mapId;
  final String rulesetId;
  final String creatorPlayerId;
  final String userIdentifier;
  final String mapDocument;
  final PreparedGameContent content;
  final Map<String, Object?> state;
  final _MatchFacts facts;
  final int revision;
  final Map<String, Map<String, Object?>> recipients;

  GameMatch matchRow(DateTime now) => GameMatch(
    publicId: 'game-${const Uuid().v4()}',
    mapId: mapId,
    mapHash: content.mapHash,
    rulesetId: rulesetId,
    rulesetHash: content.rulesetHash,
    mapDocument: mapDocument,
    canonicalStateJson: jsonEncode(state),
    state: _matchStateLobby,
    hostPlayerId: creatorPlayerId,
    turn: facts.turn,
    startedAt: null,
    endedAt: null,
    outcomeCondition: facts.outcomeCondition,
    winnerPlayerId: facts.winnerPlayerId,
    revision: revision,
    eventOffset: 0,
    createdAt: now,
    updatedAt: now,
  );

  List<GameRecipientSnapshot> snapshotRows(int matchId, DateTime now) => [
    for (final entry in recipients.entries)
      GameRecipientSnapshot(
        matchId: matchId,
        playerId: entry.key,
        eventOffset: 0,
        snapshotJson: jsonEncode(entry.value),
        updatedAt: now,
      ),
  ];
}
