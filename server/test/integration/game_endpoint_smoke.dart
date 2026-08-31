import 'dart:convert';

import 'package:aonw_server/src/game/game_endpoint.dart';
import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/generated/protocol.dart' as game;
import 'package:aonw_server/src/stats/public_game_stats_service.dart';
import 'package:aonw_server/src/stats/public_game_stats_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Game endpoint',
    (sessionBuilder, _) {
      test('persists commands once and resyncs privately', () async {
        addTearDown(shutdownAonwGameNativeHost);
        await _GameEndpointJourney(sessionBuilder).run();
      });
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

final class _GameEndpointJourney {
  _GameEndpointJourney(TestSessionBuilder sessionBuilder)
    : ownerSession = _authenticated(sessionBuilder, 'owner-user').build(),
      guestSession = _authenticated(sessionBuilder, 'guest-user').build(),
      databaseSession = sessionBuilder.build();

  final Session ownerSession;
  final Session guestSession;
  final Session databaseSession;

  Future<void> run() async {
    final joined = await _createAndJoin();
    final ownerTurn = await _submitOwner(joined);
    final guestTurn = await _restartAndSubmitGuest(joined, ownerTurn);
    final persisted = await _verifyPersistedState(joined, guestTurn);
    await _verifyRollback(joined, persisted, guestTurn);
  }

  Future<_JoinedMatch> _createAndJoin() async {
    final endpoint = GameEndpoint();
    final created = await endpoint.createMatch(
      ownerSession,
      game.GameCreateMatchRequest(
        mapId: 'postgres-game-map',
        mapDocument: _mapDocument(),
        scenarioDocument: _scenarioDocument(),
        rulesetId: 'aonw-standard',
        matchIdentityJson: _matchIdentityDocument(),
        fogEnabled: true,
        creatorPlayerId: 'player-1',
      ),
    );
    final ownerInitial = await endpoint.resync(ownerSession, created.matchId);
    final guestInitial = await endpoint.joinMatch(
      guestSession,
      game.GameJoinMatchRequest(matchId: created.matchId, playerId: 'player-2'),
    );
    expect(ownerInitial.playerId, 'player-1');
    expect(guestInitial.playerId, 'player-2');
    _expectPrivateSnapshot(ownerInitial.snapshotJson, 'player-1');
    _expectPrivateSnapshot(guestInitial.snapshotJson, 'player-2');
    return _JoinedMatch(endpoint: endpoint, created: created);
  }

  Future<_OwnerTurn> _submitOwner(_JoinedMatch joined) async {
    final request = game.GameSubmitTurnRequest(
      matchId: joined.created.matchId,
      clientCommandId: 'owner-submit-1',
      expectedRevision: joined.created.revision,
    );
    final accepted = await joined.endpoint.submitTurn(ownerSession, request);
    final retry = await joined.endpoint.submitTurn(ownerSession, request);
    expect(accepted.duplicate, isFalse);
    expect(retry.duplicate, isTrue);
    expect(retry.outcomeJson, accepted.outcomeJson);
    expect(retry.initialEventOffset, accepted.initialEventOffset);
    expect(retry.finalEventOffset, accepted.finalEventOffset);
    final outcome = _object(jsonDecode(accepted.outcomeJson));
    expect(outcome.keys, unorderedEquals(['stamp', 'rejection', 'recipient']));
    final recipient = _object(outcome['recipient']);
    expect(recipient['recipientPlayerId'], 'player-1');
    expect(
      accepted.finalEventOffset - accepted.initialEventOffset,
      greaterThanOrEqualTo(_list(recipient['events']).length),
    );
    final ledgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.clientCommandId.equals('owner-submit-1'),
    );
    expect(ledgers, hasLength(1));
    return _OwnerTurn(
      accepted: accepted,
      nextRevision: _nonNegativeInt(_object(outcome['stamp'])['revision']),
    );
  }

  Future<game.GameCommandOutcome> _restartAndSubmitGuest(
    _JoinedMatch joined,
    _OwnerTurn ownerTurn,
  ) async {
    await shutdownAonwGameNativeHost();
    initializeAonwGameNativeHost();
    final endpoint = GameEndpoint();
    final accepted = await endpoint.submitTurn(
      guestSession,
      game.GameSubmitTurnRequest(
        matchId: joined.created.matchId,
        clientCommandId: 'guest-submit-1',
        expectedRevision: ownerTurn.nextRevision,
      ),
    );
    expect(accepted.duplicate, isFalse);
    final outcome = _object(jsonDecode(accepted.outcomeJson));
    expect(_object(outcome['recipient'])['recipientPlayerId'], 'player-2');
    final resync = await endpoint.resync(guestSession, joined.created.matchId);
    expect(resync.eventOffset, accepted.finalEventOffset);
    expect(resync.playerId, 'player-2');
    _expectPrivateSnapshot(resync.snapshotJson, 'player-2');
    return accepted;
  }

  Future<_PersistedMatch> _verifyPersistedState(
    _JoinedMatch joined,
    game.GameCommandOutcome guestTurn,
  ) async {
    final match = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(match, isNotNull);
    final persisted = match!;
    expect(persisted.eventOffset, guestTurn.finalEventOffset);
    expect(persisted.state, 'running');
    expect(persisted.turn, greaterThanOrEqualTo(0));
    expect(persisted.endedAt, isNull);
    expect(persisted.outcomeCondition, isNull);
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(persisted.id!),
    );
    expect(snapshots, hasLength(2));
    expect(snapshots.map((snapshot) => snapshot.eventOffset).toSet(), {
      guestTurn.finalEventOffset,
    });
    await _expectEvents(persisted.id!, guestTurn.finalEventOffset);
    await _expectPublicStats();
    return _PersistedMatch(
      row: persisted,
      snapshots: {
        for (final snapshot in snapshots)
          snapshot.playerId: snapshot.snapshotJson,
      },
    );
  }

  Future<void> _expectEvents(int matchId, int finalOffset) async {
    final events = await game.GameEvent.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(matchId),
      orderBy: (table) => table.offset,
    );
    expect(
      events.map((event) => event.offset),
      List<int>.generate(finalOffset, (index) => index + 1),
    );
  }

  Future<void> _expectPublicStats() async {
    final stats = await PublicGameStatsService(
      cacheTtl: Duration.zero,
    ).snapshot(ServerpodPublicGameStatsStore(databaseSession));
    expect(stats.totals.activeSessions, greaterThanOrEqualTo(1));
    expect(stats.totals.matchesStarted, greaterThanOrEqualTo(1));
  }

  Future<void> _verifyRollback(
    _JoinedMatch joined,
    _PersistedMatch persisted,
    game.GameCommandOutcome guestTurn,
  ) async {
    await game.GameMatch.db.updateRow(
      databaseSession,
      persisted.row.copyWith(canonicalStateJson: '{}'),
    );
    await expectLater(
      GameEndpoint().submitTurn(
        ownerSession,
        game.GameSubmitTurnRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'must-roll-back',
          expectedRevision: persisted.row.revision,
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'invalid_canonical_state',
        ),
      ),
    );
    final ledgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.clientCommandId.equals('must-roll-back'),
    );
    expect(ledgers, isEmpty);
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(persisted.row.id!),
    );
    expect({
      for (final snapshot in snapshots)
        snapshot.playerId: snapshot.snapshotJson,
    }, persisted.snapshots);
    expect(guestTurn.finalEventOffset, persisted.row.eventOffset);
  }
}

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
