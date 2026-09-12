part of 'replay_presentation_controller_test.dart';

void replayGoldenTests() {
  group('complete replay layout', () {
    setUpAll(() async {
      for (final font in [
        ('Cinzel', 'assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ('Lato', 'assets/fonts/Lato-Regular.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
      }
    });
    for (final sample in [
      (name: 'phone', size: const Size(390, 844), locale: const Locale('pl')),
      (name: 'tablet', size: const Size(1024, 768), locale: const Locale('de')),
      (
        name: 'desktop',
        size: const Size(1440, 900),
        locale: const Locale('en'),
      ),
    ]) {
      testWidgets('replay golden ${sample.name}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = sample.size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.binding.setSurfaceSize(sample.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final scene = testMapScene(
          cols: 12,
          rows: 8,
          actorColorValue: 0xffd4af37,
          units: [
            for (var index = 0; index < 4; index++)
              testVisibleUnit(
                id: 'unit-$index',
                coordinate: (col: 4 + index, row: 4),
              ),
          ],
        );
        final controller = ReplayPresentationController(
          session: _ReplaySession(scene: scene),
          viewerCapabilities: testGameSessionCapabilities(
            FakeGameSession.success(scene),
          ),
          store: _ReplayStore(primary: 'valid'),
        );
        final settings = ClientSettingsController.ephemeral();
        final game = AonwFlameGame();
        addTearDown(controller.dispose);
        addTearDown(settings.dispose);
        await settings.update(
          settings.settings.copyWith(
            reducedMotion: true,
            showUnitIdleAnimations: false,
          ),
        );
        await controller.openLatest();
        await tester.pumpWidget(
          LocalizedTestApp(
            theme: AonwTheme.dark,
            locale: sample.locale,
            home: ClientSettingsScope(
              controller: settings,
              child: RepaintBoundary(
                key: const ValueKey('replay-golden'),
                child: ReplayScreen(
                  controller: controller,
                  flameGameFactory: () => game,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await game.ready();
          for (final unit
              in game.world.unitLayer.children.whereType<MapUnitComponent>()) {
            await unit.debugLoadSprite();
          }
        });
        await tester.pumpAndSettle();
        expect(
          game.world.unitLayer.children.whereType<MapUnitComponent>(),
          hasLength(4),
        );
        expect(tester.takeException(), isNull);
        expect(
          MediaQuery.sizeOf(tester.element(find.byType(ReplayScreen))),
          sample.size,
        );
        await expectLater(
          find.byKey(const ValueKey('replay-golden')),
          matchesGoldenFile('goldens/replay_${sample.name}.png'),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  });
}
