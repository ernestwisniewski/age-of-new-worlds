part of 'replay_presentation_controller_test.dart';

void replayViewModeTests() {
  testWidgets('replay markings follow settings and refresh after seeks', (
    tester,
  ) async {
    final session = _ReplaySession();
    final controller = ReplayPresentationController(
      session: session,
      viewerCapabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
        cityPlanning: session,
      ),
      store: _ReplayStore(primary: 'valid'),
    );
    final settings = ClientSettingsController.ephemeral();
    final game = AonwFlameGame();
    addTearDown(controller.dispose);
    addTearDown(settings.dispose);
    await controller.openLatest();
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
    expect(session.planningCalls, 0);
    final writes = game.world.debugSceneWriteCount;
    await settings.update(
      settings.settings.copyWith(
        mapDisplay: settings.settings.mapDisplay.copyWith(
          cityPlanning: settings.settings.cityPlanning.copyWith(
            showSites: true,
          ),
          showMapGrid: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(session.planningCalls, 1);
    expect(game.world.cityPlanningLayer.debugSiteCenters, hasLength(1));
    expect(game.world.gridLayer.debugGridVisible, isTrue);
    expect(game.world.debugSceneWriteCount, writes);
    session.seekCompletion = Completer<void>();
    controller.seek(1);
    await tester.pump();
    expect(game.world.cityPlanningLayer.isVisible, isFalse);
    session.seekCompletion!.complete();
    await tester.pumpAndSettle();
    expect(session.planningCalls, 2);
    expect(game.world.cityPlanningLayer.isVisible, isTrue);
    await settings.reset();
    await tester.pumpAndSettle();
    expect(game.world.cityPlanningLayer.isVisible, isFalse);
  });

  testWidgets(
    'replay waits for its initial view and retains it while seeking',
    (tester) async {
      final session = _ReplaySession();
      final controller = ReplayPresentationController(
        session: session,
        viewerCapabilities: testGameSessionCapabilities(
          FakeGameSession.success(testMapScene()),
          cityPlanning: session,
        ),
        store: _ReplayStore(primary: 'valid'),
      );
      addTearDown(controller.dispose);
      final preference = Completer<MapViewMode>();
      controller.readInitialMapViewMode = () => preference.future;
      final opening = controller.openLatest();
      final game = AonwFlameGame();
      await tester.pumpWidget(
        LocalizedTestApp(
          home: ReplayScreen(
            controller: controller,
            flameGameFactory: () => game,
          ),
        ),
      );
      expect(session.openedDocuments, isEmpty);
      preference.complete(MapViewMode.tile);
      await tester.pumpAndSettle();
      expect((await opening).started, isTrue);
      expect(game.world.debugScene?.interaction.viewMode, MapViewMode.tile);
      controller.readInitialMapViewMode = () async => MapViewMode.graphic;
      controller.seek(1);
      await tester.pumpAndSettle();
      expect(session.positions, [1]);
      expect(game.world.debugScene?.interaction.viewMode, MapViewMode.tile);
      await controller.openLatest();
      await tester.pumpAndSettle();
      expect(game.world.debugScene?.interaction.viewMode, MapViewMode.graphic);
      expect(game.world.debugScene?.effectiveViewMode, MapViewMode.tile);
    },
  );

  test('disposing during a preference read does not open a replay', () async {
    final session = _ReplaySession();
    final controller = ReplayPresentationController(
      session: session,
      viewerCapabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
        cityPlanning: session,
      ),
      store: _ReplayStore(primary: 'valid'),
    );
    final preference = Completer<MapViewMode>();
    controller.readInitialMapViewMode = () => preference.future;
    final opening = controller.openLatest();
    controller.dispose();
    preference.complete(MapViewMode.tile);
    expect((await opening).started, isFalse);
    expect(session.openedDocuments, isEmpty);
  });
}
