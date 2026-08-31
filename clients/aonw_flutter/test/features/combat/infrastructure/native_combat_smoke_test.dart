import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test('keeps native combat exact, recipient-safe and replayable', _runSmoke);
}

Future<void> _runSmoke() async {
  final session = await createAonwEngineSession();
  if (session == null) fail('The native engine session is unavailable.');
  addTearDown(session.close);
  final mapDocument = File(
    '../../content/maps/aonw2_starter/map.json',
  ).readAsStringSync();
  final initial = await _openFixture(session, mapDocument);
  final command = await _executeCombat(session, initial.stamp.revision);
  final documents = await _exportDocuments(session);
  await _assertForeignView(session, command.stamp.revision);
  await _assertPersistence(session, mapDocument, documents, command.stamp);
}

Future<AonwPlayerViewSnapshot> _openFixture(
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
  expect(opened.isSuccess, isTrue);
  final initial = (await session.send(
    AonwClientRequest.snapshot(),
  )).require<AonwSnapshotResponse>().snapshot;
  expect(
    initial.units.map((unit) => unit.id),
    containsAll(['attacker', 'defender']),
  );
  return initial;
}

Future<AonwCommandResult> _executeCombat(
  AonwEngineSession session,
  int revision,
) async {
  final preview = await _preview(session, revision);
  final command = (await session.send(
    AonwClientRequest.attackHex(
      expectedRevision: revision,
      attackerUnitId: 'attacker',
      defenderCol: 2,
      defenderRow: 1,
      cityConquestAction: AonwCityConquestAction.capture,
    ),
  )).require<AonwCommandResponse>().result;
  expect(command.accepted, isTrue);
  _assertExactEvidence(command, preview);
  return command;
}

Future<AonwCombatPreview> _preview(
  AonwEngineSession session,
  int revision,
) async {
  final result =
      (await session.send(
            AonwClientRequest.combatPreview(
              expectedRevision: revision,
              attackerUnitId: 'attacker',
              defenderCol: 2,
              defenderRow: 1,
            ),
          )).require<AonwQueryResponse>().result
          as AonwCombatPreviewResult;
  expect(result.preview.target, isA<AonwUnitCombatTarget>());
  expect(result.preview.outgoingDamageMax, greaterThanOrEqualTo(1));
  return result.preview;
}

void _assertExactEvidence(
  AonwCommandResult command,
  AonwCombatPreview preview,
) {
  final execution = (command.evidence as AonwCombatEvidence).execution;
  expect(execution.preview.attackerUnitId, preview.attackerUnitId);
  expect(execution.preview.outgoingDamageMin, preview.outgoingDamageMin);
  expect(execution.preview.outgoingDamageMax, preview.outgoingDamageMax);
  expect(
    command.events.map((event) => event.kind),
    contains(AonwClientEventKind.combatResolved),
  );
}

Future<({String save, String replay})> _exportDocuments(
  AonwEngineSession session,
) async => (
  save: (await session.send(
    AonwClientRequest.exportSave(),
  )).require<AonwSaveExportedResponse>().document,
  replay: (await session.send(
    AonwClientRequest.exportReplay(),
  )).require<AonwReplayExportedResponse>().document,
);

Future<void> _assertForeignView(AonwEngineSession session, int revision) async {
  await session.send(AonwClientRequest.handoffActor(actorPlayerId: 'player-2'));
  final response = await session.send(
    AonwClientRequest.combatPreview(
      expectedRevision: revision,
      attackerUnitId: 'attacker',
      defenderCol: 2,
      defenderRow: 1,
    ),
  );
  expect(response.isSuccess, isFalse);
  expect(
    response.error?.code,
    anyOf('attacker_not_controlled', 'attacker_not_found'),
  );
}

Future<void> _assertPersistence(
  AonwEngineSession session,
  String mapDocument,
  ({String save, String replay}) documents,
  AonwSessionStamp stamp,
) async {
  final reopened = (await session.send(
    AonwClientRequest.openSave(
      mapDocument: mapDocument,
      saveDocument: documents.save,
    ),
  )).require<AonwSaveOpenedResponse>().stamp;
  expect(reopened.stateDigest, stamp.stateDigest);
  final verified = (await session.send(
    AonwClientRequest.verifyReplay(
      mapDocument: mapDocument,
      replayDocument: documents.replay,
    ),
  )).require<AonwReplayVerifiedResponse>().verification;
  expect(verified.entryCount, 1);
  expect(verified.finalStamp.stateDigest, stamp.stateDigest);
}

final _scenarioDocument = jsonEncode(const {
  'schemaVersion': 1,
  'scenarioId': 'flutter-combat-smoke',
  'mapId': 'aonw2_starter',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'attacker',
      'ownerPlayerId': 'player-1',
      'kind': 'warrior',
      'name': 'Attacker',
      'col': 1,
      'row': 1,
    },
    {
      'id': 'defender',
      'ownerPlayerId': 'player-2',
      'kind': 'settler',
      'name': 'Defender',
      'col': 2,
      'row': 1,
    },
  ],
});

final _matchIdentity = testMatchIdentity();
