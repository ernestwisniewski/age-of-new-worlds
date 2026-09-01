import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/replay/application/replay_capture.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'stores the authoritative engine document and publishes success',
    () async {
      final gameplay = FakeGameSession.success(testMapScene());
      final saveSession = _FakeSaveSession(exported: '{"engine":"save"}');
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
      expect(store.primary, '{"engine":"save"}');
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

  test('indexes a validated save without replacing the open game', () async {
    final original = testMapScene();
    final inspected = testMapScene().withPlayer(
      PlayerMapView.preview(
        actorPlayerId: 'player-1',
        stamp: testSessionStamp(revision: 6),
        turnMode: MatchTurnModeView.simultaneous,
        turn: 9,
        pendingAction: null,
        units: const [],
      ),
    );
    final saveSession = _FakeSaveSession(
      exported: '{}',
      opened: inspected,
      validDocument: 'valid-save',
    );
    final coordinator = _coordinator(
      FakeGameSession.success(original),
      saveSession,
      _MemorySaveStore(
        primary: 'valid-save',
        scenario: LocalGameScenarioView.starterDuel,
      ),
    );
    addTearDown(coordinator.dispose);
    await coordinator.startLocalMatch(_entry, _setup());

    final summaries = await coordinator.listLocalSaves();

    expect(summaries, hasLength(1));
    expect(summaries.single.scenario, LocalGameScenarioView.starterDuel);
    expect(summaries.single.gameMode, LocalSaveGameModeView.singlePlayer);
    expect(summaries.single.turnMode, MatchTurnModeView.simultaneous);
    expect(summaries.single.turn, 9);
    expect(saveSession.inspectedDocuments, ['valid-save']);
    expect((coordinator.state as GameSessionReady).scene, same(original));
  });

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

  test('resumes only the explicitly selected scenario slot', () async {
    final restored = testMapScene(mapId: 'dravonia');
    final saveSession = _FakeSaveSession(
      exported: '{}',
      opened: restored,
      validDocument: 'dravonia-save',
    );
    final coordinator = _coordinator(
      FakeGameSession.success(testMapScene()),
      saveSession,
      _MemorySaveStore(
        primary: 'dravonia-save',
        scenario: LocalGameScenarioView.dravonia,
      ),
    );
    addTearDown(coordinator.dispose);

    final result = await coordinator.resumeLocalGame(
      LocalGameScenarioView.dravonia,
    );

    expect(result.started, isTrue);
    expect(saveSession.openedDocuments, ['dravonia-save']);
    expect((coordinator.state as GameSessionReady).scene, same(restored));
  });

  test('keeps a restored hotseat recipient behind a privacy gate', () async {
    final restored = testMapScene().withPlayer(
      PlayerMapView.preview(
        actorPlayerId: 'player-2',
        stamp: testSessionStamp(revision: 8),
        turn: 4,
        pendingAction: null,
        units: const [],
      ),
    );
    final hotseatPlan = LocalMatchControlPlanView([
      LocalParticipantControlView(
        id: 'player-1',
        name: 'Player 1',
        control: LocalPlayerControlView.human,
      ),
      LocalParticipantControlView(
        id: 'player-2',
        name: 'Player 2',
        control: LocalPlayerControlView.human,
      ),
    ]);
    final saveSession = _FakeSaveSession(
      exported: '{}',
      opened: restored,
      validDocument: 'hotseat-save',
      controlPlan: hotseatPlan,
    );
    final coordinator = _coordinator(
      FakeGameSession.success(testMapScene()),
      saveSession,
      _MemorySaveStore(primary: 'hotseat-save'),
    );
    addTearDown(coordinator.dispose);

    final result = await coordinator.resumeLatestLocalGame();

    final ready = coordinator.state as GameSessionReady;
    expect(result.started, isTrue);
    expect(ready.recipient.actorPlayerId, 'player-2');
    expect(ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);
    expect(ready.localHandoff.playerName, 'Player 2');
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
  mapId: 'map',
  rulesetId: 'ruleset',
  columns: 7,
  rows: 7,
  maximumPlayers: 2,
  participantIds: ['player-1', 'player-2'],
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
  _FakeSaveSession({
    required this.exported,
    this.opened,
    this.validDocument,
    this.controlPlan,
  });

  final String exported;
  final MapScene? opened;
  final String? validDocument;
  final LocalMatchControlPlanView? controlPlan;
  final openedDocuments = <String>[];
  final inspectedDocuments = <String>[];
  var exportCalls = 0;

  @override
  Future<String> exportSaveDocument() async {
    exportCalls += 1;
    return exported;
  }

  @override
  Future<OpenedGameSaveView> inspectSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) {
    inspectedDocuments.add(document);
    return _open(document);
  }

  @override
  Future<OpenedGameSaveView> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    openedDocuments.add(document);
    return _open(document);
  }

  Future<OpenedGameSaveView> _open(String document) async {
    if (document != validDocument || opened == null) {
      throw const GameSaveSessionException(
        code: 'invalid_save',
        message: 'Invalid save.',
      );
    }
    return OpenedGameSaveView(
      scene: opened!,
      controlPlan: controlPlan ?? _setup().controlPlan,
    );
  }
}

final class _MemorySaveStore implements LocalSaveStore {
  _MemorySaveStore({
    this.primary,
    this.backup,
    this.scenario = LocalGameScenarioView.starterDuel,
  });

  String? primary;
  String? backup;
  final LocalGameScenarioView scenario;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      scenario == this.scenario && (primary != null || backup != null);

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) async {
    if (scenario != this.scenario) return null;
    return switch (copy) {
      LocalSaveCopyView.primary => primary,
      LocalSaveCopyView.backup => backup,
    };
  }

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
