import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_menu_backdrop.dart';
import 'package:aonw_flutter/features/local_game/presentation/local_game_launch_mode.dart';
import 'package:aonw_flutter/features/local_game/presentation/new_game_screen.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import 'local_game_visual_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLocalGameFonts);
  for (final sample in [
    (name: 'phone', size: const Size(390, 844), language: 'pl'),
    (name: 'tablet', size: const Size(1024, 768), language: 'de'),
    (name: 'desktop', size: const Size(1440, 900), language: 'en'),
  ]) {
    for (final mode in LocalGameLaunchModeView.values) {
      testWidgets('new game ${mode.name} ${sample.name}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = sample.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.binding.setSurfaceSize(sample.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = MapPresentationController(
          capabilities: testGameSessionCapabilities(
            FakeGameSession.success(testMapScene()),
          ),
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          LocalizedTestApp(
            locale: Locale(sample.language),
            theme: AonwTheme.dark,
            home: RepaintBoundary(
              key: const ValueKey('new-game-golden'),
              child: newGameTestRoute(controller, mode),
            ),
          ),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage(aonwMenuBackgroundAsset),
            tester.element(find.byType(NewGameScreen)),
          );
        });
        await tester.pumpAndSettle();
        expect(
          MediaQuery.sizeOf(tester.element(find.byType(NewGameScreen))),
          sample.size,
        );
        await expectLater(
          find.byKey(const ValueKey('new-game-golden')),
          matchesGoldenFile('goldens/setup_${mode.name}_${sample.name}.png'),
        );
        final next = find.byKey(const ValueKey('continue-to-summary'));
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scroll.position.pixels, 0);
        await expectLater(
          find.byKey(const ValueKey('new-game-golden')),
          matchesGoldenFile('goldens/review_${mode.name}_${sample.name}.png'),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
}
