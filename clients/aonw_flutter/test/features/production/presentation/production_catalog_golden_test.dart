import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';
import 'production_catalog_fixture.dart';

void main() {
  final frames = SpriteFrames.createScope();
  tearDownAll(frames.dispose);
  setUpAll(() async {
    await frames.preload([
      const SpriteFrameId('building.granary'),
      const SpriteFrameId('building.port'),
      const SpriteFrameId('building.workshop'),
      const SpriteFrameId('building.university'),
      const SpriteFrameId('building.housing'),
    ]);
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
    (name: 'phone', size: const Size(390, 844), locale: 'pl', expanded: false),
    (name: 'tablet', size: const Size(1024, 768), locale: 'de', expanded: true),
    (
      name: 'desktop',
      size: const Size(1440, 900),
      locale: 'en',
      expanded: true,
    ),
  ]) {
    testWidgets(
      'catalog ${sample.name} groups researched and completed buildings',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = sample.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          bannerApp(
            options: catalogOptions(),
            modal: true,
            locale: sample.locale,
            size: sample.size,
          ),
        );
        await tester.pumpAndSettle();
        if (sample.expanded) {
          final group = find.byKey(
            const ValueKey(('production-future-buildings', 'preview-city')),
          );
          await tester.ensureVisible(group);
          await tester.tap(
            find.descendant(of: group, matching: find.byType(ListTile)),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
        await expectLater(
          find.byKey(const ValueKey('production-banner-golden')),
          matchesGoldenFile('goldens/production_catalog_${sample.name}.png'),
        );
      },
    );
  }
}
