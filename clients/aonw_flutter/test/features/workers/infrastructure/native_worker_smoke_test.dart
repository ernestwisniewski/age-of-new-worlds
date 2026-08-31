import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test('keeps native worker progress secrecy save and replay exact', () async {
    final session = await createAonwEngineSession();
    if (session == null) fail('The native engine session is unavailable.');
    addTearDown(session.close);
    final mapDocument = File(
      '../../content/maps/aonw2_starter/map.json',
    ).readAsStringSync();
    final initial = await _start(session, mapDocument);

    final options = await _options(session, initial.stamp.revision);
    expect(options.canBuildRoad, isTrue);
    expect(options.coordinate.col, 1);
    expect(options.coordinate.row, 1);

    final stale = (await session.send(
      AonwWorkerRequest.buildRoad(
        expectedRevision: initial.stamp.revision + 1,
        unitId: 'worker',
      ),
    )).require<AonwCommandResponse>().result;
    expect(stale.accepted, isFalse);
    expect(stale.rejection, AonwCommandRejectionCode.staleRevision);
    expect(stale.stamp.stateDigest, initial.stamp.stateDigest);

    final started = (await session.send(
      AonwWorkerRequest.buildRoad(
        expectedRevision: initial.stamp.revision,
        unitId: 'worker',
      ),
    )).require<AonwCommandResponse>().result;
    expect(started.accepted, isTrue);
    expect(started.evidence, isNull);
    expect(started.viewPatch.upsertedUnits, hasLength(1));
    final progress = await _snapshot(session);
    final job = progress.units
        .singleWhere((unit) => unit.id == 'worker')
        .workerJob;
    expect(job, isA<AonwRoadConstructionJobView>());
    expect(job!.remainingTurns, job.totalTurns);

    final midSave = (await session.send(
      AonwClientRequest.exportSave(),
    )).require<AonwSaveExportedResponse>().document;
    await _assertMidSave(mapDocument, midSave, progress);

    final completed = await _completeRoad(session, progress, job.totalTurns);
    expect(completed.roads, hasLength(1));
    expect(completed.roads.single.coordinate.col, 1);
    expect(completed.roads.single.coordinate.row, 1);

    final existing = (await session.send(
      AonwWorkerRequest.buildRoad(
        expectedRevision: completed.stamp.revision,
        unitId: 'worker',
      ),
    )).require<AonwCommandResponse>().result;
    expect(existing.accepted, isFalse);
    expect(
      existing.rejection,
      AonwCommandRejectionCode.roadConstructionExistingRoad,
    );
    expect(existing.stamp.stateDigest, completed.stamp.stateDigest);

    final save = (await session.send(
      AonwClientRequest.exportSave(),
    )).require<AonwSaveExportedResponse>().document;
    final replay = (await session.send(
      AonwClientRequest.exportReplay(),
    )).require<AonwReplayExportedResponse>().document;
    await _assertForeignRecipient(session);
    await _assertFinalPersistence(
      session,
      mapDocument: mapDocument,
      save: save,
      replay: replay,
      finalStamp: completed.stamp,
    );
  });
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
      fogEnabled: true,
    ),
  );
  expect(
    opened.isSuccess,
    isTrue,
    reason: '${opened.error?.code}: ${opened.error?.message}',
  );
  return _snapshot(session);
}

Future<AonwWorkerOptionsResult> _options(
  AonwEngineSession session,
  int revision,
) async {
  final result = (await session.send(
    AonwWorkerRequest.options(expectedRevision: revision, unitId: 'worker'),
  )).require<AonwQueryResponse>().result;
  expect(result, isA<AonwWorkerOptionsResult>());
  return result as AonwWorkerOptionsResult;
}

Future<AonwPlayerViewSnapshot> _completeRoad(
  AonwEngineSession session,
  AonwPlayerViewSnapshot current,
  int totalTurns,
) async {
  var snapshot = current;
  for (var turn = 0; turn <= totalTurns; turn++) {
    if (snapshot.roads.isNotEmpty) return snapshot;
    final submitted = (await session.send(
      AonwClientRequest.endTurn(expectedRevision: snapshot.stamp.revision),
    )).require<AonwCommandResponse>().result;
    expect(submitted.accepted, isTrue);
    await session.send(
      AonwClientRequest.handoffActor(actorPlayerId: 'player-2'),
    );
    final foreign = await _snapshot(session);
    final advanced = (await session.send(
      AonwClientRequest.endTurn(expectedRevision: foreign.stamp.revision),
    )).require<AonwCommandResponse>().result;
    expect(advanced.accepted, isTrue);
    await session.send(
      AonwClientRequest.handoffActor(actorPlayerId: 'player-1'),
    );
    snapshot = await _snapshot(session);
  }
  fail('Road construction did not finish within engine-owned duration.');
}

Future<void> _assertMidSave(
  String mapDocument,
  String save,
  AonwPlayerViewSnapshot expected,
) async {
  final reopened = await createAonwEngineSession();
  if (reopened == null) fail('A second native engine session is unavailable.');
  try {
    await reopened.send(
      AonwClientRequest.openSave(mapDocument: mapDocument, saveDocument: save),
    );
    final snapshot = await _snapshot(reopened);
    expect(snapshot.stamp.stateDigest, expected.stamp.stateDigest);
    final job = snapshot.units
        .singleWhere((unit) => unit.id == 'worker')
        .workerJob;
    expect(
      job?.remainingTurns,
      expected.units.single.workerJob?.remainingTurns,
    );
  } finally {
    await reopened.close();
  }
}

Future<void> _assertForeignRecipient(AonwEngineSession session) async {
  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-2'));
  final snapshot = await _snapshot(session);
  expect(snapshot.units.map((unit) => unit.id), ['observer']);
  expect(snapshot.roads, isEmpty);
  final query = await session.send(
    AonwWorkerRequest.options(
      expectedRevision: snapshot.stamp.revision,
      unitId: 'worker',
    ),
  );
  expect(query.isSuccess, isFalse);
  expect(query.error?.code, 'worker_not_controlled');
}

Future<void> _assertFinalPersistence(
  AonwEngineSession session, {
  required String mapDocument,
  required String save,
  required String replay,
  required AonwSessionStamp finalStamp,
}) async {
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
  expect(verification.entryCount, greaterThan(1));
  expect(verification.finalStamp.stateDigest, finalStamp.stateDigest);
}

Future<AonwPlayerViewSnapshot> _snapshot(AonwEngineSession session) async =>
    (await session.send(
      AonwClientRequest.snapshot(),
    )).require<AonwSnapshotResponse>().snapshot;

final _scenarioDocument = jsonEncode(const {
  'schemaVersion': 1,
  'scenarioId': 'flutter-worker-smoke',
  'mapId': 'aonw2_starter',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'worker',
      'ownerPlayerId': 'player-1',
      'kind': 'worker',
      'name': 'Worker',
      'col': 1,
      'row': 1,
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
