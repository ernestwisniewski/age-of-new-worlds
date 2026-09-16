import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_overlay.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'strategic_resource_fixture.dart';

part 'strategic_resource_golden_tests.dart';

void main() {
  testWidgets('inventory preserves authoritative values and navigation IDs', (
    tester,
  ) async {
    final cities = <String>[];
    final partners = <String>[];
    await _pumpInventory(tester, onCity: cities.add, onPartner: partners.add);
    expect(find.text('1/7'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('strategic-resource-uranium')),
      findsOneWidget,
    );
    final oil = find.byKey(const ValueKey('strategic-resource-oil'));
    expect(
      find.descendant(of: oil, matching: find.text('3')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: oil, matching: find.text('0')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('resource-partner-unknown')),
      findsNothing,
    );
    final allocation = find.descendant(
      of: find.byKey(const ValueKey('resource-allocation-warsaw')),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(allocation);
    await tester.tap(allocation);
    expect(cities, ['warsaw']);
    final partner = find.descendant(
      of: find.byKey(const ValueKey('resource-partner-partner')),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(partner);
    await tester.tap(partner);
    expect(partners, ['partner']);
    final importing = find.byKey(
      const ValueKey('resource-agreement-iron-import'),
    );
    final exporting = find.byKey(
      const ValueKey('resource-agreement-oil-export'),
    );
    expect(
      tester.getTopLeft(importing).dy,
      lessThan(tester.getTopLeft(exporting).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('keyboard and gamepad close the inventory popup', (tester) async {
    var closed = 0;
    final navigation = MapGamepadNavigation(
      onOwnerChanged: () {},
      returnToMap: () {},
    );
    addTearDown(navigation.dispose);
    await _pumpInventory(
      tester,
      navigation: navigation,
      onClose: () => closed++,
    );
    expect(navigation.hasOpenPanel, isTrue);
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('strategic-inventory-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.pixels, 0);
    navigation.handleCommand(MapInputCommand.cursorDown);
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, 1);
    expect(
      navigation.handlePanelKeyboardCommand(MapInputCommand.cancel),
      isTrue,
    );
    expect(closed, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(closed, 3);
  });

  for (final locale in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets('$locale inventory fits $size at 200 percent', (
        tester,
      ) async {
        await _pumpInventory(tester, locale: locale, size: size, scale: 2);
        final close = tester.getRect(
          find.byKey(const ValueKey('close-resource-details')),
        );
        expect(close.right, lessThanOrEqualTo(size.width));
        expect(close.bottom, lessThanOrEqualTo(size.height));
        for (final section in [
          'resources',
          'allocations',
          'sources',
          'agreements',
          'partners',
        ]) {
          await tester.ensureVisible(
            find.byKey(ValueKey('strategic-inventory-$section')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: section);
        }
      });
    }
  }
  _goldens();
}

Future<void> _pumpInventory(
  WidgetTester tester, {
  String locale = 'en',
  Size size = const Size(1024, 768),
  double scale = 1,
  ValueChanged<String>? onCity,
  ValueChanged<String>? onPartner,
  VoidCallback? onClose,
  MapGamepadNavigation? navigation,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final overlay = ResourceOverlay(
    player: strategicResourcePlayer(),
    open: ResourcePopup.resources,
    onOpen: (_) {},
    onClose: onClose ?? () {},
    onCity: onCity ?? (_) {},
    onTradePartner: onPartner ?? (_) {},
  );
  await tester.pumpWidget(
    LocalizedTestApp(
      locale: Locale(locale),
      theme: AonwTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('inventory-golden'),
          child: Scaffold(
            body: navigation == null
                ? overlay
                : MapGamepadNavigationScope(
                    navigation: navigation,
                    child: overlay,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
