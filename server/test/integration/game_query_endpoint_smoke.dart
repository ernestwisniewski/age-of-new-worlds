import 'dart:convert';

import 'package:aonw_server/src/game/game_endpoint.dart';
import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/generated/protocol.dart' as game;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Game query endpoint',
    (sessionBuilder, _) {
      test('queries one recipient without mutating the match', () async {
        addTearDown(shutdownAonwGameNativeHost);
        final owner = _authenticated(sessionBuilder, 'query-owner').build();
        final guest = _authenticated(sessionBuilder, 'query-guest').build();
        final outsider = _authenticated(
          sessionBuilder,
          'query-outsider',
        ).build();
        final database = sessionBuilder.build();
        final endpoint = GameEndpoint();
        final created = await endpoint.createMatch(
          owner,
          game.GameCreateMatchRequest(
            mapId: 'postgres-query-map',
            mapDocument: _mapDocument(),
            scenarioDocument: _scenarioDocument(),
            rulesetId: 'aonw-standard',
            matchIdentityJson: _matchIdentityDocument(),
            fogEnabled: true,
            creatorPlayerId: 'player-1',
          ),
        );
        await endpoint.joinMatch(
          guest,
          game.GameJoinMatchRequest(
            matchId: created.matchId,
            playerId: 'player-2',
          ),
        );
        await endpoint.setReady(owner, created.matchId, true);
        await endpoint.setReady(guest, created.matchId, true);
        await endpoint.startMatch(owner, created.matchId);
        final before = await game.GameMatch.db.findFirstRow(
          database,
          where: (table) => table.publicId.equals(created.matchId),
        );
        expect(before, isNotNull);

        final reachable = await endpoint.query(
          owner,
          game.GamePlayerQueryRequest(
            matchId: created.matchId,
            queryJson: jsonEncode({
              'type': 'reachable',
              'expectedRevision': created.revision,
              'unitId': 'unit-1',
            }),
          ),
        );
        final reachableOutcome = _object(jsonDecode(reachable.outcomeJson));
        expect(reachableOutcome['status'], 'success');
        final result = _object(reachableOutcome['result']);
        expect(result['type'], 'reachable');
        expect(result['unitId'], 'unit-1');

        final invalid = await endpoint.query(
          owner,
          game.GamePlayerQueryRequest(
            matchId: created.matchId,
            queryJson: jsonEncode({
              'type': 'reachable',
              'expectedRevision': created.revision,
              'unitId': '   ',
            }),
          ),
        );
        final invalidOutcome = _object(jsonDecode(invalid.outcomeJson));
        expect(invalidOutcome['status'], 'failure');
        expect(_object(invalidOutcome['error'])['code'], 'invalid_unit_id');
        await expectLater(
          endpoint.query(
            outsider,
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
              'not_participant',
            ),
          ),
        );

        final after = await game.GameMatch.db.findById(database, before!.id!);
        expect(after?.revision, before.revision);
        expect(after?.eventOffset, before.eventOffset);
        expect(after?.canonicalStateJson, before.canonicalStateJson);
        expect(await game.GameCommandLedger.db.count(database), 0);
        expect(await game.GameEvent.db.count(database), 0);
      });
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
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

String _mapDocument() => jsonEncode({
  'schemaVersion': 1,
  'gridLayout': 'oddQFlatTop',
  'cols': 5,
  'rows': 5,
  'mapName': 'postgres-query-map',
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
  'scenarioId': 'postgres-query-scenario',
  'mapId': 'postgres-query-map',
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
