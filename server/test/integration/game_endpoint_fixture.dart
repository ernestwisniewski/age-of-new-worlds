part of 'game_endpoint_smoke.dart';

final class _JoinedMatch {
  const _JoinedMatch({required this.endpoint, required this.created});

  final GameEndpoint endpoint;
  final game.GameMatchView created;
}

final class _OwnerTurn {
  const _OwnerTurn({required this.accepted, required this.nextRevision});

  final game.GameCommandOutcome accepted;
  final int nextRevision;
}

final class _PersistedMatch {
  const _PersistedMatch({required this.row, required this.snapshots});

  final game.GameMatch row;
  final Map<String, String> snapshots;
}

final class _KickResult {
  const _KickResult({required this.persisted, required this.outcome});

  final _PersistedMatch persisted;
  final game.GameCommandOutcome outcome;
}

TestSessionBuilder _authenticated(
  TestSessionBuilder sessionBuilder,
  String userIdentifier,
) => sessionBuilder.copyWith(
  authentication: AuthenticationOverride.authenticationInfo(
    userIdentifier,
    const {},
  ),
);

void _expectPrivateSnapshot(String document, String recipientPlayerId) {
  final units = _list(_object(jsonDecode(document))['units']).map(_object);
  expect(units, isNotEmpty);
  for (final unit in units) {
    expect(unit['ownerPlayerId'], recipientPlayerId);
    expect(unit['ownedDetails'], isNotNull);
  }
}

String _mapDocument() => jsonEncode({
  'schemaVersion': 1,
  'gridLayout': 'oddQFlatTop',
  'cols': 5,
  'rows': 5,
  'mapName': 'postgres-game-map',
  'defaultZoom': 1.0,
  'objectives': <Object?>[],
  'tiles': [
    for (var col = 0; col < 5; col++)
      for (var row = 0; row < 5; row++)
        {
          'col': col,
          'row': row,
          'terrainTags': ['plains'],
          'resources': <Object?>[],
          'height': 0,
        },
  ],
});

String _scenarioDocument() => jsonEncode({
  'schemaVersion': 1,
  'scenarioId': 'postgres-game-scenario',
  'mapId': 'postgres-game-map',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'unit-1',
      'ownerPlayerId': 'player-1',
      'kind': 'commander',
      'name': 'One',
      'col': 0,
      'row': 0,
    },
    {
      'id': 'unit-2',
      'ownerPlayerId': 'player-2',
      'kind': 'commander',
      'name': 'Two',
      'col': 4,
      'row': 4,
    },
  ],
});

String _matchIdentityDocument() => jsonEncode({
  'matchRules': {
    'gameLength': {
      'kind': 'unlimited',
      'targetMinutes': null,
      'turnLimit': null,
      'paceProfile': 'unlimited',
      'scoreFallbackEnabled': false,
    },
    'victory': {
      'conquestEnabled': true,
      'dominationEnabled': true,
      'dominationControlPercent': 60,
      'dominationHoldTurns': 5,
      'scoreFallbackEnabled': false,
      'turnLimit': null,
      'hardTimeLimitMinutes': null,
      'culturalEnabled': true,
      'culturalRequiredArtifacts': 6,
      'culturalHoldTurns': 5,
    },
    'balance': <String, Object?>{},
  },
  'participants': [
    {
      'id': 'player-1',
      'name': 'One',
      'colorValue': 0xff0000ff,
      'country': 'poland',
      'kind': 'human',
      'ai': null,
    },
    {
      'id': 'player-2',
      'name': 'Two',
      'colorValue': 0x00ff00ff,
      'country': 'germany',
      'kind': 'human',
      'ai': null,
    },
  ],
  'gameMode': 'multiplayer',
});

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected an object, got ${value.runtimeType}.');
}

List<Object?> _list(Object? value) {
  if (value is List<Object?>) return value;
  throw FormatException('Expected an array, got ${value.runtimeType}.');
}

int _nonNegativeInt(Object? value) {
  if (value is int && value >= 0) return value;
  throw FormatException('Expected a non-negative integer, got $value.');
}
