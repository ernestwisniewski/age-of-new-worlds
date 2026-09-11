part of 'replay_presentation_controller_test.dart';

void replaySharedHudTests() {
  testWidgets(
    'shared replay HUD retires inspection when seeking the same frame',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = _ReplaySession();
      final queries = FakeGameSession.success(testMapScene());
      final controller = ReplayPresentationController(
        session: session,
        viewerCapabilities: testGameSessionCapabilities(
          queries,
          cityPlanning: session,
        ),
        store: _ReplayStore(primary: 'valid'),
      );
      addTearDown(controller.dispose);
      final game = AonwFlameGame();
      await controller.openLatest();
      await tester.pumpWidget(
        LocalizedTestApp(
          home: ReplayScreen(
            controller: controller,
            flameGameFactory: () => game,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MapHudPanels), findsOneWidget);
      final first = tester.widget<MapScreen>(find.byType(MapScreen)).controller;
      expect(first.readOnly, isTrue);
      first.setMapViewMode(MapViewMode.tile);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resource-gold')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-details-gold')),
        findsOneWidget,
      );
      final world = game.world;
      session.seekCompletion = Completer<void>();
      controller.seek(0);
      await tester.pump();
      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).interactionEnabled,
        isFalse,
      );
      expect(find.byKey(const ValueKey('resource-details-gold')), findsNothing);
      session.seekCompletion!.complete();
      await tester.pumpAndSettle();
      final next = tester.widget<MapScreen>(find.byType(MapScreen));
      expect(next.controller, isNot(same(first)));
      expect(next.interactionEnabled, isTrue);
      expect(game.world, same(world));
      expect(game.world.debugScene?.interaction.viewMode, MapViewMode.tile);
      expect(find.byKey(const ValueKey('save-game')), findsNothing);
      expect(find.byKey(const ValueKey('turn-hud')), findsNothing);
      expect(queries.endTurnCalls, 0);
      expect(queries.researchCommandCalls, 0);
      await tester.tap(find.byKey(const ValueKey('resource-gold')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-details-gold')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets(
        'replay controls remain separate from HUD at 200% $language $size',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
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
          await controller.openLatest();
          await tester.pumpWidget(
            LocalizedTestApp(
              locale: Locale(language),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: ReplayScreen(controller: controller),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final viewport = tester.getRect(
            find.byKey(const ValueKey('replay-viewport')),
          );
          expect(viewport.width, size.width);
          expect(viewport.height, greaterThan(0));
          for (final key in [
            'play-replay',
            'replay-speed',
            'replay-seek',
            'close-replay',
          ]) {
            final control = find.byKey(ValueKey(key));
            expect(control.hitTestable(), findsOneWidget);
            final rect = tester.getRect(control);
            expect(rect.top, greaterThanOrEqualTo(viewport.bottom));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
