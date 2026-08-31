import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native replay reaches the exact recorded final digest', () async {
    final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
    addTearDown(gateway.close);
    final assets = LocalGameCatalog.entries.first.assets;
    final replay = gateway.replaySession;
    final initial = await gateway.startLocalMatch(_setup());
    final turn = await gateway.endTurn(
      expectedRevision: initial.player.stamp.revision,
    );
    expect(turn.accepted, isTrue);
    final finalDigest = turn.player!.stamp.stateDigest;
    final document = await replay.exportReplayDocument();

    final opened = await replay.openReplayDocument(
      assets: assets,
      document: document,
    );
    expect(opened.position, 0);
    expect(opened.entryCount, greaterThan(0));
    final finalFrame = await replay.seekReplay(opened.entryCount);

    expect(finalFrame.position, opened.entryCount);
    expect(finalFrame.scene.player.stamp.stateDigest, finalDigest);
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
