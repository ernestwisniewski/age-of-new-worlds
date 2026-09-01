part of 'game_match_service.dart';

const _publicNativeErrorCodes = {
  'invalid_request',
  'invalid_map_document',
  'invalid_scenario_document',
  'invalid_match_identity',
  'unsupported_game_mode',
  'match_start_failed',
  'unsupported_ruleset',
  'content_identity_mismatch',
  'invalid_authenticated_actor',
  'unknown_authenticated_actor',
  'empty_participants',
  'map_bounds_mismatch',
  'occupancy_policy_mismatch',
};

const _matchStateLobby = 'lobby';
const _matchStateRunning = 'running';
const _matchStateFinished = 'finished';
const _matchStateAbandoned = 'abandoned';

void _requireRunningMatch(GameMatch match) {
  if (match.state != _matchStateRunning) {
    throw _error(
      match.state == _matchStateLobby ? 'match_not_started' : 'match_finished',
      match.state == _matchStateLobby
          ? 'The match has not started.'
          : 'The match is no longer running.',
    );
  }
}

Future<GameMatch> _matchByPublicId(
  Session session,
  String publicId, {
  Transaction? transaction,
  bool lock = false,
}) async {
  final match = await GameMatch.db.findFirstRow(
    session,
    where: (table) => table.publicId.equals(publicId),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
    lockBehavior: lock ? LockBehavior.wait : null,
  );
  if (match == null) {
    throw _error('match_not_found', 'Match was not found.');
  }
  return match;
}

Future<GameParticipant> _participant(
  Session session,
  int matchId,
  String userIdentifier, {
  Transaction? transaction,
}) async {
  final participant = await _participantForUser(
    session,
    matchId,
    userIdentifier,
    transaction: transaction,
  );
  if (participant == null) {
    throw _error('not_participant', 'The account is not a match participant.');
  }
  if (!_isActiveParticipant(participant)) {
    throw _error('not_participant', 'The account is not a match participant.');
  }
  return participant;
}

bool _isActiveParticipant(GameParticipant participant) =>
    participant.leftAt == null &&
    participant.resignedAt == null &&
    participant.kickedAt == null;

Future<GameParticipant?> _participantForUser(
  Session session,
  int matchId,
  String userIdentifier, {
  Transaction? transaction,
  bool lock = false,
}) => GameParticipant.db.findFirstRow(
  session,
  where: (table) =>
      (table.matchId.equals(matchId)) &
      (table.userIdentifier.equals(userIdentifier)),
  transaction: transaction,
  lockMode: lock ? LockMode.forUpdate : null,
  lockBehavior: lock ? LockBehavior.wait : null,
);

Future<GameParticipant?> _participantForPlayer(
  Session session,
  int matchId,
  String playerId, {
  Transaction? transaction,
  bool lock = false,
}) => GameParticipant.db.findFirstRow(
  session,
  where: (table) =>
      (table.matchId.equals(matchId)) & (table.playerId.equals(playerId)),
  transaction: transaction,
  lockMode: lock ? LockMode.forUpdate : null,
  lockBehavior: lock ? LockBehavior.wait : null,
);

Future<GameRecipientSnapshot> _snapshot(
  Session session,
  int matchId,
  String playerId, {
  Transaction? transaction,
  bool lock = false,
}) async {
  final snapshot = await GameRecipientSnapshot.db.findFirstRow(
    session,
    where: (table) =>
        (table.matchId.equals(matchId)) & (table.playerId.equals(playerId)),
    transaction: transaction,
    lockMode: lock ? LockMode.forUpdate : null,
    lockBehavior: lock ? LockBehavior.wait : null,
  );
  if (snapshot == null) {
    throw _error('participant_not_found', 'Match participant was not found.');
  }
  return snapshot;
}

Future<void> _persistRecipientSnapshots(
  Session session,
  int matchId,
  int eventOffset,
  Map<String, Map<String, Object?>> recipients,
  DateTime now,
  Transaction transaction,
) async {
  final existing = await GameRecipientSnapshot.db.find(
    session,
    where: (table) => table.matchId.equals(matchId),
    transaction: transaction,
    lockMode: LockMode.forUpdate,
    lockBehavior: LockBehavior.wait,
  );
  final byPlayer = {for (final row in existing) row.playerId: row};
  if (byPlayer.length != recipients.length ||
      !byPlayer.keys.every(recipients.containsKey)) {
    throw StateError('Native recipients differ from persisted participants.');
  }
  await GameRecipientSnapshot.db.update(
    session,
    _updatedSnapshots(byPlayer, recipients, eventOffset, now),
    transaction: transaction,
  );
}

List<GameRecipientSnapshot> _updatedSnapshots(
  Map<String, GameRecipientSnapshot> existing,
  Map<String, Map<String, Object?>> recipients,
  int eventOffset,
  DateTime now,
) => [
  for (final entry in recipients.entries)
    existing[entry.key]!.copyWith(
      eventOffset: eventOffset,
      snapshotJson: jsonEncode(
        _object(entry.value['snapshot'], r'$.recipient.snapshot'),
      ),
      updatedAt: now,
    ),
];

Map<String, Map<String, Object?>> _recipientSnapshots(Object? value) =>
    _recipients(value, r'$.projection.recipients', requireSnapshots: true);

Map<String, Map<String, Object?>> _recipientOutcomes(Object? value) =>
    _recipients(value, r'$.result.recipients');

Map<String, Map<String, Object?>> _recipients(
  Object? value,
  String path, {
  bool requireSnapshots = false,
}) {
  final result = <String, Map<String, Object?>>{};
  for (final (index, raw) in _list(value, path).indexed) {
    final recipient = _object(raw, '$path[$index]');
    final playerId = _identifier(
      _string(
        recipient['recipientPlayerId'],
        '$path[$index].recipientPlayerId',
      ),
      'recipientPlayerId',
    );
    if (result.containsKey(playerId)) {
      throw StateError('Native host returned a duplicate recipient.');
    }
    result[playerId] = requireSnapshots
        ? _object(recipient['snapshot'], '$path[$index].snapshot')
        : recipient;
  }
  if (result.isEmpty && requireSnapshots) {
    throw StateError('Native host returned no recipients.');
  }
  return result;
}

GameCommandOutcome _ledgerOutcome(
  String matchId,
  GameCommandLedger ledger, {
  required bool duplicate,
}) => GameCommandOutcome(
  matchId: matchId,
  clientCommandId: ledger.clientCommandId,
  initialEventOffset: ledger.initialEventOffset,
  finalEventOffset: ledger.finalEventOffset,
  duplicate: duplicate,
  outcomeJson: ledger.recipientOutcomeJson,
);

GameMatchView _view(GameMatch match) => GameMatchView(
  matchId: match.publicId,
  mapId: match.mapId,
  mapHash: match.mapHash,
  rulesetId: match.rulesetId,
  rulesetHash: match.rulesetHash,
  state: match.state,
  hostPlayerId: match.hostPlayerId,
  startedAt: match.startedAt,
  revision: match.revision,
  eventOffset: match.eventOffset,
);

String _requireUser(Session session) {
  final authenticated = session.authenticated;
  if (authenticated == null) {
    throw _error('auth_required', 'Authentication is required.');
  }
  return authenticated.userIdentifier;
}

String _identifier(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.length > _maximumIdentifierLength) {
    throw _error(
      'invalid_$field',
      '$field must contain 1 to $_maximumIdentifierLength characters.',
    );
  }
  return normalized;
}

void _document(
  String value,
  String field, {
  int maximumBytes = _maximumContentDocumentBytes,
}) {
  final size = utf8.encode(value).length;
  if (size == 0 || size > maximumBytes) {
    throw _error(
      'invalid_$field',
      '$field must contain 1 to $maximumBytes UTF-8 bytes.',
    );
  }
}

T _translateNative<T>(T Function() operation) {
  try {
    return operation();
  } on AonwServerNativeException catch (error) {
    final message = _publicNativeErrorCodes.contains(error.code)
        ? error.message
        : null;
    throw _error(error.code, message);
  } on FormatException catch (error) {
    throw _error('invalid_request', error.message);
  }
}

GameException _error(String code, [String? message]) =>
    GameException(code: code, message: message);

Map<String, Object?> _object(Object? value, String path) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$path must be an object.');
}

List<Object?> _list(Object? value, String path) {
  if (value is List<Object?>) return value;
  throw FormatException('$path must be an array.');
}

String _string(Object? value, String path) {
  if (value is String) return value;
  throw FormatException('$path must be a string.');
}

int _nonNegativeInt(Object? value, String path) {
  if (value is int && value >= 0) return value;
  throw FormatException('$path must be a non-negative integer.');
}

_MatchFacts _matchFacts(Map<String, Object?> state) {
  final outcome = _object(state['outcome'], r'$.state.outcome');
  final condition = _string(outcome['condition'], r'$.state.outcome.condition');
  final winner = outcome['winnerPlayerId'];
  if (winner != null && winner is! String) {
    throw const FormatException(
      r'$.state.outcome.winnerPlayerId must be a string or null.',
    );
  }
  return _MatchFacts(
    turn: _nonNegativeInt(state['turn'], r'$.state.turn'),
    outcomeCondition: condition == 'ongoing' ? null : condition,
    winnerPlayerId: condition == 'ongoing' ? null : winner as String?,
  );
}

final class _MatchFacts {
  const _MatchFacts({
    required this.turn,
    required this.outcomeCondition,
    required this.winnerPlayerId,
  });

  final int turn;
  final String? outcomeCondition;
  final String? winnerPlayerId;

  bool get finished => outcomeCondition != null;
  String get state => finished ? _matchStateFinished : _matchStateRunning;
}
