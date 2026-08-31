import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test(
    'keeps native city queries commands secrecy and replay exact',
    _runSmoke,
  );
}

Future<void> _runSmoke() async {
  final session = await createAonwEngineSession();
  if (session == null) fail('The native engine session is unavailable.');
  addTearDown(session.close);
  final mapDocument = File(
    '../../content/maps/aonw2_starter/map.json',
  ).readAsStringSync();
  final initial = await _start(session, mapDocument);
  final founded = await _foundCity(session, initial.stamp.revision);
  final completed = await _completeFounding(session, founded.stamp.revision);
  final finalStamp = await _inspectAndConfigure(
    session,
    completed.cityId,
    completed.stamp.revision,
  );
  final save = (await session.send(
    AonwClientRequest.exportSave(),
  )).require<AonwSaveExportedResponse>().document;
  final replay = (await session.send(
    AonwClientRequest.exportReplay(),
  )).require<AonwReplayExportedResponse>().document;
  await _assertForeignRecipient(session, completed.cityId);
  await _assertPersistence(session, mapDocument, save, replay, finalStamp);
}

Future<AonwPlayerViewSnapshot> _start(
  AonwEngineSession session,
  String mapDocument,
) async {
  final opened = await session.send(
    AonwClientRequest.startMatch(
      mapDocument: mapDocument,
      scenarioDocument: _scenarioDocument,
      actorPlayerId: 'player-1',
      matchIdentity: _matchIdentity,
      fogEnabled: false,
    ),
  );
  expect(
    opened.isSuccess,
    isTrue,
    reason: '${opened.error?.code}: ${opened.error?.message}',
  );
  return (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
}

Future<AonwCommandResult> _foundCity(
  AonwEngineSession session,
  int revision,
) async {
  final options =
      (await session.send(
            AonwCityRequest.foundingOptions(
              expectedRevision: revision,
              founderUnitId: 'settler',
            ),
          )).require<AonwQueryResponse>().result
          as AonwCityFoundingOptionsResult;
  final controlled = [...options.selectedControlledHexes];
  controlled.addAll(
    options.availableControlledHexes.take(
      options.requiredControlledHexes - controlled.length,
    ),
  );
  expect(controlled, hasLength(options.requiredControlledHexes));
  final command = (await session.send(
    AonwCityRequest.found(
      expectedRevision: revision,
      founderUnitId: 'settler',
      controlledHexes: controlled,
    ),
  )).require<AonwCommandResponse>().result;
  expect(command.accepted, isTrue);
  expect(command.events, isEmpty);
  expect(command.evidence, isNull);
  final scheduled = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  final job = scheduled.units
      .singleWhere((unit) => unit.id == 'settler')
      .ownedDetails
      ?.cityFoundingJob;
  expect(job, isNotNull);
  expect(
    job?.controlledHexes.map((hex) => (hex.col, hex.row)),
    unorderedEquals(controlled.map((hex) => (hex.col, hex.row))),
  );
  return command;
}

Future<({String cityId, AonwSessionStamp stamp})> _completeFounding(
  AonwEngineSession session,
  int revision,
) async {
  final submitted = (await session.send(
    AonwClientRequest.endTurn(expectedRevision: revision),
  )).require<AonwCommandResponse>().result;
  expect(submitted.accepted, isTrue);
  expect(
    (submitted.evidence as AonwTurnKernelEvidence).foundedCityIds,
    isEmpty,
  );

  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-2'));
  final foreign = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  final completed = (await session.send(
    AonwClientRequest.endTurn(expectedRevision: foreign.stamp.revision),
  )).require<AonwCommandResponse>().result;
  expect(completed.accepted, isTrue);
  final evidence = completed.evidence as AonwTurnKernelEvidence;
  expect(evidence.foundedCityIds, isEmpty);
  expect(completed.viewPatch.upsertedCities, hasLength(1));
  expect(completed.viewPatch.upsertedCities.single.ownedDetails, isNull);

  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-1'));
  final snapshot = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  expect(snapshot.units.where((unit) => unit.id == 'settler'), isEmpty);
  expect(snapshot.cities, hasLength(1));
  final cityId = snapshot.cities.single.id;
  expect(
    snapshot.cities.singleWhere((city) => city.id == cityId).ownedDetails,
    isNotNull,
  );
  return (cityId: cityId, stamp: snapshot.stamp);
}

Future<AonwSessionStamp> _inspectAndConfigure(
  AonwEngineSession session,
  String cityId,
  int revision,
) async {
  final worked = await _query<AonwCityWorkedHexOptionsResult>(
    session,
    AonwCityRequest.workedHexOptions(
      expectedRevision: revision,
      cityId: cityId,
    ),
  );
  final expansion = await _query<AonwCityExpansionOptionsResult>(
    session,
    AonwCityRequest.expansionOptions(
      expectedRevision: revision,
      cityId: cityId,
    ),
  );
  final cityYield = await _query<AonwCityYieldResult>(
    session,
    AonwCityRequest.cityYield(expectedRevision: revision, cityId: cityId),
  );
  expect(cityYield.contributions, isNotEmpty);
  expect(worked.availableHexes, isNotEmpty);
  expect(expansion.candidates, isNotEmpty);

  final toggled = (await session.send(
    AonwCityRequest.toggleWorkedHex(
      expectedRevision: revision,
      cityId: cityId,
      targetCol: worked.availableHexes.first.col,
      targetRow: worked.availableHexes.first.row,
    ),
  )).require<AonwCommandResponse>().result;
  expect(toggled.accepted, isTrue);
  final candidate = expansion.candidates.first;
  final selected = (await session.send(
    AonwCityRequest.selectExpansionHex(
      expectedRevision: toggled.stamp.revision,
      cityId: cityId,
      targetCol: candidate.coordinate.col,
      targetRow: candidate.coordinate.row,
    ),
  )).require<AonwCommandResponse>().result;
  expect(selected.accepted, isTrue);
  return _configureProduction(session, cityId, selected.stamp.revision);
}

Future<AonwSessionStamp> _configureProduction(
  AonwEngineSession session,
  String cityId,
  int revision,
) async {
  final resources = await _query<AonwStrategicResourceProjectionResult>(
    session,
    AonwProductionRequest.strategicResources(expectedRevision: revision),
  );
  expect(resources.playerId, 'player-1');
  final options = await _query<AonwProductionOptionsResult>(
    session,
    AonwProductionRequest.options(expectedRevision: revision, cityId: cityId),
  );
  expect(options.cityId, cityId);
  final building = options.buildings.firstWhere(
    (option) => option.rejection == null,
  );
  final buildingType = building.target.buildingType;
  expect(buildingType, isNotNull);
  final started = (await session.send(
    AonwProductionRequest.startBuilding(
      expectedRevision: revision,
      cityId: cityId,
      building: buildingType!,
    ),
  )).require<AonwCommandResponse>().result;
  expect(started.accepted, isTrue);
  expect(started.events, isEmpty);
  expect(started.evidence, isNull);
  final snapshot = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  final queue = snapshot.cities
      .singleWhere((city) => city.id == cityId)
      .ownedDetails
      ?.productionQueue;
  expect(queue?.target.buildingType, buildingType);
  final refreshed = await _query<AonwProductionOptionsResult>(
    session,
    AonwProductionRequest.options(
      expectedRevision: started.stamp.revision,
      cityId: cityId,
    ),
  );
  expect(refreshed.currentTarget?.buildingType, buildingType);
  return started.stamp;
}

Future<T> _query<T extends AonwQueryResult>(
  AonwEngineSession session,
  AonwClientRequest request,
) async {
  final result = (await session.send(
    request,
  )).require<AonwQueryResponse>().result;
  expect(result, isA<T>());
  return result as T;
}

Future<void> _assertForeignRecipient(
  AonwEngineSession session,
  String cityId,
) async {
  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-2'));
  final snapshot = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  final city = snapshot.cities.singleWhere((value) => value.id == cityId);
  expect(city.ownedDetails, isNull);
  final privateQuery = await session.send(
    AonwCityRequest.cityYield(
      expectedRevision: snapshot.stamp.revision,
      cityId: cityId,
    ),
  );
  expect(privateQuery.isSuccess, isFalse);
  expect(privateQuery.error?.code, 'city_not_controlled');
  final privateProduction = await session.send(
    AonwProductionRequest.options(
      expectedRevision: snapshot.stamp.revision,
      cityId: cityId,
    ),
  );
  expect(privateProduction.isSuccess, isFalse);
  expect(privateProduction.error?.code, 'city_not_controlled');
}

Future<void> _assertPersistence(
  AonwEngineSession session,
  String mapDocument,
  String save,
  String replay,
  AonwSessionStamp finalStamp,
) async {
  final reopened = (await session.send(
    AonwClientRequest.openSave(mapDocument: mapDocument, saveDocument: save),
  )).require<AonwSaveOpenedResponse>().stamp;
  expect(reopened.stateDigest, finalStamp.stateDigest);
  final verification = (await session.send(
    AonwClientRequest.verifyReplay(
      mapDocument: mapDocument,
      replayDocument: replay,
    ),
  )).require<AonwReplayVerifiedResponse>().verification;
  expect(verification.entryCount, 6);
  expect(verification.finalStamp.stateDigest, finalStamp.stateDigest);
}

final _scenarioDocument = jsonEncode(const {
  'schemaVersion': 1,
  'scenarioId': 'flutter-city-smoke',
  'mapId': 'aonw2_starter',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'settler',
      'ownerPlayerId': 'player-1',
      'kind': 'settler',
      'name': 'Settler',
      'col': 3,
      'row': 3,
    },
    {
      'id': 'observer',
      'ownerPlayerId': 'player-2',
      'kind': 'scout',
      'name': 'Observer',
      'col': 6,
      'row': 6,
    },
  ],
});

final _matchIdentity = testMatchIdentity();
