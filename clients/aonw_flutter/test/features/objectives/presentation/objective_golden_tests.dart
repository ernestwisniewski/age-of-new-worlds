part of 'objective_overlay_test.dart';

void objectiveGoldenTests() {
  group('objective panel regression images', () {
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
      testWidgets('objectives golden ${sample.name}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = sample.size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.binding.setSurfaceSize(sample.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          LocalizedTestApp(
            theme: AonwTheme.dark,
            locale: sample.locale,
            home: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('objective-golden'),
                child: _ObjectiveHarness(
                  objectives: [
                    for (final kind in MapObjectiveType.values)
                      MapObjectiveView(
                        id: kind.name,
                        type: kind,
                        coordinate: (col: 2 + kind.index, row: 3),
                        requiredHoldTurns: 4,
                        victoryPoints: 7,
                        goldPerTurn: 2,
                      ),
                  ],
                  outcome: _ongoing(),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('open-objectives')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(AonwPanel)).right,
          lessThanOrEqualTo(sample.size.width),
        );
        await expectLater(
          find.byKey(const ValueKey('objective-golden')),
          matchesGoldenFile('goldens/objectives_${sample.name}.png'),
        );
      });
    }
  });
}
