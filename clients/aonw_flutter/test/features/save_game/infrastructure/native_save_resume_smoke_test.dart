import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects invalid native saves without replacing the retained session',
    () async {
      final gateway = EngineGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      final saveSession = gateway.saveSession;
      final assets = LocalGameCatalog.entries.first.assets;
      final initial = await gateway.startLocalMatch(_setup());
      final save = await saveSession.exportSaveDocument();
      final mismatch = jsonDecode(save) as Map<String, dynamic>;
      mismatch['mapHash'] = 'f' * 64;
      final rulesetMismatch = jsonDecode(save) as Map<String, dynamic>;
      rulesetMismatch['rulesetHash'] = 'e' * 64;
      final behaviorMismatch = jsonDecode(save) as Map<String, dynamic>;
      behaviorMismatch['behaviorFingerprint'] = 'legacy-client';
      final digestMismatch = jsonDecode(save) as Map<String, dynamic>;
      digestMismatch['stateDigest'] = 'd' * 64;

      final inspected = await saveSession.inspectSaveDocument(
        assets: assets,
        document: save,
      );
      expect(
        inspected.player.stamp.stateDigest,
        initial.player.stamp.stateDigest,
      );
      expect(await saveSession.exportSaveDocument(), save);

      for (final rejected in [
        save.substring(0, save.length ~/ 2),
        jsonEncode(mismatch),
        jsonEncode(rulesetMismatch),
        jsonEncode(behaviorMismatch),
        jsonEncode(digestMismatch),
      ]) {
        await expectLater(
          saveSession.openSaveDocument(assets: assets, document: rejected),
          throwsA(isA<GameSaveSessionException>()),
        );
        expect(await saveSession.exportSaveDocument(), save);
      }

      final restored = await saveSession.openSaveDocument(
        assets: assets,
        document: save,
      );
      expect(restored.player.stamp.revision, initial.player.stamp.revision);
      expect(
        restored.player.stamp.stateDigest,
        initial.player.stamp.stateDigest,
      );
      expect(restored.player.stamp.mapHash, initial.player.stamp.mapHash);
      expect(
        restored.player.stamp.rulesetHash,
        initial.player.stamp.rulesetHash,
      );
      expect(await saveSession.exportSaveDocument(), save);
    },
  );

  test(
    'reopens an exact authoritative save after the native session closes',
    () async {
      final first = EngineGameSessionGateway(assets: _FileAssetBundle());
      final initial = await first.startLocalMatch(_setup());
      final humanTurn = await first.endTurn(
        expectedRevision: initial.player.stamp.revision,
      );
      expect(humanTurn.accepted, isTrue);
      final aiTurn = await first.advanceAiTurn(
        LocalAiTurnRequestView(
          aiPlayerId: 'player-2',
          humanPlayerId: 'player-1',
        ),
      );
      final document = await first.saveSession.exportSaveDocument();
      final expected = aiTurn.player.stamp;
      await first.close();

      final reopened = EngineGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(reopened.close);
      final restored = await reopened.saveSession.openSaveDocument(
        assets: LocalGameCatalog.entries.first.assets,
        document: document,
      );

      expect(restored.player.stamp.revision, expected.revision);
      expect(restored.player.stamp.stateDigest, expected.stateDigest);
      expect(restored.player.stamp.mapHash, expected.mapHash);
      expect(restored.player.stamp.rulesetHash, expected.rulesetHash);
      expect(await reopened.saveSession.exportSaveDocument(), document);
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
  fogEnabled: false,
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
