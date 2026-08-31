import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/match_identity_test_fixture.dart';

void main() {
  test(
    'keeps native diplomacy recipient-private saveable and replayable',
    () async {
      final session = await createAonwEngineSession();
      if (session == null) fail('The native engine session is unavailable.');
      addTearDown(session.close);
      final mapDocument = File(
        '../../content/maps/aonw2_starter/map.json',
      ).readAsStringSync();
      final opened = await session.send(
        AonwClientRequest.startMatch(
          mapDocument: mapDocument,
          scenarioDocument: _scenarioDocument,
          actorPlayerId: 'player-1',
          matchIdentity: _matchIdentity,
          fogEnabled: false,
        ),
      );
      expect(opened.isSuccess, isTrue);
      final initial = await _snapshot(session);
      expect(initial.diplomacy.relations, hasLength(2));

      final sent = (await session.send(
        AonwDiplomacyRequest.sendProposal(
          expectedRevision: initial.stamp.revision,
          targetPlayerId: 'player-2',
          kind: AonwDiplomaticProposalKind.friendship,
          proposalId: 'friendship-private',
          goldPayment: 0,
        ),
      )).require<AonwCommandResponse>().result;
      expect(sent.accepted, isTrue);
      expect(
        sent.events.single.kind,
        AonwClientEventKind.diplomaticProposalSent,
      );

      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-3'),
      );
      final observer = await _snapshot(session);
      expect(observer.diplomacy.proposals, isEmpty);

      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-2'),
      );
      final recipient = await _snapshot(session);
      expect(recipient.diplomacy.proposals.single.id, 'friendship-private');
      final responded = (await session.send(
        AonwDiplomacyRequest.respondProposal(
          expectedRevision: recipient.stamp.revision,
          proposalId: 'friendship-private',
          accepted: false,
        ),
      )).require<AonwCommandResponse>().result;
      expect(responded.accepted, isTrue);

      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-1'),
      );
      final sender = await _snapshot(session);
      final message = (await session.send(
        AonwDiplomacyRequest.sendMessage(
          expectedRevision: sender.stamp.revision,
          targetPlayerId: 'player-2',
          topic: AonwDiplomaticMessageTopic.avoidEscalation,
          messageId: 'message-private',
        ),
      )).require<AonwCommandResponse>().result;
      expect(message.accepted, isTrue);

      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-3'),
      );
      expect((await _snapshot(session)).diplomacy.messages, isEmpty);
      await session.send(
        AonwClientRequest.handoffActor(actorPlayerId: 'player-2'),
      );
      final finalSnapshot = await _snapshot(session);
      expect(finalSnapshot.diplomacy.messages.single.id, 'message-private');

      final save = (await session.send(
        AonwClientRequest.exportSave(),
      )).require<AonwSaveExportedResponse>().document;
      final replay = (await session.send(
        AonwClientRequest.exportReplay(),
      )).require<AonwReplayExportedResponse>().document;
      final reopened = (await session.send(
        AonwClientRequest.openSave(
          mapDocument: mapDocument,
          saveDocument: save,
        ),
      )).require<AonwSaveOpenedResponse>().stamp;
      expect(reopened.stateDigest, finalSnapshot.stamp.stateDigest);
      final verified = (await session.send(
        AonwClientRequest.verifyReplay(
          mapDocument: mapDocument,
          replayDocument: replay,
        ),
      )).require<AonwReplayVerifiedResponse>().verification;
      expect(verified.entryCount, 3);
      expect(verified.finalStamp.stateDigest, finalSnapshot.stamp.stateDigest);
    },
  );
}

Future<AonwPlayerViewSnapshot> _snapshot(AonwEngineSession session) async =>
    (await session.send(
      AonwClientRequest.snapshot(),
    )).require<AonwSnapshotResponse>().snapshot;

final _scenarioDocument = jsonEncode(const {
  'schemaVersion': 1,
  'scenarioId': 'flutter-diplomacy-smoke',
  'mapId': 'aonw2_starter',
  'rulesetId': 'aonw-standard',
  'initialUnits': [
    {
      'id': 'unit-1',
      'ownerPlayerId': 'player-1',
      'kind': 'commander',
      'name': 'One',
      'col': 1,
      'row': 1,
    },
    {
      'id': 'unit-2',
      'ownerPlayerId': 'player-2',
      'kind': 'commander',
      'name': 'Two',
      'col': 3,
      'row': 3,
    },
    {
      'id': 'unit-3',
      'ownerPlayerId': 'player-3',
      'kind': 'commander',
      'name': 'Three',
      'col': 5,
      'row': 5,
    },
  ],
});

final _matchIdentity = testMatchIdentity(playerCount: 3);
