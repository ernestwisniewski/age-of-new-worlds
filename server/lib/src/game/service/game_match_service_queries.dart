part of 'game_match_service.dart';

Future<GamePlayerQueryOutcome> _query(
  GameMatchService service,
  Session session,
  GamePlayerQueryRequest request,
) {
  _document(
    request.queryJson,
    'queryJson',
    maximumBytes: _maximumQueryDocumentBytes,
  );
  final query = _translateNative(
    () => decodeGameObjectDocument(request.queryJson, r'$.queryJson'),
  );
  final userIdentifier = _requireUser(session);
  final matchId = _identifier(request.matchId, 'matchId');
  return session.db.transaction((transaction) async {
    final match = await _matchByPublicId(
      session,
      matchId,
      transaction: transaction,
      lock: true,
    );
    final participant = await _participant(
      session,
      match.id!,
      userIdentifier,
      transaction: transaction,
    );
    final state = _persistedState(match);
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
        authenticatedActorPlayerId: participant.playerId,
        query: query,
        canonicalState: state,
      ),
    );
    _validateQueryOutcome(outcome);
    return GamePlayerQueryOutcome(
      matchId: match.publicId,
      outcomeJson: jsonEncode(outcome),
    );
  });
}

void _validateQueryOutcome(Map<String, Object?> outcome) {
  switch (outcome['status']) {
    case 'success':
      _object(outcome['result'], r'$.queryOutcome.result');
    case 'failure':
      _object(outcome['error'], r'$.queryOutcome.error');
    default:
      throw StateError('Native host returned an unknown query outcome.');
  }
}
