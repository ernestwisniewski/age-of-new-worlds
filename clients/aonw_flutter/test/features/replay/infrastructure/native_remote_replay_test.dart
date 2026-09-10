import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/city_planning_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/serverpod_replay_transport.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'remote replay shares native map projection and exact command playback',
    () async {
      final assets = LocalGameCatalog.entries.first.assets;
      final gateway = EngineGameSessionGateway(assets: _Files());
      addTearDown(gateway.close);
      final initial = await gateway.startLocalMatch(_setup());
      await gateway.capabilities.turns.endTurn(
        expectedRevision: initial.player.stamp.revision,
      );
      final ai = await gateway.advanceAiTurn(
        LocalAiTurnRequestView(
          aiPlayerId: 'player-2',
          humanPlayerId: 'player-1',
        ),
      );
      final document = await gateway.replaySession.exportReplayDocument();
      final backend = (await createAonwEngineSession())!;
      final opened = await backend.send(
        AonwClientRequest.openReplay(
          mapDocument: await File(assets.document).readAsString(),
          replayDocument: document,
          recipientPlayerId: assets.actorPlayerId,
        ),
      );
      final initialFrame = opened.require<AonwReplayFrameResponse>();
      var frameReads = 0;
      final transport = ServerpodReplayTransport(
        matchId: 'online-archive',
        playerId: assets.actorPlayerId,
        mapHash: initialFrame.snapshot.stamp.mapHash,
        rulesetHash: initialFrame.snapshot.stamp.rulesetHash,
        frame: (position) async {
          frameReads++;
          final raw = await backend.requestJson(
            AonwClientRequest.seekReplay(position: position).toJson(),
          );
          final envelope = jsonDecode(raw) as Map;
          return server.GameReplayFrame(
            matchId: 'online-archive',
            playerId: assets.actorPlayerId,
            frameJson: jsonEncode(envelope['outcome']['response']),
          );
        },
        query: (request, position) async {
          final raw = await backend.requestJson(
            jsonEncode({
              'apiVersion': aonwClientApiVersion,
              'request': {
                'type': 'query',
                'query': jsonDecode(request.queryJson),
              },
            }),
          );
          final outcome = (jsonDecode(raw) as Map)['outcome'] as Map;
          final projected = outcome['status'] == 'failure'
              ? outcome
              : {'status': 'success', 'result': outcome['response']['result']};
          return server.GamePlayerQueryOutcome(
            matchId: request.matchId,
            outcomeJson: jsonEncode(projected),
          );
        },
        requireAuthorized: () {},
        release: () {},
      );
      addTearDown(backend.close);
      final remote = await gateway.startRemoteReplay(
        assets: assets,
        session: transport,
      );
      expect(frameReads, 1);
      expect(remote.position, 0);
      expect(remote.command, isNull);
      expect(
        remote.scene.player.stamp.stateDigest,
        initialFrame.snapshot.stamp.stateDigest,
      );
      for (var position = 1; position <= remote.entryCount; position++) {
        final frame = await gateway.replaySession.seekReplay(position);
        expect(frame.command, isNotNull);
        expect(frame.scene.player.actorPlayerId, assets.actorPlayerId);
      }
      final finalFrame = await gateway.replaySession.seekReplay(
        remote.entryCount,
      );
      expect(finalFrame.command, isNull);
      expect(
        finalFrame.scene.player.stamp.stateDigest,
        ai.player.stamp.stateDigest,
      );
      final planning = await gateway.replaySession
          .cityPlanning(
            expectedRevision: finalFrame.scene.player.stamp.revision,
          )
          .catchError((Object error) {
            if (error is CityPlanningSessionException) {
              fail('${error.code}: ${error.diagnosticCause}');
            }
            throw error;
          });
      expect(planning.stamp, finalFrame.scene.player.stamp);
      final back = await gateway.replaySession.seekReplay(0);
      expect(back.command, isNull);
      expect(back.scene.player.recentFeedback, isEmpty);
      await expectLater(
        gateway.replaySession.exportReplayDocument(),
        throwsA(isA<Exception>()),
      );
      final local = await gateway.replaySession.openReplayDocument(
        assets: assets,
        document: document,
      );
      expect(local.position, 0);
      expect(
        (await gateway.replaySession.seekReplay(
          local.entryCount,
        )).scene.player.stamp.stateDigest,
        ai.player.stamp.stateDigest,
      );
    },
  );
}

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: LocalGameCatalog.entries.first.assets,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player',
      colorValue: 0xff3d5a80,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'AI',
      colorValue: 0xffee6c4d,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 42),
    ),
  ],
  fogEnabled: true,
);

final class _Files extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}
