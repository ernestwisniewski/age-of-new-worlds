part of 'strategic_resource_panel_test.dart';

void _goldens() {
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
    (name: 'phone', size: const Size(390, 844), locale: 'pl', scale: 1.0),
    (name: 'tablet', size: const Size(1024, 768), locale: 'de', scale: 1.0),
    (name: 'desktop', size: const Size(1440, 900), locale: 'en', scale: 1.0),
    (name: 'large_text', size: const Size(390, 844), locale: 'de', scale: 2.0),
  ]) {
    testWidgets('${sample.name} inventory golden', (tester) async {
      await _pumpInventory(
        tester,
        size: sample.size,
        locale: sample.locale,
        scale: sample.scale,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('inventory-golden')),
        matchesGoldenFile('goldens/inventory_${sample.name}.png'),
      );
      if (sample.name == 'phone') {
        await tester.ensureVisible(
          find.byKey(const ValueKey('strategic-inventory-partners')),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('inventory-golden')),
          matchesGoldenFile('goldens/inventory_phone_trade.png'),
        );
      }
    });
  }
}
