import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('capability parser covers the complete current engine feature set', () {
    const featureWires = [
      'artifacts',
      'cities',
      'combat',
      'inspectMap',
      'matchStart',
      'actorHandoff',
      'aiTurns',
      'snapshot',
      'reachable',
      'routePlan',
      'moveUnit',
      'unitActions',
      'turnKernel',
      'saveGame',
      'replayVerification',
      'replayPlayback',
      'movementLogistics',
      'workers',
      'production',
      'research',
      'diplomacy',
    ];
    final capabilities = AonwClientResponse.parse(
      _success({'type': 'capabilities', 'features': featureWires}),
    ).require<AonwCapabilitiesResponse>();

    expect(capabilities.features, AonwClientFeature.values);
  });

  test('typed response parser rejects unknown nested fields', () {
    final source = _success({
      'type': 'snapshot',
      'snapshot': {
        'stamp': _stamp,
        'turn': 7,
        'turnMode': 'sequential',
        'turnLifecycle': {
          'ownState': 'active',
          'ownSubmitted': false,
          'requiredSubmissionCount': 1,
          'submittedCount': 0,
        },
        'pendingAction': null,
        'cityFoundingDraft': null,
        'units': [
          {
            'id': 'unit-1',
            'ownerPlayerId': 'player-1',
            'kind': 'worker',
            'name': 'Worker',
            'coordinate': {'col': 1, 'row': 2},
            'movementUnits': 4,
            'posture': 'active',
            'hitPoints': null,
            'carriedArtifactId': null,
            'ownedDetails': null,
            'unknown': true,
          },
        ],
        'cities': <Object?>[],
        'fieldImprovements': <Object?>[],
        'roads': <Object?>[],
      },
    });

    expect(() => AonwClientResponse.parse(source), throwsFormatException);
  });

  test('map response rejects unknown nested fields and terrain values', () {
    final fixture =
        jsonDecode(
              File(
                _fixturePath('map_inspected_response.json'),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outcome = fixture['outcome'] as Map<String, dynamic>;
    final response = outcome['response'] as Map<String, dynamic>;
    final map = response['map'] as Map<String, dynamic>;
    final tile = (map['tiles'] as List).single as Map<String, dynamic>;
    tile['unknown'] = true;
    expect(
      () => AonwClientResponse.parse(jsonEncode(fixture)),
      throwsFormatException,
    );

    tile.remove('unknown');
    tile['displayTerrain'] = 'volcano';
    expect(
      () => AonwClientResponse.parse(jsonEncode(fixture)),
      throwsFormatException,
    );
  });

  test('typed parser covers lifecycle and persistence responses', () {
    final cases = <String, Type>{
      _success({
        'type': 'capabilities',
        'features': ['snapshot', 'moveUnit'],
      }): AonwCapabilitiesResponse,
      _success({'type': 'sessionOpened', 'stamp': _stamp}):
          AonwSessionOpenedResponse,
      _success({'type': 'actorHandedOff', 'stamp': _stamp}):
          AonwActorHandedOffResponse,
      _success({
        'type': 'aiTurnAdvanced',
        'stamp': _stamp,
        'actorPlayerId': 'player-ai',
        'executedCommands': 4,
        'completedTurn': true,
      }): AonwAiTurnAdvancedResponse,
      _success({'type': 'sessionClosed'}): AonwSessionClosedResponse,
      _success({'type': 'saveExported', 'document': '{}'}):
          AonwSaveExportedResponse,
      _success({
        'type': 'saveOpened',
        'stamp': _stamp,
        'actorPlayerId': 'player-1',
        'participants': [
          {'id': 'player-1', 'name': 'Player', 'kind': 'human'},
          {'id': 'player-2', 'name': 'Computer', 'kind': 'ai'},
        ],
      }): AonwSaveOpenedResponse,
      _success({'type': 'replayExported', 'document': '{}'}):
          AonwReplayExportedResponse,
      _success({
        'type': 'replayVerified',
        'verification': {
          'entryCount': 3,
          'finalEventOffset': 8,
          'finalStamp': _stamp,
        },
      }): AonwReplayVerifiedResponse,
      _success({
        'type': 'replayFrame',
        'position': 2,
        'entryCount': 3,
        'snapshot': _snapshot,
      }): AonwReplayFrameResponse,
    };

    for (final MapEntry(key: source, value: expectedType) in cases.entries) {
      expect(
        AonwClientResponse.parse(source).response.runtimeType,
        expectedType,
      );
    }
  });

  test('save restore exposes only ordered local participant control', () {
    final response = AonwClientResponse.parse(
      _success({
        'type': 'saveOpened',
        'stamp': _stamp,
        'actorPlayerId': 'player-2',
        'participants': [
          {'id': 'player-1', 'name': 'Ada', 'kind': 'human'},
          {'id': 'player-2', 'name': 'Grace', 'kind': 'human'},
          {'id': 'player-3', 'name': 'Computer', 'kind': 'ai'},
        ],
      }),
    ).require<AonwSaveOpenedResponse>();

    expect(response.actorPlayerId, 'player-2');
    expect(response.participants.map((participant) => participant.id), [
      'player-1',
      'player-2',
      'player-3',
    ]);
    expect(response.participants[1].name, 'Grace');
    expect(response.participants[1].kind, AonwPlayerKind.human);
    expect(response.participants[2].kind, AonwPlayerKind.ai);
  });

  test('typed parser covers both movement query results', () {
    final reachable = AonwClientResponse.parse(
      _success({
        'type': 'query',
        'result': {
          'type': 'reachable',
          'stamp': _stamp,
          'unitId': 'unit-1',
          'availableMovementUnits': 4,
          'tiles': [
            {
              'coordinate': {'col': 2, 'row': 2},
              'costUnits': 2,
              'exhaustsMovement': false,
            },
          ],
        },
      }),
    ).require<AonwQueryResponse>();
    expect(reachable.result, isA<AonwReachableResult>());

    final route = AonwClientResponse.parse(
      _success({
        'type': 'query',
        'result': {
          'type': 'routePlan',
          'stamp': _stamp,
          'unitId': 'unit-1',
          'target': {'col': 3, 'row': 2},
          'destination': {'col': 3, 'row': 2},
          'totalCostUnits': 4,
          'availableMovementUnits': 4,
          'remainingMovementUnits': 0,
          'steps': [
            {
              'coordinate': {'col': 3, 'row': 2},
              'enterCostUnits': 4,
              'cumulativeCostUnits': 4,
            },
          ],
        },
      }),
    ).require<AonwQueryResponse>();
    expect(route.result, isA<AonwRoutePlanResult>());
  });

  test('pending actions are a strict closed recipient view', () {
    final actions = <Map<String, Object?>>[
      const {'type': 'researchSelection'},
      const {'type': 'cityWorkedHexSelection', 'cityId': 'city-1'},
      const {'type': 'cityExpansionSelection', 'cityId': 'city-1'},
      const {
        'type': 'workerActionSelection',
        'unitId': 'worker-1',
        'improvement': 'farm',
      },
      const {'type': 'merchantTradeRouteSelection', 'unitId': 'merchant-1'},
      const {'type': 'merchantMoveToCitySelection', 'unitId': 'merchant-1'},
      const {
        'type': 'unitTurnSkip',
        'unitId': 'unit-1',
        'restoreMovementUnits': 4,
      },
      const {
        'type': 'attackTargeting',
        'unitId': 'unit-1',
        'defender': {'col': 2, 'row': 3},
      },
      const {'type': 'commanderMergeSelection', 'unitId': 'commander-1'},
    ];

    expect(actions.map(AonwPendingActionView.fromJson), [
      isA<AonwPendingResearchSelection>(),
      isA<AonwPendingCityWorkedHexSelection>(),
      isA<AonwPendingCityExpansionSelection>(),
      isA<AonwPendingWorkerActionSelection>(),
      isA<AonwPendingMerchantTradeRouteSelection>(),
      isA<AonwPendingMerchantMoveToCitySelection>(),
      isA<AonwPendingUnitTurnSkip>(),
      isA<AonwPendingAttackTargeting>(),
      isA<AonwPendingCommanderMergeSelection>(),
    ]);
    expect(
      () => AonwPendingActionView.fromJson(const {'type': 'futureAction'}),
      throwsFormatException,
    );
  });

  test('command result uses one tagged accepted or rejected outcome', () {
    final accepted = AonwCommandResult.fromJson(
      _commandResult(const {'status': 'accepted'}),
    );
    final rejected = AonwCommandResult.fromJson(
      _commandResult(const {'status': 'rejected', 'code': 'stale_revision'}),
    );

    expect(accepted.accepted, isTrue);
    expect(accepted.rejection, isNull);
    expect(rejected.accepted, isFalse);
    expect(rejected.rejection, AonwCommandRejectionCode.staleRevision);
    expect(
      () => AonwCommandResult.fromJson({
        ..._commandResult(const {'status': 'accepted'}),
        'accepted': true,
      }),
      throwsFormatException,
    );
    expect(
      () => AonwCommandResult.fromJson(
        _commandResult(const {
          'status': 'rejected',
          'code': 'future_rejection',
        }),
      ),
      throwsFormatException,
    );
  });

  test('command rejection codes match the shared fixture', () {
    final fixture =
        jsonDecode(
              File(
                _fixturePath('command_rejection_codes.json'),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(
      AonwCommandRejectionCode.values.map((value) => value.wireCode),
      fixture['codes'],
    );
  });

  test('failure response is typed and cannot be required as success', () {
    final response = AonwClientResponse.parse(
      jsonEncode({
        'apiVersion': aonwClientApiVersion,
        'outcome': {
          'status': 'failure',
          'error': {'code': 'invalid_request', 'message': 'invalid'},
        },
      }),
    );

    expect(response.error?.code, 'invalid_request');
    expect(response.require<AonwSessionClosedResponse>, throwsStateError);
  });
}

String _fixturePath(String name) {
  for (final root in [
    'test/fixtures/client_protocol',
    '../../tests/fixtures/client_protocol',
  ]) {
    final path = '$root/$name';
    if (File(path).existsSync()) return path;
  }
  throw StateError('Shared client fixture not found: $name');
}

const _stamp = {
  'revision': 7,
  'stateDigest': 'digest-7',
  'mapHash': 'map-hash',
  'rulesetHash': 'ruleset-hash',
};

const _snapshot = {
  'stamp': _stamp,
  'turn': 1,
  'turnMode': 'sequential',
  'outcome': {
    'condition': 'ongoing',
    'winnerPlayerId': null,
    'scoreByPlayerId': <String, int>{},
  },
  'turnLifecycle': {
    'ownState': 'active',
    'ownSubmitted': false,
    'requiredSubmissionCount': 1,
    'submittedCount': 0,
  },
  'pendingAction': null,
  'cityFoundingDraft': null,
  'diplomacy': {
    'relations': <Object?>[],
    'proposals': <Object?>[],
    'messages': <Object?>[],
    'resourceTradeAgreements': <Object?>[],
  },
  'units': <Object?>[],
  'cities': <Object?>[],
  'artifacts': <Object?>[],
  'fieldImprovements': <Object?>[],
  'roads': <Object?>[],
};

String _success(Map<String, Object?> response) => jsonEncode({
  'apiVersion': aonwClientApiVersion,
  'outcome': {'status': 'success', 'response': response},
});

Map<String, Object?> _commandResult(Map<String, Object?> outcome) => {
  'stamp': _stamp,
  'outcome': outcome,
  'events': const [],
  'evidence': null,
  'viewPatch': const {
    'fromRevision': 7,
    'toRevision': 7,
    'turn': 7,
    'turnMode': 'sequential',
    'turnLifecycle': null,
    'outcome': null,
    'upsertedUnits': <Object?>[],
    'removedUnitIds': <Object?>[],
    'upsertedCities': <Object?>[],
    'removedCityIds': <Object?>[],
    'upsertedArtifacts': <Object?>[],
    'removedArtifactIds': <Object?>[],
    'upsertedFieldImprovements': <Object?>[],
    'removedFieldImprovementCoordinates': <Object?>[],
    'upsertedRoads': <Object?>[],
    'removedRoadCoordinates': <Object?>[],
    'pendingAction': null,
    'cityFoundingDraft': null,
    'diplomacy': null,
  },
};
