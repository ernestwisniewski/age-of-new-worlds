import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/local_game/presentation/local_handoff_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
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
    testWidgets('handoff ${sample.name} has private player identity', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = sample.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        LocalizedTestApp(
          theme: AonwTheme.dark,
          locale: Locale(sample.locale),
          home: MediaQuery(
            data: MediaQueryData(
              size: sample.size,
              textScaler: TextScaler.linear(sample.scale),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: RepaintBoundary(
                key: const ValueKey('handoff-golden'),
                child: LocalHandoffOverlay(
                  state: const LocalHandoffState.awaitingConfirmation(
                    playerId: 'player-2',
                    playerName: 'Aleksandra',
                  ),
                  playerColorValue: 0xff8b2424,
                  turnNumber: 42,
                  onConfirm: () {},
                  onRetry: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
      await expectLater(
        find.byKey(const ValueKey('handoff-golden')),
        matchesGoldenFile('goldens/handoff_${sample.name}.png'),
      );
    });
  }
}
