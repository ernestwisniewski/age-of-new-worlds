import 'dart:async';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_frame_view.dart';
import 'package:aonw_flutter/features/replay/application/local_replay_store.dart';
import 'package:aonw_flutter/features/replay/application/replay_session_port.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_screen.dart';
import 'package:aonw_flutter/features/replay/read_model/replay_frame_view.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_controller.dart';
import 'package:aonw_flutter/features/settings/presentation/client_settings_scope.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'replay applies animation settings live without changing its frame',
    (tester) async {
      final session = _ReplaySession();
      final controller = ReplayPresentationController(
        session: session,
        store: _ReplayStore(primary: 'valid'),
      );
      final settings = ClientSettingsController.ephemeral();
      final game = AonwFlameGame();
      addTearDown(controller.dispose);
      addTearDown(settings.dispose);
      await controller.openLatest();
      await settings.update(
        settings.settings.copyWith(showCombatAnimations: false),
      );
      await tester.pumpWidget(
        LocalizedTestApp(
          home: ClientSettingsScope(
            controller: settings,
            child: ReplayScreen(
              controller: controller,
              flameGameFactory: () => game,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final host = game.world.effectHost;
      final sceneWrites = game.world.debugSceneWriteCount;
      expect(host.combatAnimationsEnabled, isFalse);
      expect(host.movementAnimationsEnabled, isTrue);
      expect(game.world.unitLayer.idleAnimationsEnabled, isTrue);
      await settings.update(
        settings.settings.copyWith(
          showUnitMovementAnimations: false,
          showUnitIdleAnimations: false,
        ),
      );
      await tester.pump();
      expect(host.movementAnimationsEnabled, isFalse);
      expect(game.world.unitLayer.idleAnimationsEnabled, isFalse);
      expect(host.combatAnimationsEnabled, isFalse);
      expect(game.world.debugSceneWriteCount, sceneWrites);
      expect(session.positions, isEmpty);
      await settings.reset();
      await tester.pump();
      expect(host.movementAnimationsEnabled, isTrue);
      expect(game.world.unitLayer.idleAnimationsEnabled, isTrue);
      expect(host.combatAnimationsEnabled, isTrue);
    },
  );

  testWidgets(
    'speed changes wait for active effects and pause prevents rescheduling',
    (tester) async {
      final session = _ReplaySession(observed: true);
      final controller = ReplayPresentationController(
        session: session,
        store: _ReplayStore(primary: 'valid'),
      );
      addTearDown(controller.dispose);
      final effects = Completer<void>();
      controller.waitForCommandEffects = () => effects.future;
      await controller.openLatest();
      controller.play();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(session.positions, [1]);
      controller.cycleSpeed();
      await tester.pump(const Duration(seconds: 3));
      expect(session.positions, [1]);
      controller.pause();
      effects.complete();
      await tester.pump(const Duration(seconds: 3));
      expect(session.positions, [1]);
      controller.play();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(session.positions, [1, 2]);
      controller.pause();
    },
  );

  testWidgets('pause and speed changes survive an in-flight replay response', (
    tester,
  ) async {
    final session = _ReplaySession(observed: true)
      ..seekCompletion = Completer<void>();
    final controller = ReplayPresentationController(
      session: session,
      store: _ReplayStore(primary: 'valid'),
    );
    addTearDown(controller.dispose);
    await controller.openLatest();
    controller.play();
    await tester.pump(const Duration(milliseconds: 800));
    expect((controller.state as ReplayReady).isSeeking, isTrue);
    controller.pause();
    controller.cycleSpeed();
    session.seekCompletion!.complete();
    await tester.pump();
    final ready = controller.state as ReplayReady;
    expect(ready.frame.position, 1);
    expect(ready.speed, ReplaySpeedView.twoTimes);
    expect(ready.isPlaying, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(session.positions, [1]);
  });

  testWidgets('a jump supersedes an older frame waiting for effects', (
    tester,
  ) async {
    final session = _ReplaySession(observed: true);
    final controller = ReplayPresentationController(
      session: session,
      store: _ReplayStore(primary: 'valid'),
    );
    addTearDown(controller.dispose);
    final effects = Completer<void>();
    controller.waitForCommandEffects = () => effects.future;
    await controller.openLatest();
    controller.play();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    controller.seek(3);
    await tester.pump();
    effects.complete();
    await tester.pump(const Duration(seconds: 2));
    expect((controller.state as ReplayReady).frame.position, 3);
    expect((controller.state as ReplayReady).isPlaying, isFalse);
    expect(session.positions, [1, 3]);
  });

  testWidgets('captures, opens, seeks, changes speed, and plays in order', (
    tester,
  ) async {
    final session = _ReplaySession();
    final store = _ReplayStore();
    final controller = ReplayPresentationController(
      session: session,
      store: store,
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    await controller.captureReplay(LocalGameCatalog.entries.first);
    expect(store.document, 'engine-replay');
    expect(await controller.hasReplay(), isTrue);
    expect((await controller.openLatest()).started, isTrue);
    expect((controller.state as ReplayReady).frame.position, 0);

    controller.seek(2);
    await tester.pump();
    expect((controller.state as ReplayReady).frame.position, 2);

    controller.cycleSpeed();
    controller.cycleSpeed();
    expect((controller.state as ReplayReady).speed, ReplaySpeedView.fourTimes);
    controller.play();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    final completed = controller.state as ReplayReady;
    expect(completed.frame.position, 3);
    expect(completed.isPlaying, isFalse);
    expect(session.positions, [2, 3]);
  });

  test('falls back from corrupt primary to current backup', () async {
    final session = _ReplaySession(rejectDocument: 'corrupt');
    final store = _ReplayStore(primary: 'corrupt', backup: 'valid');
    final controller = ReplayPresentationController(
      session: session,
      store: store,
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    expect((await controller.openLatest()).started, isTrue);
    expect(session.openedDocuments, ['corrupt', 'valid']);
    expect(controller.state, isA<ReplayReady>());
  });

  test('opens only the replay selected by its scenario', () async {
    final session = _ReplaySession();
    final store = _ReplayStore(
      primary: 'dravonia-replay',
      scenario: LocalGameScenarioView.dravonia,
    );
    final controller = ReplayPresentationController(
      session: session,
      store: store,
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    expect(
      (await controller.open(LocalGameScenarioView.starterDuel)).failure,
      ReplayFailureViewCode.missing,
    );
    expect(session.openedDocuments, isEmpty);
    expect(
      (await controller.open(LocalGameScenarioView.dravonia)).started,
      isTrue,
    );
    expect(session.openedDocuments, ['dravonia-replay']);
  });
}

final class _ReplaySession implements ReplaySessionPort {
  _ReplaySession({this.rejectDocument, this.observed = false});

  final String? rejectDocument;
  final bool observed;
  Completer<void>? seekCompletion;
  int _position = 0;
  final positions = <int>[];
  final openedDocuments = <String>[];

  @override
  Future<String> exportReplayDocument() async => 'engine-replay';

  @override
  Future<ReplayFrameView> openReplayDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    openedDocuments.add(document);
    if (document == rejectDocument) {
      throw const ReplaySessionException(
        code: 'replay_open_failed',
        message: 'Rejected replay.',
      );
    }
    return _frame(0);
  }

  @override
  Future<ReplayFrameView> seekReplay(int position) async {
    positions.add(position);
    await seekCompletion?.future;
    final frame = _frame(
      position,
      command: observed && position == _position + 1,
    );
    _position = position;
    return frame;
  }

  ReplayFrameView _frame(int position, {bool command = false}) {
    final scene = testMapScene();
    return ReplayFrameView(
      position: position,
      entryCount: 3,
      scene: scene,
      command: command ? MapCommandFrameView(player: scene.player) : null,
    );
  }
}

final class _ReplayStore implements LocalReplayStore {
  _ReplayStore({
    String? primary,
    this.backup,
    this.scenario = LocalGameScenarioView.starterDuel,
  }) : document = primary;

  String? document;
  final String? backup;
  final LocalGameScenarioView scenario;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      scenario == this.scenario && (document != null || backup != null);

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) async {
    if (scenario != this.scenario) return null;
    return switch (copy) {
      LocalReplayCopyView.primary => document,
      LocalReplayCopyView.backup => backup,
    };
  }

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {
    this.document = document;
  }
}
