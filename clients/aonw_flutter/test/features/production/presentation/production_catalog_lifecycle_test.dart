import 'dart:convert';

import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/production/presentation/production_choice_card.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_banner_fixture.dart';
import 'production_catalog_fixture.dart';

void main() {
  late ProductionOptionsView options;
  final frames = SpriteFrames.createScope();
  tearDownAll(frames.dispose);
  setUpAll(() async {
    final manifest =
        jsonDecode(
              await rootBundle.loadString(
                'assets/runtime/sprites/sprite_manifest.json',
              ),
            )
            as Map<String, dynamic>;
    final names = (manifest['frames'] as Map<String, dynamic>).keys
        .where((name) => name.startsWith('building.'))
        .map((name) => name.substring('building.'.length))
        .toList();
    await frames.preload([
      for (final name in names) SpriteFrameId('building.$name'),
    ]);
    options = _catalog(names);
    expect(names.length, 59);
  });

  testWidgets('catalog keeps a bounded set of rows and releases its atlases', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(bannerApp(options: options, modal: true));
    await tester.pumpAndSettle();
    expect(
      find.byType(ProductionChoiceCard).evaluate().length,
      inInclusiveRange(1, 12),
    );

    expect(SpriteFrames.debugAtlasBytes, isNotEmpty);
    final firstTitles = tester
        .widgetList<ProductionChoiceCard>(find.byType(ProductionChoiceCard))
        .map(
          (card) =>
              (card.option.target as BuildingProductionTargetView).building,
        )
        .toList();
    await tester.drag(
      find.byKey(const ValueKey('production-catalog-scroll')),
      const Offset(0, -2400),
    );
    await tester.pumpAndSettle();
    final nextTitles = tester
        .widgetList<ProductionChoiceCard>(find.byType(ProductionChoiceCard))
        .map(
          (card) =>
              (card.option.target as BuildingProductionTargetView).building,
        )
        .toList();
    expect(nextTitles, isNot(firstTitles));
    expect(nextTitles.length, inInclusiveRange(1, 12));

    expect(tester.hasRunningAnimations, isFalse);
    frames.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(SpriteFrames.debugAtlasBytes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

ProductionOptionsView _catalog(List<String> names) {
  final source = catalogOptions();
  final sample = source.buildings.first;
  return ProductionOptionsView(
    stamp: source.stamp,
    cityId: source.cityId,
    currentTarget: null,
    investedProduction: 0,
    productionOverflow: 0,
    rushQuote: source.rushQuote,
    buildings: [
      for (final name in names)
        ProductionOptionView(
          target: BuildingProductionTargetView(name),
          cost: sample.cost,
          blocker: null,
          forecast: sample.forecast,
          availability: sample.availability,
        ),
    ],
    units: [],
    projects: [],
    wonders: [],
    specializations: [],
  );
}
