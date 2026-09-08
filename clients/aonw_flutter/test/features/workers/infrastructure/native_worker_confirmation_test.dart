import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test(
    'native confirmation starts the queried improvement without a pending command',
    () async {
      final session = await createAonwEngineSession();
      if (session == null) fail('The native engine session is unavailable.');
      addTearDown(session.close);
      final opened = await session.send(
        AonwClientRequest.startMatch(
          mapDocument: File(
            '../../content/maps/aonw2_starter/map.json',
          ).readAsStringSync(),
          scenarioDocument: _scenario,
          actorPlayerId: 'player-1',
          matchIdentity: testMatchIdentity(),
          fogEnabled: false,
        ),
      );
      expect(opened.isSuccess, isTrue);
      await _foundCity(session);
      await _researchAgriculture(session);
      final before = await _snapshot(session);
      expect(before.pendingAction, isNull);
      expect(
        before.units.singleWhere((unit) => unit.id == 'worker').workerJob,
        isNull,
      );
      final options =
          (await session.send(
                AonwWorkerRequest.options(
                  expectedRevision: before.stamp.revision,
                  unitId: 'worker',
                ),
              )).require<AonwQueryResponse>().result
              as AonwWorkerOptionsResult;
      expect(options.improvements, isNotEmpty);
      final option = options.improvements.first;
      expect(
        (await _snapshot(session)).stamp.stateDigest,
        before.stamp.stateDigest,
      );
      final result = (await session.send(
        AonwWorkerRequest.confirmImprovement(
          expectedRevision: before.stamp.revision,
          unitId: 'worker',
          improvement: option.improvement,
        ),
      )).require<AonwCommandResponse>().result;
      expect(result.accepted, isTrue, reason: '${result.rejection}');
      final after = await _snapshot(session);
      expect(after.stamp.revision, before.stamp.revision + 1);
      final job = after.units
          .singleWhere((unit) => unit.id == 'worker')
          .workerJob;
      expect(job, isA<AonwFieldImprovementJobView>());
      expect(
        (job! as AonwFieldImprovementJobView).improvement,
        option.improvement,
      );
      expect(job.remainingTurns, option.buildTurns);
      expect(job.totalTurns, option.buildTurns);
      final duplicate = (await session.send(
        AonwWorkerRequest.confirmImprovement(
          expectedRevision: after.stamp.revision,
          unitId: 'worker',
          improvement: option.improvement,
        ),
      )).require<AonwCommandResponse>().result;
      expect(duplicate.accepted, isFalse);
      expect(
        (await _snapshot(session)).stamp.stateDigest,
        after.stamp.stateDigest,
      );
    },
  );
}

Future<void> _foundCity(AonwEngineSession session) async {
  final initial = await _snapshot(session);
  final options =
      (await session.send(
            AonwCityRequest.foundingOptions(
              expectedRevision: initial.stamp.revision,
              founderUnitId: 'settler',
            ),
          )).require<AonwQueryResponse>().result
          as AonwCityFoundingOptionsResult;
  final workerHex = options.availableControlledHexes.firstWhere(
    (hex) => hex.col == 3 && hex.row == 2,
  );
  final selected = [
    workerHex,
    ...options.selectedControlledHexes.where(
      (hex) => hex.col != 3 || hex.row != 2,
    ),
  ];
  for (final candidate in options.availableControlledHexes) {
    if (selected.length == options.requiredControlledHexes) break;
    if (!selected.any(
      (hex) => hex.col == candidate.col && hex.row == candidate.row,
    )) {
      selected.add(candidate);
    }
  }
  final founded = (await session.send(
    AonwCityRequest.found(
      expectedRevision: initial.stamp.revision,
      founderUnitId: 'settler',
      controlledHexes: selected.take(options.requiredControlledHexes).toList(),
    ),
  )).require<AonwCommandResponse>().result;
  expect(founded.accepted, isTrue);
  final submitted = (await session.send(
    AonwClientRequest.endTurn(expectedRevision: founded.stamp.revision),
  )).require<AonwCommandResponse>().result;
  expect(submitted.accepted, isTrue);
  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-2'));
  final foreign = await _snapshot(session);
  final completed = (await session.send(
    AonwClientRequest.endTurn(expectedRevision: foreign.stamp.revision),
  )).require<AonwCommandResponse>().result;
  expect(completed.accepted, isTrue);
  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-1'));
}

Future<AonwPlayerViewSnapshot> _snapshot(AonwEngineSession session) async =>
    (await session.send(
      AonwClientRequest.snapshot(),
    )).require<AonwSnapshotResponse>().snapshot;

final _scenario = jsonEncode(const {
  'schemaVersion': 1,
  'scenarioId': 'flutter-worker-confirmation',
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
      'id': 'worker',
      'ownerPlayerId': 'player-1',
      'kind': 'worker',
      'name': 'Worker',
      'col': 3,
      'row': 2,
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

Future<void> _researchAgriculture(AonwEngineSession session) async {
  final initial = await _snapshot(session);
  final started = (await session.send(
    AonwResearchRequest.select(
      expectedRevision: initial.stamp.revision,
      technology: AonwTechnologyId.agriculture,
    ),
  )).require<AonwCommandResponse>().result;
  expect(started.accepted, isTrue);
  for (var round = 0; round < 100; round++) {
    final snapshot = await _snapshot(session);
    final research =
        (await session.send(
              AonwResearchRequest.options(
                expectedRevision: snapshot.stamp.revision,
              ),
            )).require<AonwQueryResponse>().result
            as AonwResearchOptionsResult;
    if (research.options
            .singleWhere(
              (option) => option.technology == AonwTechnologyId.agriculture,
            )
            .availability ==
        AonwTechnologyAvailability.unlocked) {
      final next = research.options.firstWhere(
        (option) => option.availability == AonwTechnologyAvailability.available,
      );
      final selected = (await session.send(
        AonwResearchRequest.select(
          expectedRevision: snapshot.stamp.revision,
          technology: next.technology,
        ),
      )).require<AonwCommandResponse>().result;
      expect(selected.accepted, isTrue);
      return;
    }
    for (final actor in ['player-1', 'player-2']) {
      await session.send(AonwClientRequest.handoffActor(actorPlayerId: actor));
      final current = await _snapshot(session);
      final ended = (await session.send(
        AonwClientRequest.endTurn(expectedRevision: current.stamp.revision),
      )).require<AonwCommandResponse>().result;
      expect(ended.accepted, isTrue, reason: '$actor: ${ended.rejection}');
    }
    await session.send(
      AonwClientRequest.handoffActor(actorPlayerId: 'player-1'),
    );
  }
  fail('Agriculture did not unlock within the bounded scenario.');
}
