import 'dart:convert';

import 'package:aonw_server/src/game/game_endpoint.dart';
import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/generated/protocol.dart' as game;
import 'package:aonw_server/src/stats/public_game_stats_service.dart';
import 'package:aonw_server/src/stats/public_game_stats_store.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

part 'game_endpoint_persistence.dart';

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
    await _rejectInvalidCommand(joined);
    final fortifiedRevision = await _fortifyOwner(joined);
    final ownerTurn = await _submitOwner(joined, fortifiedRevision);
    final guestTurn = await _restartAndSubmitGuest(joined, ownerTurn);
    final persisted = await _verifyPersistedState(joined, guestTurn);
    await _verifyRollback(joined, persisted, guestTurn);
  }

  Future<void> _rejectInvalidCommand(_JoinedMatch joined) async {
    await expectLater(
      joined.endpoint.applyCommand(
        ownerSession,
        game.GamePlayerCommandRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'owner-invalid-1',
          commandJson: jsonEncode({
            'type': 'fortifyUnit',
            'expectedRevision': joined.created.revision,
          }),
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'invalid_request',
        ),
      ),
    );
    final ledgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.clientCommandId.equals('owner-invalid-1'),
    );
    expect(ledgers, isEmpty);
    final resync = await joined.endpoint.resync(
      ownerSession,
      joined.created.matchId,
    );
    expect(resync.eventOffset, 0);
    expect(
      _list(
        _object(jsonDecode(resync.snapshotJson))['units'],
      ).map(_object).singleWhere((unit) => unit['id'] == 'unit-1')['posture'],
      'active',
    );
  }

  Future<int> _fortifyOwner(_JoinedMatch joined) async {
    final request = game.GamePlayerCommandRequest(
      matchId: joined.created.matchId,
      clientCommandId: 'owner-fortify-1',
      commandJson: jsonEncode({
        'type': 'fortifyUnit',
        'expectedRevision': joined.created.revision,
        'unitId': 'unit-1',
      }),
    );
    final accepted = await joined.endpoint.applyCommand(ownerSession, request);
    final retry = await joined.endpoint.applyCommand(ownerSession, request);
    expect(accepted.duplicate, isFalse);
    expect(retry.duplicate, isTrue);
    expect(retry.outcomeJson, accepted.outcomeJson);
    final outcome = _object(jsonDecode(accepted.outcomeJson));
    final recipient = _object(outcome['recipient']);
    final snapshot = _object(recipient['snapshot']);
    final unit = _list(
      snapshot['units'],
    ).map(_object).singleWhere((unit) => unit['id'] == 'unit-1');
    expect(unit['posture'], 'fortified');
    final ledger = await game.GameCommandLedger.db.findFirstRow(
      databaseSession,
      where: (table) => table.clientCommandId.equals('owner-fortify-1'),
    );
    expect(ledger, isNotNull);
    expect(_object(jsonDecode(ledger!.requestJson!))['type'], 'fortifyUnit');
    return _nonNegativeInt(_object(outcome['stamp'])['revision']);
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
    expect(created.state, 'lobby');
    expect(created.hostPlayerId, 'player-1');
    expect(created.startedAt, isNull);
    final ownerInitial = await endpoint.resync(ownerSession, created.matchId);
    final guestInitial = await endpoint.joinMatch(
      guestSession,
      game.GameJoinMatchRequest(matchId: created.matchId, playerId: 'player-2'),
    );
    expect(ownerInitial.playerId, 'player-1');
    expect(guestInitial.playerId, 'player-2');
    _expectPrivateSnapshot(ownerInitial.snapshotJson, 'player-1');
    _expectPrivateSnapshot(guestInitial.snapshotJson, 'player-2');
    await _verifyLobbyLifecycle(endpoint, created);
    return _JoinedMatch(endpoint: endpoint, created: created);
  }

  Future<void> _verifyLobbyLifecycle(
    GameEndpoint endpoint,
    game.GameMatchView created,
  ) async {
    final lobbyStats = await PublicGameStatsService(
      cacheTtl: Duration.zero,
    ).snapshot(ServerpodPublicGameStatsStore(databaseSession));
    expect(lobbyStats.totals.openLobbies, 1);
    expect(lobbyStats.totals.matchesStarted, 0);
    await expectLater(
      endpoint.applyCommand(
        ownerSession,
        game.GamePlayerCommandRequest(
          matchId: created.matchId,
          clientCommandId: 'owner-before-start',
          commandJson: jsonEncode({
            'type': 'fortifyUnit',
            'expectedRevision': created.revision,
            'unitId': 'unit-1',
          }),
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'match_not_started',
        ),
      ),
    );
    await expectLater(
      endpoint.query(
        ownerSession,
        game.GamePlayerQueryRequest(
          matchId: created.matchId,
          queryJson: jsonEncode({
            'type': 'researchOptions',
            'expectedRevision': created.revision,
          }),
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'match_not_started',
        ),
      ),
    );

    final guestReady = await endpoint.setReady(
      guestSession,
      created.matchId,
      true,
    );
    expect(guestReady.canStart, isFalse);
    expect(
      guestReady.participants
          .singleWhere((participant) => participant.playerId == 'player-2')
          .isReady,
      isTrue,
    );
    await expectLater(
      endpoint.startMatch(ownerSession, created.matchId),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'lobby_not_ready',
        ),
      ),
    );
    await expectLater(
      endpoint.startMatch(guestSession, created.matchId),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'host_required',
        ),
      ),
    );

    final ownerReady = await endpoint.setReady(
      ownerSession,
      created.matchId,
      true,
    );
    expect(ownerReady.canStart, isTrue);
    expect(ownerReady.participants, hasLength(2));
    expect(
      ownerReady.participants
          .singleWhere((participant) => participant.isCurrentUser)
          .playerId,
      'player-1',
    );
    final started = await endpoint.startMatch(ownerSession, created.matchId);
    expect(started.match.state, 'running');
    expect(started.match.startedAt, isNotNull);
    expect(started.canStart, isFalse);

    final startedStats = await PublicGameStatsService(
      cacheTtl: Duration.zero,
    ).snapshot(ServerpodPublicGameStatsStore(databaseSession));
    expect(startedStats.totals.openLobbies, 0);
    expect(startedStats.totals.matchesStarted, 1);

    final preStartLedgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.clientCommandId.equals('owner-before-start'),
    );
    expect(preStartLedgers, isEmpty);
  }

  Future<_OwnerTurn> _submitOwner(
    _JoinedMatch joined,
    int expectedRevision,
  ) async {
    final request = game.GameSubmitTurnRequest(
      matchId: joined.created.matchId,
      clientCommandId: 'owner-submit-1',
      expectedRevision: expectedRevision,
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
