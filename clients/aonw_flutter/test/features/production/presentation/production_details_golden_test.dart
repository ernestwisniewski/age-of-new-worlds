import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';
import 'production_details_fixture.dart';

void main() {
  final frames = SpriteFrames.createScope();
  tearDownAll(frames.dispose);
  setUpAll(() async {
    await frames.preload([
      const SpriteFrameId('building.workshop'),
      const SpriteFrameId('unit.warrior.idle.0'),
      const SpriteFrameId('wonder.greatLibrary'),
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
      name: 'building_phone',
      size: const Size(390, 844),
      locale: 'pl',
      target: const BuildingProductionTargetView('workshop'),
    ),
    (
      name: 'unit_tablet',
      size: const Size(1024, 768),
      locale: 'de',
      target: const UnitProductionTargetView(VisibleUnitKind.warrior),
    ),
    (
      name: 'wonder_desktop',
      size: const Size(1440, 900),
      locale: 'en',
      target: const WonderProductionTargetView('greatLibrary'),
    ),
  ]) {
    testWidgets('details ${sample.name} show localized content', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = sample.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        bannerApp(
          options: detailsOptions(sample.target),
          modal: true,
          locale: sample.locale,
          size: sample.size,
        ),
      );
      await tester.pumpAndSettle();
      final help = find.byIcon(Icons.help_outline);
      await tester.ensureVisible(help);
      await tester.pumpAndSettle();
      await tester.tap(help);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
      await expectLater(
        find.byKey(const ValueKey('production-banner-golden')),
        matchesGoldenFile('goldens/production_details_${sample.name}.png'),
      );
    });
  }
}
