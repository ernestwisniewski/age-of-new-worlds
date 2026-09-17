import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';

void main() {
  final frames = SpriteFrames.createScope();
  tearDownAll(frames.dispose);
  setUpAll(() async {
    await frames.preload([
      const SpriteFrameId('building.workshop'),
      const SpriteFrameId('unit.warrior.idle.0'),
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
    (
      name: 'phone',
      size: const Size(390, 844),
      locale: 'pl',
      scale: 1.0,
      project: false,
      blocked: false,
    ),
    (
      name: 'tablet',
      size: const Size(1024, 768),
      locale: 'de',
      scale: 1.0,
      project: true,
      blocked: false,
    ),
    (
      name: 'desktop',
      size: const Size(1440, 900),
      locale: 'en',
      scale: 1.0,
      project: false,
      blocked: true,
    ),
    (
      name: 'large_text',
      size: const Size(390, 844),
      locale: 'de',
      scale: 2.0,
      project: false,
      blocked: false,
    ),
  ]) {
    testWidgets('production ${sample.name} preserves engine forecast', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = sample.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        bannerApp(
          options: bannerOptions(
            project: sample.project,
            blocked: sample.blocked,
          ),
          locale: sample.locale,
          scale: sample.scale,
          size: sample.size,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
      await expectLater(
        find.byKey(const ValueKey('production-banner-golden')),
        matchesGoldenFile('goldens/production_${sample.name}.png'),
      );
    });
  }
}
