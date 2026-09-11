import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import '../../../support/resource_hud_test_host.dart';

void main() {
  testWidgets('every resource opens a read-only popup and Escape closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: ResourceHudTestHost(
            player: testMapScene().player,
            sessionIdentity: 0,
          ),
        ),
      ),
    );
    for (final kind in ResourcePopup.values) {
      final trigger = find.byKey(ValueKey('resource-${kind.name}'));
      await tester.ensureVisible(trigger);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('resource-details-${kind.name}')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('resource-details-${kind.name}')),
        findsNothing,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('gamepad popup captures cancel and releases map ownership', (
    tester,
  ) async {
    final navigation = MapGamepadNavigation(
      onOwnerChanged: () {},
      returnToMap: () {},
    );
    addTearDown(navigation.dispose);
    await tester.pumpWidget(
      LocalizedTestApp(
        home: MapGamepadNavigationScope(
          navigation: navigation,
          child: Scaffold(
            body: ResourceHudTestHost(
              player: testMapScene().player,
              sessionIdentity: 0,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('resource-gold')));
    await tester.pumpAndSettle();
    expect(navigation.hasOpenPanel, isTrue);
    expect(
      navigation.handlePanelKeyboardCommand(MapInputCommand.cancel),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(navigation.hasOpenPanel, isFalse);
  });

  testWidgets('viewer replacement and pending seeks clear private details', (
    tester,
  ) async {
    Widget screen(int identity, bool blocked) => LocalizedTestApp(
      home: Scaffold(
        body: ResourceHudTestHost(
          player: testMapScene().player,
          sessionIdentity: identity,
          blocked: blocked,
        ),
      ),
    );
    await tester.pumpWidget(screen(0, false));
    await tester.tap(find.byKey(const ValueKey('resource-gold')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen(1, false));
    expect(find.byKey(const ValueKey('resource-details-gold')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('resource-gold')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen(1, true));
    expect(find.byKey(const ValueKey('resource-details-gold')), findsNothing);
  });

  for (final size in [
    const Size(390, 844),
    const Size(1024, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('resource HUD fits $size at 130 percent text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: ResourceHudTestHost(
                player: testMapScene().player,
                sessionIdentity: 0,
              ),
            ),
          ),
        ),
      );
      final trigger = find.byKey(const ValueKey('resource-stability'));
      await tester.ensureVisible(trigger);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-details-stability')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('close-resource-details')))
            .right,
        lessThanOrEqualTo(size.width),
      );
    });
  }
}
