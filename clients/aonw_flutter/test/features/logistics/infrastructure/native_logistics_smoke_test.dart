import 'dart:convert';
import 'dart:io';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test(
    'keeps native logistics recipient-safe across save and replay',
    () async {
      final session = await createAonwRustSession();
      if (session == null) fail('The native Rust session is unavailable.');
      addTearDown(session.close);
      final mapDocument = File(
        '../../content/maps/aonw2_starter/map.json',
      ).readAsStringSync();
      final scenarioDocument = jsonEncode({
        'schemaVersion': 1,
        'scenarioId': 'flutter-logistics-smoke',
        'mapId': 'aonw2_starter',
        'rulesetId': 'aonw-standard',
        'initialUnits': [
          {
            'id': 'p1-scout',
            'ownerPlayerId': 'player-1',
            'kind': 'scout',
            'name': 'P1 Scout',
            'col': 1,
            'row': 1,
          },
          {
            'id': 'p2-scout',
            'ownerPlayerId': 'player-2',
            'kind': 'scout',
            'name': 'P2 Scout',
            'col': 6,
            'row': 6,
          },
        ],
      });

      final opened = await session.send(
        AonwClientRequest.startMatch(
          mapDocument: mapDocument,
          scenarioDocument: scenarioDocument,
          actorPlayerId: 'player-1',
          matchIdentity: _matchIdentity,
          fogEnabled: true,
        ),
      );
      expect(opened.isSuccess, isTrue);
      final initial = (await session.send(
        AonwClientRequest.snapshot(),
      )).require<AonwSnapshotResponse>().snapshot;
      expect(initial.units.map((unit) => unit.id), ['p1-scout']);

      final options =
          (await session.send(
                AonwClientRequest.unitLogisticsOptions(
                  expectedRevision: initial.stamp.revision,
                  unitId: 'p1-scout',
                ),
              )).require<AonwQueryResponse>().result
              as AonwUnitLogisticsOptionsResult;
      expect(options.autoExplore, isNotNull);
      final command = (await session.send(
        AonwClientRequest.autoExploreUnit(
          expectedRevision: initial.stamp.revision,
          unitId: 'p1-scout',
        ),
      )).require<AonwCommandResponse>().result;
      expect(command.accepted, isTrue);
      expect(command.evidence, isA<AonwLogisticsEvidence>());

      final save = (await session.send(
        AonwClientRequest.exportSave(),
      )).require<AonwSaveExportedResponse>().document;
      final replay = (await session.send(
        AonwClientRequest.exportReplay(),
      )).require<AonwReplayExportedResponse>().document;

      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-2'),
      );
      final foreign = (await session.send(
        AonwClientRequest.snapshot(),
      )).require<AonwSnapshotResponse>().snapshot;
      expect(foreign.units.map((unit) => unit.id), ['p2-scout']);

      final reopened = (await session.send(
        AonwClientRequest.openSave(
          mapDocument: mapDocument,
          saveDocument: save,
        ),
      )).require<AonwSaveOpenedResponse>().stamp;
      expect(reopened.stateDigest, command.stamp.stateDigest);
      final verification = (await session.send(
        AonwClientRequest.verifyReplay(
          mapDocument: mapDocument,
          replayDocument: replay,
        ),
      )).require<AonwReplayVerifiedResponse>().verification;
      expect(verification.entryCount, 1);
      expect(verification.finalStamp.stateDigest, command.stamp.stateDigest);
    },
  );
}

final _matchIdentity = testMatchIdentity();
