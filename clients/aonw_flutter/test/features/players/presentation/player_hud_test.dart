import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_navigation.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_input.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_gamepad_region.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/viewer_hud.dart';
import 'package:aonw_flutter/features/players/presentation/player_status.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'player_test_fixture.dart';

void main() {
  test(
    'foreign submission and AI thinking cannot be inferred from aggregates',
    () {
      final l10n = AonwLocalizationsEn();
      for (final submitted in [false, true]) {
        final player = playersFixture(submitted: submitted);
        expect(
          playerStatus(player, 'one', l10n),
          submitted ? 'Submitted' : 'Active',
        );
        expect(playerStatus(player, 'two', l10n), 'Turn status is private');
        expect(playerStatus(player, 'three', l10n), 'Turn status is private');
      }
    },
  );
  testWidgets(
    'details use only disclosed relations and resources replace them',
    (tester) async {
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: ViewerHud(player: playersFixture(), sessionIdentity: 0),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('player-avatar-two')));
      await tester.pumpAndSettle();
      expect(find.text('Friendly'), findsOneWidget);
      expect(find.text('Turn status is private'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player-avatar-three')));
      await tester.pumpAndSettle();
      expect(find.text('No diplomatic contact'), findsOneWidget);
      expect(find.text('Friendly'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('resource-gold')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-details-three')), findsNothing);
      expect(
        find.byKey(const ValueKey('resource-details-gold')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('player-avatar-one')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('player-details-one')), findsNothing);
    },
  );
  testWidgets('recipient replacement and seek clear player details', (
    tester,
  ) async {
    Widget screen(String actor, bool blocked) => LocalizedTestApp(
      home: Scaffold(
        body: ViewerHud(
          player: playersFixture(actor: actor),
          sessionIdentity: 0,
          blocked: blocked,
        ),
      ),
    );
    await tester.pumpWidget(screen('one', false));
    await tester.tap(find.byKey(const ValueKey('player-avatar-two')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen('two', false));
    expect(find.byKey(const ValueKey('player-details-two')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('player-avatar-one')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen('two', true));
    expect(find.byKey(const ValueKey('player-details-one')), findsNothing);
  });
  testWidgets('player popup captures and releases gamepad ownership', (
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
            body: ViewerHud(player: playersFixture(), sessionIdentity: 0),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('player-avatar-two')));
    await tester.pumpAndSettle();
    expect(navigation.hasOpenPanel, isTrue);
    expect(
      navigation.handlePanelKeyboardCommand(MapInputCommand.cancel),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(navigation.hasOpenPanel, isFalse);
  });
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('rail and details fit $size at 130 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: const Locale('de'),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: ViewerHud(player: playersFixture(), sessionIdentity: 0),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('player-avatar-three')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('player-avatar-three'))),
        const Size(48, 48),
      );
    });
  }
}
