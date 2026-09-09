import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:aonw_flutter/features/save_game/infrastructure/atomic_local_save_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final sample in [
    (mode: LocalTurnModeView.sequential, hotseat: false),
    (mode: LocalTurnModeView.simultaneous, hotseat: false),
    (mode: LocalTurnModeView.sequential, hotseat: true),
  ]) {
    test('native autosave restores exact state for $sample', () async {
      final root = await Directory.systemTemp.createTemp(
        'aonw-native-autosave-',
      );
      addTearDown(() => root.delete(recursive: true));
      final gateway = EngineGameSessionGateway(assets: _Files());
      final store = AtomicLocalSaveStore(rootDirectory: () async => root);
      final coordinator = MapCoordinator(
        capabilities: gateway.capabilities,
        saveStore: store,
      );
      addTearDown(coordinator.dispose);
      final entry = LocalGameCatalog.entries.first;
      expect(
        await coordinator.startLocalMatch(
          entry,
          _setup(sample.mode, sample.hotseat),
        ),
        isTrue,
      );
      final saving = coordinator.changes.firstWhere(
        (state) =>
            state is GameSessionReady &&
            [
              LocalSavePhase.saved,
              LocalSavePhase.failed,
            ].contains(state.localSave.phase),
      );
      coordinator.endTurn();
      final saved = await saving as GameSessionReady;
      expect(saved.localSave.phase, LocalSavePhase.saved);
      expect(
        saved.localHandoff.phase,
        sample.hotseat
            ? LocalHandoffPhase.awaitingConfirmation
            : LocalHandoffPhase.idle,
      );
      final slots = await store.list();
      expect(slots, hasLength(1));
      expect(slots.single.automatic, isTrue);
      final document = (await store.read(
        slots.single,
        LocalSaveCopyView.primary,
      ))!;
      expect(document, await gateway.saveSession.exportSaveDocument());
      final other = EngineGameSessionGateway(assets: _Files());
      addTearDown(other.close);
      final restored = await other.saveSession.openSaveDocument(
        assets: entry.assets,
        document: document,
      );
      expect(
        restored.player.stamp.stateDigest,
        saved.recipient.stamp.stateDigest,
      );
      expect(restored.player.stamp.revision, saved.recipient.stamp.revision);
      expect(restored.player.turnMode, saved.recipient.turnMode);
      expect(restored.player.actorPlayerId, saved.recipient.actorPlayerId);
      expect(await other.saveSession.exportSaveDocument(), document);
      coordinator.confirmLocalHandoff();
      final manual = coordinator.changes.firstWhere(
        (state) =>
            state is GameSessionReady &&
            state.localSave.phase == LocalSavePhase.saved,
      );
      coordinator.saveLocalGame();
      await manual;
      final after = await store.list();
      expect(after, hasLength(2));
      expect(after.where((slot) => slot.automatic), hasLength(1));
      expect(
        await store.read(slots.single, LocalSaveCopyView.primary),
        document,
      );
    });
  }
}

LocalMatchSetupView _setup(LocalTurnModeView mode, bool hotseat) =>
    LocalMatchSetupView(
      assets: LocalGameCatalog.entries.first.assets,
      turnMode: mode,
      fogEnabled: true,
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
          name: 'Opponent',
          colorValue: 0xffee6c4d,
          country: LocalPlayerCountryView.japan,
          control: hotseat
              ? LocalPlayerControlView.human
              : LocalPlayerControlView.ai,
          ai: hotseat ? null : const LocalAiProfileView(seed: 42),
        ),
      ],
    );

final class _Files extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}
