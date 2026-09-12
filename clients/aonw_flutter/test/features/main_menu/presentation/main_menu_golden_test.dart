import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_menu_backdrop.dart';
import 'package:aonw_flutter/features/main_menu/presentation/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    (name: 'desktop', size: const Size(1440, 900), locale: const Locale('en')),
  ]) {
    testWidgets('complete main menu ${sample.name}', (tester) async {
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
          home: RepaintBoundary(
            key: const ValueKey('menu-golden'),
            child: MainMenuScreen(
              onOpenSinglePlayer: () {},
              onOpenMultiplayer: () {},
              onOpenHotseat: () {},
              onOpenLoadGame: () {},
              onOpenSettings: () {},
              onOpenInstructions: () {},
              onOpenCredits: () {},
              onOpenFeedback: () {},
              onExit: () async {},
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MainMenuScreen));
        await precacheImage(const AssetImage(aonwMenuBackgroundAsset), context);
        if (!context.mounted) return;
        await precacheImage(const AssetImage(aonwLogoAsset), context);
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(MainMenuScreen))),
        sample.size,
      );
      await expectLater(
        find.byKey(const ValueKey('menu-golden')),
        matchesGoldenFile('goldens/menu_${sample.name}.png'),
      );
    });
  }
}
