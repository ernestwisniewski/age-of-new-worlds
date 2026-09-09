import 'dart:async';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:aonw_flutter/features/save_game/application/local_autosave_store.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_state.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final simultaneous in [false, true]) {
    test('autosaves after AI finishes, simultaneous=$simultaneous', () async {
      final h = _Harness(simultaneous: simultaneous);
      addTearDown(h.coordinator.dispose);
      await h.start();
      h.save.onExport = () {
        expect(h.game.aiTurnCalls, 1);
        expect(h.ready.recipient.stamp.revision, 2);
      };
      final saved = h.coordinator.changes.firstWhere(
        (state) =>
            state is GameSessionReady &&
            state.localSave.phase == LocalSavePhase.saved,
      );
      h.coordinator.endTurn();
      await saved;
      expect(h.store.documents, ['engine-save']);
      expect(
        h.store.modes.single,
        simultaneous
            ? MatchTurnModeView.simultaneous
            : MatchTurnModeView.sequential,
      );
      expect(h.store.privateHandoffs.single, isFalse);
      expect(h.store.manualWrites, 0);
      await pumpEventQueue();
      expect(h.store.documents, hasLength(1));
    });
  }

  test('hotseat saves behind the private handoff without opening it', () async {
    final h = _Harness(hotseat: true);
    addTearDown(h.coordinator.dispose);
    await h.start();
    final saved = h.coordinator.changes.firstWhere(
      (state) =>
          state is GameSessionReady &&
          state.localSave.phase == LocalSavePhase.saved,
    );
    h.coordinator.endTurn();
    await saved;
    expect(h.ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);
    expect(h.ready.recipient.actorPlayerId, 'player-2');
    expect(h.store.privateHandoffs, [true]);
    expect(h.game.aiTurnCalls, 0);
  });

  test(
    'a superseding load discards an export before it reaches storage',
    () async {
      final h = _Harness();
      addTearDown(h.coordinator.dispose);
      await h.start();
      h.save.pending = Completer<String>();
      final exporting = Completer<void>();
      h.save.onExport = exporting.complete;
      h.coordinator.endTurn();
      await exporting.future;
      await h.start();
      h.save.pending!.complete('obsolete-save');
      await pumpEventQueue();
      expect(h.store.documents, isEmpty);
      expect(h.ready.localSave.phase, LocalSavePhase.idle);
    },
  );

  test('a rejected turn does not trigger autosave', () async {
    final h = _Harness(reject: true);
    addTearDown(h.coordinator.dispose);
    await h.start();
    h.coordinator.endTurn();
    await pumpEventQueue();
    expect(h.game.endTurnCalls, 1);
    expect(h.save.exports, 0);
    expect(h.store.documents, isEmpty);
  });

  test(
    'storage failure remains visible without rolling back the turn',
    () async {
      final h = _Harness();
      addTearDown(h.coordinator.dispose);
      h.store.fail = true;
      await h.start();
      final failed = h.coordinator.changes.firstWhere(
        (state) =>
            state is GameSessionReady &&
            state.localSave.phase == LocalSavePhase.failed,
      );
      h.coordinator.endTurn();
      await failed;
      expect(h.ready.recipient.stamp.revision, 2);
      expect(h.ready.localSave.failure, LocalSaveFailureViewCode.writeFailed);
      expect(h.game.endTurnCalls, 1);
    },
  );
}

final class _Harness {
  _Harness({
    this.simultaneous = false,
    this.hotseat = false,
    bool reject = false,
  }) {
    final initial = _player('player-1', 0);
    game = FakeGameSession.success(
      testMapScene(cols: 7, rows: 7).withPlayer(initial),
      turnResult: reject
          ? const TurnCommandResultView.rejected(
              code: TurnRejectionCodeView.staleRevision,
            )
          : TurnCommandResultView.accepted(
              player: _player('player-1', 1),
              activities: const [],
              evidence: null,
            ),
      aiTurnResults: [
        LocalAiTurnExecutionView(
          aiPlayerId: 'player-2',
          executedCommands: 1,
          completedTurn: true,
          player: _player('player-1', 2),
        ),
      ],
      handoffPlayers: {'player-2': _player('player-2', 2)},
    );
    coordinator = MapCoordinator(
      capabilities: testGameSessionCapabilities(game, save: save),
      saveStore: store,
    );
  }
  final bool simultaneous;
  final bool hotseat;
  late final FakeGameSession game;
  late final MapCoordinator coordinator;
  final save = _SaveSession();
  final store = _Store();
  GameSessionReady get ready => coordinator.state as GameSessionReady;
  final entry = LocalGameCatalog.entries.first;

  Future<bool> start() => coordinator.startLocalMatch(
    entry,
    LocalMatchSetupView(
      assets: entry.assets,
      fogEnabled: true,
      turnMode: simultaneous
          ? LocalTurnModeView.simultaneous
          : LocalTurnModeView.sequential,
      participants: [
        for (final id in ['player-1', 'player-2'])
          LocalParticipantSetupView(
            id: id,
            name: id,
            colorValue: 0xffaabbcc,
            country: LocalPlayerCountryView.poland,
            control: id == 'player-1' || hotseat
                ? LocalPlayerControlView.human
                : LocalPlayerControlView.ai,
            ai: id == 'player-1' || hotseat
                ? null
                : const LocalAiProfileView(seed: 1),
          ),
      ],
    ),
  );

  PlayerMapView _player(String actor, int revision) => PlayerMapView.preview(
    actorPlayerId: actor,
    stamp: testSessionStamp(revision: revision),
    turnMode: simultaneous
        ? MatchTurnModeView.simultaneous
        : MatchTurnModeView.sequential,
    turn: revision + 1,
    pendingAction: null,
    units: const [],
  );
}

final class _SaveSession implements GameSaveSessionPort {
  Completer<String>? pending;
  void Function()? onExport;
  int exports = 0;
  @override
  Future<String> exportSaveDocument() {
    exports++;
    onExport?.call();
    return pending?.future ?? Future.value('engine-save');
  }

  @override
  Future<OpenedGameSaveView> inspectSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) => throw UnimplementedError();
  @override
  Future<OpenedGameSaveView> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) => throw UnimplementedError();
}

final class _Store implements LocalSaveStore, LocalAutosaveStore {
  final documents = <String>[];
  final modes = <MatchTurnModeView>[];
  final privateHandoffs = <bool>[];
  int manualWrites = 0;
  bool fail = false;
  @override
  Future<LocalSaveSlotView> writeAutomatic({
    required LocalGameScenarioView scenario,
    required bool privateHandoff,
    required MatchTurnModeView turnMode,
    required String document,
  }) async {
    if (fail) {
      throw const LocalSaveStoreException(
        code: 'disk_full',
        message: 'No space',
      );
    }
    documents.add(document);
    modes.add(turnMode);
    privateHandoffs.add(privateHandoff);
    return LocalSaveSlotView(
      id: 'automatic',
      scenario: scenario,
      automatic: true,
      savedAt: DateTime.utc(2026),
    );
  }

  @override
  Future<List<LocalSaveSlotView>> list() async => const [];
  @override
  Future<String?> read(LocalSaveSlotView slot, LocalSaveCopyView copy) async =>
      null;
  @override
  Future<LocalSaveSlotView> create({
    required LocalGameScenarioView scenario,
    required String? name,
    required String document,
  }) {
    manualWrites++;
    return Future.value(
      LocalSaveSlotView(
        id: 'manual',
        scenario: scenario,
        savedAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Future<LocalSaveSlotView> write(
    LocalSaveSlotView slot,
    String document,
  ) async {
    manualWrites++;
    return slot;
  }
}
