import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native replay reaches the exact recorded final digest', () async {
    final gateway = EngineGameSessionGateway(assets: _FileAssetBundle());
    addTearDown(gateway.close);
    final assets = LocalGameCatalog.entries.first.assets;
    final replay = gateway.replaySession;
    final initial = await gateway.startLocalMatch(_setup());
    final turn = await gateway.endTurn(
      expectedRevision: initial.player.stamp.revision,
    );
    expect(turn.accepted, isTrue);
    final ai = await gateway.advanceAiTurn(
      LocalAiTurnRequestView(aiPlayerId: 'player-2', humanPlayerId: 'player-1'),
    );
    final finalDigest = ai.player.stamp.stateDigest;
    final document = await replay.exportReplayDocument();

    final opened = await replay.openReplayDocument(
      assets: assets,
      document: document,
    );
    expect(opened.position, 0);
    expect(opened.entryCount, greaterThan(1));
    expect(opened.command, isNull);
    expect(opened.scene.player.recentFeedback, isEmpty);
    for (var position = 1; position <= opened.entryCount; position++) {
      final frame = await replay.seekReplay(position);
      expect(frame.command, isNotNull);
      expect(frame.command!.player, same(frame.scene.player));
      expect(frame.scene.player.actorPlayerId, assets.actorPlayerId);
    }
    final repeated = await replay.seekReplay(opened.entryCount);
    expect(repeated.command, isNull);
    expect(repeated.scene.player.recentFeedback, isEmpty);
    final restarted = await replay.seekReplay(0);
    expect(restarted.command, isNull);
    expect(restarted.scene.player.recentFeedback, isEmpty);
    final finalFrame = await replay.seekReplay(opened.entryCount);

    expect(finalFrame.position, opened.entryCount);
    expect(finalFrame.scene.player.stamp.stateDigest, finalDigest);
    expect(finalFrame.command, isNull);
    expect(finalFrame.scene.player.recentFeedback, isEmpty);
  });
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
  fogEnabled: false,
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
