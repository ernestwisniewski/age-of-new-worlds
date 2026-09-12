part of 'multiplayer_screen_test.dart';

void lobbyGoldenCases() {
  for (final sample in [
    (name: 'phone', size: const Size(390, 844), language: 'pl', scale: 1.0),
    (name: 'tablet', size: const Size(1024, 768), language: 'de', scale: 1.0),
    (name: 'desktop', size: const Size(1440, 900), language: 'en', scale: 1.0),
    (
      name: 'large_text',
      size: const Size(390, 844),
      language: 'de',
      scale: 2.0,
    ),
  ]) {
    testWidgets('waiting room golden ${sample.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = sample.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.binding.setSurfaceSize(sample.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final coordinator = MultiplayerCoordinator(
        session: _Session(),
        documents: _Documents(),
      );
      final controller = MultiplayerController(coordinator);
      addTearDown(controller.dispose);
      await controller.initialize();
      await coordinator.createMatch();
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: Locale(sample.language),
          theme: AonwTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(
              size: sample.size,
              textScaler: TextScaler.linear(sample.scale),
            ),
            child: RepaintBoundary(
              key: const ValueKey('lobby-golden'),
              child: MultiplayerScreen(controller: controller),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(aonwMenuBackgroundAsset),
          tester.element(find.byType(MultiplayerScreen)),
        );
      });
      await tester.pumpAndSettle();
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(MultiplayerScreen))),
        sample.size,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('lobby-golden')),
        matchesGoldenFile('goldens/waiting_room_${sample.name}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}
