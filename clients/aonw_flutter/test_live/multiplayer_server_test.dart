import 'dart:io';

import 'package:aonw_flutter/features/multiplayer/infrastructure/auth_token_store.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/multiplayer_match_document_source.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/server_connection_config.dart';
import 'package:aonw_flutter/features/multiplayer/infrastructure/serverpod_multiplayer_session.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runs the packaged multiplayer journey through Serverpod and engine',
    () async {
      const host = String.fromEnvironment('AONW_MULTIPLAYER_TEST_HOST');
      expect(host, isNotEmpty, reason: 'Pass AONW_MULTIPLAYER_TEST_HOST.');
      final config = ServerConnectionConfig.checked(
        source: host,
        platform: 'macos',
        buildNumber: 1,
        isRelease: false,
        requestTimeout: const Duration(seconds: 10),
      );
      final ownerTokens = _MemoryTokenStore();
      final guestTokens = _MemoryTokenStore();
      final owner = ServerpodMultiplayerSession(
        config: config,
        tokenStore: ownerTokens,
      );
      final guest = ServerpodMultiplayerSession(
        config: config,
        tokenStore: guestTokens,
      );
      addTearDown(owner.close);
      addTearDown(guest.close);
      final runId = DateTime.now().toUtc().microsecondsSinceEpoch;
      final password = 'AonwFlutter-$runId-password';

      final ownerAccount = await owner.createAccount(
        email: 'flutter-owner-$runId@example.test',
        password: password,
        displayName: 'Flutter Owner',
      );
      final guestAccount = await guest.createAccount(
        email: 'flutter-guest-$runId@example.test',
        password: password,
        displayName: 'Flutter Guest',
      );
      expect(ownerAccount.userId, isNot(guestAccount.userId));
      expect(ownerTokens.value, isNotEmpty);
      expect(guestTokens.value, isNotEmpty);

      final documents = await AssetMultiplayerMatchDocumentSource(
        assets: _FileAssetBundle(),
      ).load(MultiplayerMatchSetupView.defaults);
      final ownerLobby = await owner.createMatch(documents);
      final guestLobby = await guest.joinMatch(
        matchId: ownerLobby.match.matchId,
        playerId: 'player-2',
      );
      expect(ownerLobby.currentParticipant.playerId, 'player-1');
      expect(guestLobby.currentParticipant.playerId, 'player-2');
      await owner.setReady(matchId: ownerLobby.match.matchId, ready: true);
      await guest.setReady(matchId: ownerLobby.match.matchId, ready: true);
      final readyLobby = await owner.lobby(ownerLobby.match.matchId);
      expect(readyLobby.canStart, isTrue);
      final startedLobby = await owner.startMatch(ownerLobby.match.matchId);
      expect(startedLobby.match.phase.name, 'running');
      final ownerInitial = await owner.resync(ownerLobby.match.matchId);
      final guestInitial = await guest.resync(ownerLobby.match.matchId);
      expect(ownerInitial.playerId, 'player-1');
      expect(guestInitial.playerId, 'player-2');
      expect(ownerInitial.visibleUnitCount, greaterThan(0));
      expect(guestInitial.visibleUnitCount, greaterThan(0));

      const commandId = '00000000-0000-4000-8000-000000000001';
      final ownerCommand = await owner.submitTurn(
        matchId: ownerInitial.matchId,
        clientCommandId: commandId,
        expectedRevision: ownerInitial.revision,
      );
      final ownerDuplicate = await owner.submitTurn(
        matchId: ownerInitial.matchId,
        clientCommandId: commandId,
        expectedRevision: ownerInitial.revision,
      );
      expect(ownerCommand.accepted, isTrue);
      expect(ownerCommand.duplicate, isFalse);
      expect(ownerDuplicate.duplicate, isTrue);
      expect(ownerDuplicate.finalEventOffset, ownerCommand.finalEventOffset);

      final previousGuestToken = guestTokens.value;
      await guest.reconnect();
      expect(guestTokens.value, isNot(previousGuestToken));
      final guestSynchronized = await guest.resync(ownerInitial.matchId);
      expect(guestSynchronized.revision, ownerCommand.projection.revision);
      expect(guestSynchronized.eventOffset, ownerCommand.finalEventOffset);

      final guestCommand = await guest.submitTurn(
        matchId: ownerInitial.matchId,
        clientCommandId: '00000000-0000-4000-8000-000000000002',
        expectedRevision: guestSynchronized.revision,
      );
      expect(guestCommand.accepted, isTrue);
      final ownerSynchronized = await owner.resync(ownerInitial.matchId);
      expect(ownerSynchronized.revision, guestCommand.projection.revision);
      expect(ownerSynchronized.eventOffset, guestCommand.finalEventOffset);
      expect(
        (await owner.listMatches()).map((match) => match.matchId),
        contains(ownerInitial.matchId),
      );
      expect(
        (await guest.listMatches()).map((match) => match.matchId),
        contains(ownerInitial.matchId),
      );
    },
  );
}

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

final class _MemoryTokenStore implements AuthTokenStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> readRefreshToken() async => value;

  @override
  Future<void> writeRefreshToken(String next) async => value = next;
}
