import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

part 'protocol_response_fixture.dart';

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
        'participants': [
          {
            'id': 'player-1',
            'name': 'Player One',
            'colorValue': 0xff000000,
            'country': 'poland',
            'kind': 'human',
          },
        ],
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

  test('recipient snapshot exposes only the public participant roster', () {
    final snapshot = AonwPlayerViewSnapshot.fromJson(_snapshot);
    final participant = snapshot.participants.single;

    expect(participant.id, 'player-1');
    expect(participant.name, 'Player One');
    expect(participant.colorValue, 0xff000000);
    expect(participant.country, AonwPlayerCountry.poland);
    expect(participant.kind, AonwPlayerKind.human);
    expect(snapshot.fog.enabled, isTrue);
    expect(snapshot.fog.discoveredHexes, hasLength(2));
    expect(snapshot.fog.visibleHexes.single.col, 2);
    expect(snapshot.fog.visibleHexes.single.row, 1);
    expect(snapshot.economy.gold, 73);
    expect(snapshot.economy.warWeariness, 5);
    expect(snapshot.economy.stabilityNet, -4);
    expect(
      snapshot.economy.strategicResourceStockpile.single.resource,
      AonwResourceType.oil,
    );
    expect(snapshot.economy.strategicResourceStockpile.single.amount, 2);
    expect(snapshot.economy.strategicResourceOutput.single.amount, 1);
    expect(snapshot.economy.strategicResourceSources.single.cityId, 'city-a');
    expect(snapshot.economy.forecast.treasury, 73);
    expect(snapshot.economy.forecast.cityIncome, 7);
    expect(snapshot.economy.forecast.projectIncome, 2);
    expect(snapshot.economy.forecast.grossIncome, 9);
    expect(snapshot.economy.forecast.netPerTurn, 5);
    expect(snapshot.economy.forecast.citySources.single.cityId, 'city-a');
    expect(snapshot.economy.forecast.projectSources.single.amount, 2);
    expect(snapshot.economy.forecast.upkeep.total, 4);
    expect(snapshot.economy.forecast.upkeep.nextWorkerUpkeep, 2);
    expect(
      snapshot.economy.forecast.upkeep.sources.single.kind,
      AonwUnitKind.worker,
    );
    expect(snapshot.economy.forecast.stability.sourceTotal, 11);
    expect(snapshot.economy.forecast.stability.costTotal, 9);
    expect(snapshot.economy.forecast.stability.effectiveNet, 1);
    expect(snapshot.economy.forecast.stability.band, AonwStabilityBand.stable);
    expect(snapshot.research.activeTechnology, AonwTechnologyId.agriculture);
    expect(snapshot.research.activeProgress, 4);
    expect(snapshot.research.activeEffectiveCost, 20);
    expect(snapshot.research.scienceOverflow, 1);
    expect(snapshot.research.scienceYield.total, 0);
    expect(snapshot.victory.dominationRequiredControlPercent, 60);
    expect(snapshot.victory.remainingTurns, 19);
    expect(snapshot.victory.scoreByPlayerId, {'player-1': 37});
    expect(snapshot.victory.domination.single.controlledPassableHexes, 3);
    expect(snapshot.victory.ownCultural.uniqueStoredArtifacts, 2);

    final leakedParticipant = <String, Object?>{
      ...(_snapshot['participants']! as List).single as Map<String, Object?>,
      'ai': const {'difficulty': 'hard'},
    };
    expect(
      () => AonwPlayerViewSnapshot.fromJson({
        ..._snapshot,
        'participants': [leakedParticipant],
      }),
      throwsFormatException,
    );

    expect(
      () => AonwPlayerViewSnapshot.fromJson({
        ..._snapshot,
        'economy': {
          ..._snapshot['economy']! as Map<String, Object?>,
          'forecast': {
            ...(_snapshot['economy']! as Map<String, Object?>)['forecast']!
                as Map<String, Object?>,
            'clientCalculatedNet': 5,
          },
        },
      }),
      throwsFormatException,
    );

    expect(
      () => AonwPlayerViewSnapshot.fromJson({
        ..._snapshot,
        'victory': {..._victory, 'privateForeignCulturalProgress': 4},
      }),
      throwsFormatException,
    );
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
