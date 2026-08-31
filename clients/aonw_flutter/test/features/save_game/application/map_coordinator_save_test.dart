import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/replay/application/replay_capture.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'stores the authoritative Rust document and publishes success',
    () async {
      final gameplay = FakeGameSession.success(testMapScene());
      final saveSession = _FakeSaveSession(exported: '{"rust":"save"}');
      final store = _MemorySaveStore();
      final replay = _ReplayCapture();
      final coordinator = _coordinator(gameplay, saveSession, store, replay);
      addTearDown(coordinator.dispose);
      await coordinator.startLocalMatch(_entry, _setup());

      coordinator.saveLocalGame();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final ready = coordinator.state as GameSessionReady;
      expect(saveSession.exportCalls, 1);
      expect(store.primary, '{"rust":"save"}');
      expect(replay.entries, [_entry]);
      expect(ready.localSave.phase, LocalSavePhase.saved);
    },
  );

  test(
    'tries the backup in a candidate before replacing the open game',
    () async {
      final original = testMapScene();
      final restored = testMapScene(mapId: 'restored-map');
      final gameplay = FakeGameSession.success(original);
      final saveSession = _FakeSaveSession(
        exported: '{}',
        opened: restored,
        validDocument: 'valid-backup',
      );
      final store = _MemorySaveStore(
        primary: 'truncated-primary',
        backup: 'valid-backup',
      );
      final coordinator = _coordinator(gameplay, saveSession, store);
      addTearDown(coordinator.dispose);
      await coordinator.startLocalMatch(_entry, _setup());

      final result = await coordinator.resumeLatestLocalGame();

      expect(result.started, isTrue);
      expect(saveSession.openedDocuments, [
        'truncated-primary',
        'valid-backup',
      ]);
      expect((coordinator.state as GameSessionReady).scene, same(restored));
    },
  );

  test('keeps the open game when every save candidate is rejected', () async {
    final original = testMapScene();
    final gameplay = FakeGameSession.success(original);
    final saveSession = _FakeSaveSession(
      exported: '{}',
      validDocument: 'never',
    );
    final store = _MemorySaveStore(primary: 'corrupt');
    final coordinator = _coordinator(gameplay, saveSession, store);
    addTearDown(coordinator.dispose);
    await coordinator.startLocalMatch(_entry, _setup());
    final before = coordinator.state;

    final result = await coordinator.resumeLatestLocalGame();

    expect(result.started, isFalse);
    expect(result.failure, LocalResumeFailureViewCode.incompatible);
    expect(coordinator.state, same(before));
  });
}

MapCoordinator _coordinator(
  FakeGameSession gameplay,
  GameSaveSessionPort saveSession,
  LocalSaveStore store, [
  ReplayCapture? replayCapture,
]) => MapCoordinator(
  capabilities: testGameSessionCapabilities(gameplay, save: saveSession),
  saveStore: store,
  replayCapture: replayCapture,
);

const _assets = MapAssetPaths(
  document: 'map',
  bundleManifest: 'manifest',
  scenarioDocument: 'scenario',
  actorPlayerId: 'player-1',
);

const _entry = LocalGameCatalogEntryView(
  id: LocalGameScenarioView.starterDuel,
  assets: _assets,
  aiPlayerIds: ['player-2'],
);

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: _assets,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player',
      colorValue: 1,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'AI',
      colorValue: 2,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 7),
    ),
  ],
  fogEnabled: true,
);

final class _FakeSaveSession implements GameSaveSessionPort {
  _FakeSaveSession({required this.exported, this.opened, this.validDocument});

  final String exported;
  final MapScene? opened;
  final String? validDocument;
  final openedDocuments = <String>[];
  var exportCalls = 0;

  @override
  Future<String> exportSaveDocument() async {
    exportCalls += 1;
    return exported;
  }

  @override
  Future<MapScene> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    openedDocuments.add(document);
    if (document != validDocument || opened == null) {
      throw const GameSaveSessionException(
        code: 'invalid_save',
        message: 'Invalid save.',
      );
    }
    return opened!;
  }
}

final class _MemorySaveStore implements LocalSaveStore {
  _MemorySaveStore({this.primary, this.backup});

  String? primary;
  String? backup;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      primary != null || backup != null;

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) async => switch (copy) {
    LocalSaveCopyView.primary => primary,
    LocalSaveCopyView.backup => backup,
  };

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {
    backup = primary;
    primary = document;
  }
}

final class _ReplayCapture implements ReplayCapture {
  final entries = <LocalGameCatalogEntryView>[];

  @override
  Future<void> captureReplay(LocalGameCatalogEntryView entry) async {
    entries.add(entry);
  }
}
