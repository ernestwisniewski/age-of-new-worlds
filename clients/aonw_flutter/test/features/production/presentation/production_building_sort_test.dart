import 'package:aonw_flutter/features/production/presentation/production_building_choices.dart';
import 'package:aonw_flutter/features/production/presentation/production_building_sort.dart';
import 'package:aonw_flutter/features/production/read_model/production_ranking_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  for (final mode in ProductionBuildingSort.values) {
    test(
      '$mode uses the authoritative key before time and localized title',
      () {
        final ranks = [
          _rank('granary', priority: 3, turns: 1, mode: mode),
          _rank('port', priority: 5, turns: 5, mode: mode),
          _rank('workshop', priority: 5, turns: 4, mode: mode),
          _rank('housing', priority: 5, turns: 4, mode: mode),
        ];
        final options = [for (final rank in ranks) _option(rank.building)];
        final sorted = mode.order(
          options,
          ranks,
          (target) => switch (target) {
            BuildingProductionTargetView(building: 'workshop') => 'A',
            _ => 'Z',
          },
        );
        expect(
          sorted.map(_id),
          mode == ProductionBuildingSort.fastestImpact
              ? ['granary', 'workshop', 'housing', 'port']
              : ['workshop', 'housing', 'port', 'granary'],
        );
        expect(options.map(_id), ['granary', 'port', 'workshop', 'housing']);
      },
    );
  }

  testWidgets('selection survives refresh and resets when the city changes', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(_dropdown(tester).value, ProductionBuildingSort.recommended);
    await tester.tap(find.byKey(const ValueKey('production-building-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fastest impact').last);
    await tester.pumpAndSettle();
    expect(_dropdown(tester).value, ProductionBuildingSort.fastestImpact);
    expect(
      tester.getTopLeft(find.text('granary')).dy,
      lessThan(tester.getTopLeft(find.text('port')).dy),
    );
    await tester.pumpWidget(_app());
    expect(_dropdown(tester).value, ProductionBuildingSort.fastestImpact);
    await tester.pumpWidget(_app(cityId: 'second'));
    expect(_dropdown(tester).value, ProductionBuildingSort.recommended);
    expect(
      tester.getTopLeft(find.text('port')).dy,
      lessThan(tester.getTopLeft(find.text('granary')).dy),
    );
  });

  for (final locale in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets('$locale sort menu fits phone at 200 percent', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(locale: locale, scale: 2));
      await tester.tap(find.byKey(const ValueKey('production-building-sort')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
      final menu = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sort-economy')).last,
        150,
        scrollable: menu,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sort-economy')).last);
      await tester.pumpAndSettle();
      expect(_dropdown(tester).value, ProductionBuildingSort.economy);
      expect(tester.takeException(), isNull);
    });
  }
}

DropdownButton<ProductionBuildingSort> _dropdown(WidgetTester tester) =>
    tester.widget(find.byKey(const ValueKey('production-building-sort')));

String _id(ProductionOptionView option) =>
    (option.target as BuildingProductionTargetView).building;

Widget _app({String cityId = 'city', String locale = 'en', double scale = 1}) =>
    LocalizedTestApp(
      locale: Locale(locale),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(scale),
          ),
          child: CustomScrollView(
            slivers: [
              ProductionBuildingChoices(
                cityId: cityId,
                options: [_option('granary'), _option('port')],
                ranks: [
                  _rank('granary', priority: 1, turns: 1),
                  _rank('port', priority: 5, turns: 5),
                ],
                choice: (option) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_id(option)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

ProductionBuildingRankView _rank(
  String id, {
  required int priority,
  required int turns,
  ProductionBuildingSort? mode,
}) {
  int score(ProductionBuildingSort field) =>
      mode == null || mode == field ? priority : 0;
  return ProductionBuildingRankView(
    building: id,
    turnsForScore: turns,
    recommended: score(ProductionBuildingSort.recommended),
    bestReturn: score(ProductionBuildingSort.bestReturn),
    growth: score(ProductionBuildingSort.growth),
    industry: score(ProductionBuildingSort.industry),
    science: score(ProductionBuildingSort.science),
    defenseMilitary: score(ProductionBuildingSort.defenseMilitary),
    economy: score(ProductionBuildingSort.economy),
  );
}

ProductionOptionView _option(String id) => ProductionOptionView(
  target: BuildingProductionTargetView(id),
  cost: id == 'granary' ? 1 : 999,
  blocker: null,
  availability: const ProductionAvailabilityView(
    requiredTechnology: null,
    technologyUnlocked: true,
    completedInCity: false,
  ),
  forecast: const ProductionForecastView(
    investedProduction: 0,
    productionPerTurn: 1,
    estimatedTurns: 100,
    projectOutput: null,
    spawnBlocked: false,
  ),
);
