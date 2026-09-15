import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_victory_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/resource_hud_test_host.dart';
import 'resource_test_fixture.dart';

void main() {
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
    (name: 'phone', size: const Size(390, 844), locale: const Locale('pl')),
    (name: 'tablet', size: const Size(1024, 768), locale: const Locale('de')),
    (name: 'desktop', size: const Size(1440, 900), locale: const Locale('en')),
  ]) {
    testWidgets('${sample.name} resource strip and detailed income', (
      tester,
    ) async {
      tester.view.physicalSize = sample.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: sample.locale,
          theme: AonwTheme.dark,
          home: RepaintBoundary(
            key: const ValueKey('resource-golden'),
            child: Scaffold(
              body: ResourceHudTestHost(
                player: resourcePlayerFixture(
                  warning: TreasuryWarningView.deficitWithinThreeTurns,
                  shortages: const [MapResource.oil],
                  victory: resourceVictoryFixture(
                    const VictoryStatusView(
                      kind: VictoryStatusKindView.score,
                      critical: true,
                      leaderPlayerId: 'player-1',
                    ),
                  ),
                ),
                sessionIdentity: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gold = find.byKey(const ValueKey('resource-gold'));
      await tester.ensureVisible(gold);
      await tester.tap(gold);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('resource-golden')),
        matchesGoldenFile('goldens/resources_${sample.name}.png'),
      );
    });
  }
}
