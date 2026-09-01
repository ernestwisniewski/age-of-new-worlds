import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('end-turn request stays revision-bound', () {
    final request = AonwClientRequest.endTurn(expectedRevision: 7);
    expect(jsonDecode(request.toJson()), {
      'apiVersion': aonwClientApiVersion,
      'request': {
        'type': 'dispatch',
        'command': {'type': 'endTurn', 'expectedRevision': 7},
      },
    });
    expect(jsonDecode(request.toPlayerCommandJson()), {
      'type': 'endTurn',
      'expectedRevision': 7,
    });
  });

  test('queries cannot be encoded as player commands', () {
    expect(
      () => AonwClientRequest.reachable(
        expectedRevision: 7,
        unitId: 'unit-1',
      ).toPlayerCommandJson(),
      throwsStateError,
    );
  });

  test('replay playback requests stay recipient-bound', () {
    expect(
      jsonDecode(
        AonwClientRequest.openReplay(
          mapDocument: 'map',
          replayDocument: 'replay',
          recipientPlayerId: 'player-1',
        ).toJson(),
      ),
      {
        'apiVersion': aonwClientApiVersion,
        'request': {
          'type': 'openReplay',
          'mapDocument': 'map',
          'replayDocument': 'replay',
          'recipientPlayerId': 'player-1',
        },
      },
    );
    expect(jsonDecode(AonwClientRequest.seekReplay(position: 4).toJson()), {
      'apiVersion': aonwClientApiVersion,
      'request': {'type': 'seekReplay', 'position': 4},
    });
  });

  test('turn parser preserves complete ordered event and evidence corpus', () {
    final events = _eventCorpus().map(AonwClientEvent.fromJson).toList();
    expect(events.map((event) => event.kind), AonwClientEventKind.values);

    final evidence =
        AonwClientEvidence.fromJson({
              'type': 'turnKernel',
              'processors': ['movement', 'production'],
              'foundedCityIds': ['city-1'],
              'combatExecutions': <Object?>[],
              'resetUnitIds': ['unit-1'],
              'movementExecutions': <Object?>[],
              'invalidatedOrderUnitIds': ['unit-2'],
              'finishedAutoExploreUnitIds': ['unit-3'],
            })
            as AonwTurnKernelEvidence;
    expect(evidence.processors, ['movement', 'production']);
    expect(evidence.foundedCityIds, ['city-1']);
    expect(evidence.resetUnitIds, ['unit-1']);
  });

  test('turn parser fails closed for unknown event and evidence variants', () {
    expect(
      () => AonwClientEvent.fromJson(const {'type': 'futureEvent'}),
      throwsFormatException,
    );
    expect(
      () => AonwClientEvidence.fromJson(const {'type': 'futureEvidence'}),
      throwsFormatException,
    );
  });

  test('shared client goldens stay consumable from Dart', () {
    final request = AonwClientRequest.moveUnit(
      expectedRevision: 7,
      unitId: 'unit-1',
      targetCol: 3,
      targetRow: 4,
    );
    final requestGolden = _fixture(
      'move_unit_request.json',
    ).readAsStringSync().trim();
    expect(request.toJson(), requestGolden);

    final responseGolden = _fixture(
      'command_result_response.json',
    ).readAsStringSync();
    final response = AonwClientResponse.parse(responseGolden);
    final command = response.require<AonwCommandResponse>().result;
    expect(command.stamp.revision, 8);
    expect(command.viewPatch.turn, 7);
    expect(command.viewPatch.upsertedUnits.single.kind, AonwUnitKind.commander);
    expect(command.events.single, isA<AonwUnitMovedEvent>());
    expect(command.evidence, isA<AonwUnitMovementEvidence>());

    final inspectRequest = AonwClientRequest.inspectMap(
      mapDocument: 'map-document',
    );
    expect(
      inspectRequest.toJson(),
      _fixture('inspect_map_request.json').readAsStringSync().trim(),
    );
    final mapResponse = AonwClientResponse.parse(
      _fixture('map_inspected_response.json').readAsStringSync(),
    ).require<AonwMapInspectedResponse>();
    expect(mapResponse.map.gridLayout, AonwMapGridLayout.oddQFlatTop);
    expect(mapResponse.map.tiles.single.displayTerrain, AonwMapTerrain.forest);
    expect(mapResponse.map.objectives.single.type, AonwMapObjectiveType.ruins);
  });

  test('client response rejects foreign versions', () {
    const foreignVersion = aonwClientApiVersion + 1;
    expect(
      () => AonwClientResponse.parse(
        '{"apiVersion":$foreignVersion,"outcome":{"status":"success",'
        '"response":{"type":"sessionClosed"}}}',
      ),
      throwsFormatException,
    );
  });

  test('native availability and session creation stay coherent', () async {
    expect(aonwEngineClientIdentity.isCompatible, aonwEngineClientAvailable);
    final session = await createAonwEngineSession();
    expect(session != null, aonwEngineClientAvailable);
    if (session == null) return;
    expect(
      aonwEngineClientIdentity.buildIdentity,
      aonwExpectedNativeBuildIdentity,
    );
    addTearDown(session.close);

    final rawResponse = await session.requestJson(
      AonwClientRequest.capabilities().toJson(),
    );
    final response = jsonDecode(rawResponse) as Map<String, dynamic>;
    expect(response['apiVersion'], aonwClientApiVersion);
    final capabilities = AonwClientResponse.parse(
      rawResponse,
    ).require<AonwCapabilitiesResponse>();
    expect(capabilities.features, unorderedEquals(AonwClientFeature.values));

    final inspected = AonwClientResponse.parse(
      await session.requestJson(
        AonwClientRequest.inspectMap(
          mapDocument: _starterMap().readAsStringSync(),
        ).toJson(),
      ),
    ).require<AonwMapInspectedResponse>();
    expect(inspected.map.mapId, 'aonw2_starter');
    expect(inspected.map.tiles, hasLength(49));
    expect(
      inspected.map.contentHash,
      '4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d',
    );
  });
}

List<Map<String, Object?>> _eventCorpus() => [
  ..._worldEvents(),
  ..._diplomacyEvents(),
  ..._unitAndTurnEvents(),
];

List<Map<String, Object?>> _worldEvents() {
  const coordinate = {'col': 1, 'row': 2};
  const target = {'type': 'unit', 'unitId': 'target-1'};
  const outcome = {
    'condition': 'ongoing',
    'winnerPlayerId': null,
    'scoreByPlayerId': <String, int>{},
  };
  return [
    {
      'type': 'artifactExcavationStarted',
      'artifactId': 'a',
      'ownerPlayerId': 'p1',
      'unitId': 'u1',
      'coordinate': coordinate,
    },
    {
      'type': 'artifactCarried',
      'artifactId': 'a',
      'ownerPlayerId': 'p1',
      'unitId': 'u1',
      'coordinate': coordinate,
    },
    {
      'type': 'artifactStored',
      'artifactId': 'a',
      'ownerPlayerId': 'p1',
      'sourceUnitId': 'u1',
      'cityId': 'c1',
      'coordinate': coordinate,
    },
    {'type': 'cityFounded', 'cityId': 'c1', 'ownerPlayerId': 'p1'},
    {'type': 'cityBuiltBuilding', 'cityId': 'c1', 'buildingType': 'granary'},
    {
      'type': 'cityProducedUnit',
      'cityId': 'c1',
      'unitType': 'worker',
      'producedUnitId': 'u2',
    },
    {
      'type': 'cityBuiltWonder',
      'cityId': 'c1',
      'ownerPlayerId': 'p1',
      'wonderType': 'greatLibrary',
    },
    {
      'type': 'wonderProductionRefunded',
      'cityId': 'c1',
      'ownerPlayerId': 'p1',
      'wonderType': 'greatLibrary',
      'refundedProduction': 5,
    },
    {
      'type': 'technologyResearched',
      'playerId': 'p1',
      'technologyId': 'agriculture',
    },
    {'type': 'researchPointsGained', 'playerId': 'p1', 'points': 3},
    {'type': 'cityClaimedHex', 'cityId': 'c1', 'col': 1, 'row': 2},
    {
      'type': 'stabilityBandChanged',
      'playerId': 'p1',
      'previousBand': 'stable',
      'newBand': 'content',
      'net': 2,
    },
    {
      'type': 'mapObjectiveSecured',
      'playerId': 'p1',
      'objectiveId': 'o1',
      'objectiveType': 'ruins',
      'col': 1,
      'row': 2,
      'holdTurns': 2,
      'requiredHoldTurns': 2,
      'victoryPoints': 5,
      'goldPerTurn': 1,
    },
    {
      'type': 'dominationThresholdReached',
      'playerId': 'p1',
      'controlPercent': 60,
      'requiredControlPercent': 60,
      'holdTurns': 1,
      'requiredHoldTurns': 2,
    },
    {'type': 'matchEnded', 'turn': 7, 'outcome': outcome},
    {'type': 'unitAttacked', 'attackerUnitId': 'u1', 'target': target},
    {'type': 'cityAttacked', 'attackerUnitId': 'u1', 'target': target},
    {'type': 'combatResolved', 'attackerUnitId': 'u1', 'target': target},
  ];
}

List<Map<String, Object?>> _diplomacyEvents() => [
  {
    'type': 'diplomaticScoreChanged',
    'playerAId': 'p1',
    'playerBId': 'p2',
    'delta': -1,
    'scoreAfter': 2,
    'reason': 'unitAttack',
    'sourceId': 'u1',
  },
  {
    'type': 'diplomaticProposalSent',
    'proposalId': 'd1',
    'fromPlayerId': 'p1',
    'toPlayerId': 'p2',
    'kind': 'friendship',
    'expiresOnTurn': 8,
  },
  {
    'type': 'diplomaticProposalResponded',
    'proposalId': 'd1',
    'fromPlayerId': 'p1',
    'toPlayerId': 'p2',
    'kind': 'friendship',
    'accepted': true,
  },
  {
    'type': 'diplomaticProposalExpired',
    'proposalId': 'd1',
    'fromPlayerId': 'p1',
    'toPlayerId': 'p2',
    'kind': 'friendship',
  },
  {
    'type': 'diplomaticMessageSent',
    'messageId': 'm1',
    'fromPlayerId': 'p1',
    'toPlayerId': 'p2',
    'topic': 'peacefulPraise',
    'category': 'praise',
    'expiresOnTurn': 8,
  },
  {
    'type': 'diplomaticMessageResponded',
    'messageId': 'm1',
    'fromPlayerId': 'p1',
    'toPlayerId': 'p2',
    'topic': 'peacefulPraise',
    'response': 'conciliatory',
    'relationDelta': 1,
    'relationScoreAfter': 3,
    'promiseDueTurn': null,
  },
  {
    'type': 'diplomaticPromiseBroken',
    'messageId': 'm1',
    'playerAId': 'p1',
    'playerBId': 'p2',
    'delta': -2,
    'scoreAfter': 1,
  },
  {
    'type': 'diplomaticRelationChanged',
    'playerAId': 'p1',
    'playerBId': 'p2',
    'oldStatus': 'neutral',
    'newStatus': 'friendly',
    'reason': 'proposalAccepted',
    'expiresOnTurn': null,
  },
];

List<Map<String, Object?>> _unitAndTurnEvents() {
  const coordinate = {'col': 1, 'row': 2};
  const target = {'type': 'unit', 'unitId': 'target-1'};
  return [
    {
      'type': 'unitGainedExperience',
      'attackerUnitId': 'u1',
      'target': target,
      'subjectUnitId': 'u1',
    },
    {
      'type': 'unitKilled',
      'attackerUnitId': 'u1',
      'target': target,
      'subjectUnitId': 'u2',
    },
    {
      'type': 'unitRetreated',
      'attackerUnitId': 'u1',
      'target': target,
      'subjectUnitId': 'u2',
    },
    {'type': 'cityCaptured', 'attackerUnitId': 'u1', 'target': target},
    {'type': 'cityDestroyed', 'attackerUnitId': 'u1', 'target': target},
    {'type': 'unitMoved', 'unitId': 'u1', 'from': coordinate, 'to': coordinate},
    {'type': 'autoExplorePlanned', 'unitId': 'u1', 'target': coordinate},
    {
      'type': 'merchantRouteAssigned',
      'unitId': 'u1',
      'originCityId': 'c1',
      'destinationCityId': 'c2',
    },
    {'type': 'merchantTravelQueued', 'unitId': 'u1', 'destinationCityId': 'c2'},
    {
      'type': 'troopDetached',
      'sourceUnitId': 'u1',
      'detachedUnitId': 'u2',
      'troopKind': 'warrior',
      'destination': coordinate,
    },
    {'type': 'turnEnded', 'playerId': 'p1'},
    {
      'type': 'allPlayersSubmitted',
      'turn': 7,
      'playerIds': ['p1', 'p2'],
    },
    {'type': 'playerTimedOut', 'turn': 7, 'playerId': 'p2'},
    {
      'type': 'playerKicked',
      'turn': 7,
      'playerId': 'p2',
      'reason': 'timeout',
      'timeoutStreak': 3,
    },
    {
      'type': 'workerCompletedJob',
      'unitId': 'u1',
      'target': coordinate,
      'completion': {'type': 'fieldImprovement', 'improvement': 'farm'},
    },
  ];
}

File _starterMap() {
  for (final path in [
    'clients/aonw_godot/assets/maps/aonw2_starter/map.json',
    '../../clients/aonw_godot/assets/maps/aonw2_starter/map.json',
  ]) {
    final candidate = File(path);
    if (candidate.existsSync()) return candidate;
  }
  throw StateError('Starter map fixture not found.');
}

File _fixture(String name) {
  for (final root in [
    'test/fixtures/client_protocol',
    '../../tests/fixtures/client_protocol',
  ]) {
    final candidate = File('$root/$name');
    if (candidate.existsSync()) return candidate;
  }
  throw StateError('Shared client fixture not found: $name');
}
