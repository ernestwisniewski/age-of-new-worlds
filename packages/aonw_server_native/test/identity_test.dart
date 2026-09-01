import 'dart:convert';

import 'package:aonw_server_native/aonw_server_native.dart';
import 'package:test/test.dart';

void main() {
  test('packaged native artifact identity fails closed and is exact', () {
    final identity = AonwServerNativeIdentity.read();
    expect(identity.status, AonwServerNativeIdentityStatus.exactMatch);
    expect(identity.apiVersion, aonwServerHostApiVersion);
    expect(identity.buildIdentity, aonwExpectedServerNativeBuildIdentity);
  });

  test('native host exposes player queries and trusted lifecycle commands', () {
    final host = AonwServerNativeHost();
    final world = host.prepareWorld(
      mapDocument: jsonEncode(_mapDocument()),
      rulesetId: 'aonw-standard',
    );
    addTearDown(world.close);
    final created = host.createMatchJson(
      world,
      jsonEncode({
        'apiVersion': aonwServerHostApiVersion,
        'mapHash': world.mapHash,
        'rulesetHash': world.rulesetHash,
        'scenarioDocument': jsonEncode(_scenarioDocument),
        'matchIdentity': _matchIdentity,
        'fogEnabled': true,
      }),
    );
    final state = _object(
      _object(created.requireSuccess('matchCreated')['result'])['state'],
    );

    final queried = host.queryPlayerJson(
      world,
      jsonEncode({
        'apiVersion': aonwServerHostApiVersion,
        'authenticatedActorPlayerId': 'player-1',
        'query': {
          'type': 'reachable',
          'expectedRevision': state['revision'],
          'unitId': 'unit-1',
        },
        'mapHash': world.mapHash,
        'rulesetHash': world.rulesetHash,
        'state': state,
      }),
    );
    final outcome = _object(
      queried.requireSuccess('playerQueryExecuted')['result'],
    );
    final result = _object(outcome['result']);

    expect(outcome['status'], 'success');
    expect(result['type'], 'reachable');
    expect(result['unitId'], 'unit-1');

    final applied = host.applySystemCommandJson(
      world,
      jsonEncode({
        'apiVersion': aonwServerHostApiVersion,
        'command': {
          'type': 'kickParticipant',
          'expectedRevision': state['revision'],
          'playerId': 'player-2',
          'reason': 'timeout',
          'timeoutStreak': 3,
        },
        'initialEventOffset': 0,
        'mapHash': world.mapHash,
        'rulesetHash': world.rulesetHash,
        'state': state,
      }),
    );
    final command = _object(applied.requireSuccess('commandApplied')['result']);
    final nextState = _object(command['state']);
    final lifecycle = _object(nextState['turnLifecycle']);

    expect(command['rejection'], isNull);
    expect(command['finalEventOffset'], 1);
    expect(lifecycle['kickedPlayerIds'], ['player-2']);
    expect((command['recipients'] as List<Object?>), hasLength(2));
  });
}

Map<String, Object?> _mapDocument() => {
  'schemaVersion': 1,
  'gridLayout': 'oddQFlatTop',
  'cols': 5,
  'rows': 5,
  'mapName': 'native-package-test',
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
};

const _scenarioDocument = <String, Object?>{
  'schemaVersion': 1,
  'scenarioId': 'native-package-scenario',
  'mapId': 'native-package-test',
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
};

const _matchIdentity = <String, Object?>{
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
};

Map<String, Object?> _object(Object? value) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('Expected a JSON object, got ${value.runtimeType}.');
}
