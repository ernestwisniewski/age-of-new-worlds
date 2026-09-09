import 'package:aonw_flutter/features/players/presentation/player_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'player_test_fixture.dart';

void main() {
  for (final sample in [
    (viewport: const Size(390, 844), tile: const Size(40, 40)),
    (viewport: const Size(844, 390), tile: const Size(40, 40)),
    (viewport: const Size(1024, 768), tile: const Size(140, 32)),
    (viewport: const Size(1440, 900), tile: const Size(140, 32)),
  ]) {
    testWidgets('online rail uses reference metrics at ${sample.viewport}', (
      tester,
    ) async {
      tester.view.physicalSize = sample.viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          locale: const Locale('de'),
          home: MediaQuery(
            data: MediaQueryData(
              size: sample.viewport,
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: PlayerOverlay(
                player: playersFixture(submitted: true),
                online: true,
                selectedId: 'two',
                onSelect: (_) {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('online-player-tile-one'))),
        sample.tile,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('player-avatar-one'))).height,
        48,
      );
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final details = tester.getRect(
        find.byKey(const ValueKey('player-details-two')),
      );
      final rail = tester.getRect(
        find.byKey(const ValueKey('player-avatar-two')),
      );
      expect(details.right, lessThan(rail.left));
    });
  }
}
