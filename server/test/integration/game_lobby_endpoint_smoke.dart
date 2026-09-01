import 'dart:convert';

import 'package:aonw_server/src/game/game_endpoint.dart';
import 'package:aonw_server/src/game/native/game_native_runtime.dart';
import 'package:aonw_server/src/generated/protocol.dart' as game;
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Game lobby endpoint',
    (sessionBuilder, _) {
      test('rejects an AI-controlled creator seat', () async {
        addTearDown(shutdownAonwGameNativeHost);
        final owner = sessionBuilder
            .copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                'ai-owner-user',
                const {},
              ),
            )
            .build();
        await expectLater(
          GameEndpoint().createMatch(
            owner,
            game.GameCreateMatchRequest(
              mapId: 'postgres-ai-owner-map',
              mapDocument: _mapDocument(),
              scenarioDocument: _scenarioDocument(),
              rulesetId: 'aonw-standard',
              matchIdentityJson: _matchIdentityDocument(),
              fogEnabled: true,
              creatorPlayerId: 'player-1',
            ),
          ),
          throwsA(
            isA<game.GameException>().having(
              (error) => error.code,
              'code',
              'participant_not_claimable',
            ),
          ),
        );
      });
    },
    rollbackDatabase: RollbackDatabase.afterEach,
    testServerOutputMode: TestServerOutputMode.normal,
  );
}

String _mapDocument() => jsonEncode({
  'schemaVersion': 1,
  'gridLayout': 'oddQFlatTop',
  'cols': 5,
  'rows': 5,
  'mapName': 'postgres-ai-owner-map',
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
  'scenarioId': 'postgres-ai-owner-scenario',
  'mapId': 'postgres-ai-owner-map',
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
      'name': 'Computer host',
      'colorValue': 0xff0000ff,
      'country': 'poland',
      'kind': 'ai',
      'ai': {
        'strategyId': 'mcts',
        'difficulty': 'normal',
        'persona': 'balanced',
        'seed': 7,
      },
    },
    {
      'id': 'player-2',
      'name': 'Human guest',
      'colorValue': 0x00ff00ff,
      'country': 'germany',
      'kind': 'human',
      'ai': null,
    },
  ],
  'gameMode': 'multiplayer',
});
