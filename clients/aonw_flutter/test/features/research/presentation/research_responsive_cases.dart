part of 'research_overlay_test.dart';

void researchResponsiveCases() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Cinzel')..addFont(
          rootBundle.load('assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ))
        .load();
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final sample in [
    (name: 'phone', size: const Size(390, 844), language: 'pl', scale: 1.3),
    (name: 'tablet', size: const Size(1024, 768), language: 'de', scale: 1.0),
    (name: 'desktop', size: const Size(1440, 900), language: 'en', scale: 1.0),
    (name: 'landscape', size: const Size(740, 360), language: 'fr', scale: 1.3),
  ]) {
    testWidgets('${sample.name} research stays inside the viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(sample.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final selected = <TechnologyIdView>[];
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: Locale(sample.language),
          theme: AonwTheme.dark,
          home: RepaintBoundary(
            key: const ValueKey('research-golden'),
            child: Scaffold(
              body: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: sample.size,
                    textScaler: TextScaler.linear(sample.scale),
                  ),
                  child: ResearchOverlay(
                    state: ResearchState(
                      requestedRevision: 0,
                      options: _options(),
                    ),
                    selectionRequired: true,
                    trailingReserve: 60,
                    open: true,
                    onOpenChanged: (_) {},
                    onSelect: selected.add,
                    onRetry: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final surface = find.byType(ResearchOverlay);
      expect(tester.getRect(surface).width, sample.size.width);
      final close = find.byKey(const ValueKey('close-research'));
      expect(
        tester.getRect(close).right,
        lessThanOrEqualTo(sample.size.width - 60),
      );
      final first = find.byKey(
        const ValueKey(('research-option', 'agriculture')),
      );
      final second = find.byKey(
        const ValueKey(('research-option', 'woodworking')),
      );
      expect(tester.getRect(first).left, greaterThanOrEqualTo(0));
      expect(
        tester.getRect(first).right,
        lessThanOrEqualTo(sample.size.width - 60),
      );
      if (sample.size.width > 1000) {
        expect(
          tester.getRect(first).left,
          greaterThanOrEqualTo((sample.size.width - 60 - 980) / 2),
        );
        expect(tester.getRect(first).top, tester.getRect(second).top);
        expect(
          tester.getRect(second).left,
          greaterThan(tester.getRect(first).left),
        );
      }
      expect(
        find.byType(Card).evaluate().length,
        lessThan(TechnologyIdView.values.length),
      );
      if (sample.name != 'landscape') {
        await expectLater(
          find.byKey(const ValueKey('research-golden')),
          matchesGoldenFile('goldens/research_${sample.name}.png'),
        );
        await tester.tap(
          find.byKey(const ValueKey(('select-technology', 'agriculture'))),
        );
        expect(selected, [TechnologyIdView.agriculture]);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
