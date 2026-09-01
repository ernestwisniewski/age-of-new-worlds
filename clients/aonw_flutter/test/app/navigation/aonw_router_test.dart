import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_hud_surface.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/replay/application/local_replay_store.dart';
import 'package:aonw_flutter/features/replay/application/replay_session_port.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/replay/read_model/replay_frame_view.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  testWidgets('opens the map route and fails closed for an unknown route', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(
      AonwApp(mapController: controller, initialRoute: AonwRoute.map),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    Navigator.of(tester.element(find.text('Settings'))).pop();
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const ValueKey('map-viewport')));
    Navigator.of(context).pushNamed('/future-screen');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('unknown-route')), findsOneWidget);
    expect(find.text('Unknown route: /future-screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('uses Polish app shell and map translations', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(
      AonwApp(
        mapController: controller,
        locale: const Locale('pl'),
        initialRoute: AonwRoute.map,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Mapa test-map, 3 na 2 heksów'),
      findsOneWidget,
    );

    final context = tester.element(find.byKey(const ValueKey('map-viewport')));
    Navigator.of(context).pushNamed('/future-screen');
    await tester.pumpAndSettle();

    expect(find.text('Strona niedostępna'), findsOneWidget);
    expect(find.text('Nieznana trasa: /future-screen'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    semantics.dispose();
  });

  testWidgets('starts a typed local AI match from the main menu', (
    tester,
  ) async {
    final scene = testMapScene();
    final session = FakeGameSession.success(scene);
    final saves = _SingleSaveStore();
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        session,
        save: _ResumeSession(scene),
      ),
      saveStore: saves,
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    expect(find.text('SINGLE PLAYER'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('single-player')));
    await tester.pumpAndSettle();
    expect(find.text('Play with the computer'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
    final turnMode = tester.widget<SegmentedButton<LocalTurnModeView>>(
      find.byKey(const ValueKey('turn-mode-selector')),
    );
    expect(turnMode.selected, {LocalTurnModeView.sequential});
    await tester.tap(find.text('Simultaneous'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-summary')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-summary')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('new-game-review')), findsOneWidget);
    expect(find.text('Simultaneous'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('start-game')));
    await tester.tap(find.byKey(const ValueKey('start-game')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);
    expect(session.localStartCalls, 1);
    final setup = session.lastLocalMatchSetup!;
    expect(setup.assets.scenarioDocument, contains('aonw2_local_duel.json'));
    expect(setup.turnMode, LocalTurnModeView.simultaneous);
    expect(setup.participants.map((item) => item.id), ['player-1', 'player-2']);
    expect(
      setup.participants.last.ai?.difficulty,
      LocalAiDifficultyView.normal,
    );

    final saveButton = tester.widget<AonwHudIconButton>(
      find.byKey(const ValueKey('save-game')),
    );
    expect(saveButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('save-game')));
    await tester.pumpAndSettle();
    expect(saves.document, 'engine-save');
    expect(find.text('Game saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens localized help and completes the guided onboarding', (
    tester,
  ) async {
    final session = FakeGameSession.success(testMapScene());
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(session),
    );

    await tester.pumpWidget(
      AonwApp(mapController: controller, locale: const Locale('pl')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('menu-help')));
    await tester.tap(find.byKey(const ValueKey('menu-help')));
    await tester.pumpAndSettle();
    expect(find.text('Jak grać'), findsOneWidget);
    expect(find.text('Realizuj cel'), findsOneWidget);
    expect(find.text('Zapisuj i analizuj'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('start-onboarding')));
    await tester.tap(find.byKey(const ValueKey('start-onboarding')));
    await tester.pumpAndSettle();
    expect(find.text('Przewodnik po grze'), findsOneWidget);
    expect(find.text('Czytaj mapę'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-onboarding-step')));
    await tester.pump();
    expect(find.text('Wydawaj precyzyjne polecenia'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('previous-onboarding-step')));
    await tester.pump();
    expect(find.text('Czytaj mapę'), findsOneWidget);

    for (var step = 0; step < 3; step += 1) {
      await tester.tap(find.byKey(const ValueKey('next-onboarding-step')));
      await tester.pump();
    }
    expect(find.text('Wracaj do gry bez obaw'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish-onboarding')));
    await tester.pumpAndSettle();
    expect(find.text('Graj z komputerem'), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-to-summary')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('resumes the authoritative local save from the main menu', (
    tester,
  ) async {
    final scene = testMapScene();
    final gameplay = FakeGameSession.success(scene);
    final saves = _SingleSaveStore('engine-save');
    final persistence = _ResumeSession(scene);
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(gameplay, save: persistence),
      saveStore: saves,
    );

    await tester.pumpWidget(AonwApp(mapController: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('load-game')));
    await tester.tap(find.byKey(const ValueKey('load-game')));
    await tester.pumpAndSettle();
    final continueButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('continue-game-starterDuel')),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('continue-game-starterDuel')));
    await tester.pumpAndSettle();

    expect(persistence.openedDocuments, ['engine-save']);
    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens credits and feedback through injected platform actions', (
    tester,
  ) async {
    final opened = <Uri>[];
    var exitCalls = 0;
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );
    await tester.pumpWidget(
      AonwApp(
        mapController: controller,
        onExit: () async => exitCalls += 1,
        openExternalUri: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('menu-credits')));
    await tester.tap(find.byKey(const ValueKey('menu-credits')));
    await tester.pumpAndSettle();
    expect(find.text('Created by Ernest'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-devlog')));
    await tester.pump();
    expect(opened.single.host, 'ernest.dev');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('menu-feedback')));
    await tester.tap(find.byKey(const ValueKey('menu-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('open-feedback-link')));
    await tester.pump();
    expect(opened.last.host, 'www.reddit.com');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('exit-game')));
    await tester.tap(find.byKey(const ValueKey('exit-game')));
    await tester.pump();
    expect(exitCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens and controls a stored authoritative replay', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final scene = testMapScene();
    final gameplay = FakeGameSession.success(scene);
    final replaySession = _ReplaySession(scene);
    final replayController = ReplayPresentationController(
      session: replaySession,
      store: _SingleReplayStore('engine-replay'),
      diagnosticReporter: (_, _, _) {},
    );
    final mapController = MapPresentationController(
      capabilities: testGameSessionCapabilities(gameplay),
    );

    await tester.pumpWidget(
      AonwApp(mapController: mapController, replayController: replayController),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('load-game')));
    await tester.tap(find.byKey(const ValueKey('load-game')));
    await tester.pumpAndSettle();
    final replayButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('open-replay-starterDuel')),
    );
    expect(replayButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('open-replay-starterDuel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('replay-viewport')), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('play-replay')));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('play-replay')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('play-replay')));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.text('1 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-replay')));
    await tester.tap(find.byKey(const ValueKey('close-replay')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('open-replay-starterDuel')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}

final class _ResumeSession implements GameSaveSessionPort {
  _ResumeSession(this.scene);

  final MapScene scene;
  final openedDocuments = <String>[];

  @override
  Future<String> exportSaveDocument() async => 'engine-save';

  @override
  Future<OpenedGameSaveView> inspectSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async => _opened();

  @override
  Future<OpenedGameSaveView> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    openedDocuments.add(document);
    return _opened();
  }

  OpenedGameSaveView _opened() => OpenedGameSaveView(
    scene: scene,
    controlPlan: LocalMatchControlPlanView([
      LocalParticipantControlView(
        id: scene.player.actorPlayerId,
        name: 'Player',
        control: LocalPlayerControlView.human,
      ),
    ]),
  );
}

final class _SingleSaveStore implements LocalSaveStore {
  _SingleSaveStore([this.document]);

  String? document;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      scenario == LocalGameScenarioView.starterDuel && document != null;

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) async =>
      scenario == LocalGameScenarioView.starterDuel &&
          copy == LocalSaveCopyView.primary
      ? document
      : null;

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {
    this.document = document;
  }
}

final class _ReplaySession implements ReplaySessionPort {
  _ReplaySession(this.scene);

  final MapScene scene;

  @override
  Future<String> exportReplayDocument() async => 'engine-replay';

  @override
  Future<ReplayFrameView> openReplayDocument({
    required MapAssetPaths assets,
    required String document,
  }) async => ReplayFrameView(position: 0, entryCount: 3, scene: scene);

  @override
  Future<ReplayFrameView> seekReplay(int position) async =>
      ReplayFrameView(position: position, entryCount: 3, scene: scene);
}

final class _SingleReplayStore implements LocalReplayStore {
  _SingleReplayStore(this.document);

  final String? document;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      scenario == LocalGameScenarioView.starterDuel && document != null;

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) async =>
      scenario == LocalGameScenarioView.starterDuel &&
          copy == LocalReplayCopyView.primary
      ? document
      : null;

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {}
}
