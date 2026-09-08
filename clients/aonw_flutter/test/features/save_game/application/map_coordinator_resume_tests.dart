part of 'map_coordinator_save_test.dart';

void resumeMapViewTests() {
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

      coordinator.readInitialMapViewMode = () async => MapViewMode.tile;
      final result = await coordinator.resumeLatestLocalGame();

      expect(result.started, isTrue);
      expect(saveSession.openedDocuments, [
        'truncated-primary',
        'valid-backup',
      ]);
      expect((coordinator.state as GameSessionReady).scene, same(restored));
      expect(
        (coordinator.state as GameSessionReady).interaction.viewMode,
        MapViewMode.tile,
      );
    },
  );
}
