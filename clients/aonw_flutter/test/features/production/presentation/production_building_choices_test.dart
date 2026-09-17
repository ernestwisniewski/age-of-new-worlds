import 'package:aonw_flutter/features/production/presentation/production_building_choices.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets(
    'research and completion group identical command blockers correctly',
    (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('port'), findsOneWidget);
      expect(find.text('workshop'), findsNothing);
      expect(find.text('granary'), findsNothing);
      await tester.tap(find.text('Future buildings'));
      await tester.pumpAndSettle();
      expect(find.text('workshop'), findsOneWidget);
      expect(find.text('granary'), findsNothing);
      await tester.tap(find.text('Completed buildings'));
      await tester.pumpAndSettle();
      expect(find.text('granary'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('keyboard opens a collapsed group and city changes reset it', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('workshop'), findsOneWidget);
    await tester.pumpWidget(_app(cityId: 'other-city'));
    await tester.pumpAndSettle();
    expect(find.text('workshop'), findsNothing);
  });

  for (final locale in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets(
      '$locale collapsed and expanded groups fit phone text 200 percent',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(locale: locale, scale: 2));
        final future = find.byKey(
          const ValueKey(('production-future-buildings', 'city')),
        );
        await tester.ensureVisible(future);
        await tester.tap(
          find.descendant(of: future, matching: find.byType(ListTile)),
        );
        await tester.pumpAndSettle();
        expect(find.text('workshop'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  }
}

Widget _app({String cityId = 'city', String locale = 'en', double scale = 1}) =>
    LocalizedTestApp(
      locale: Locale(locale),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: ProductionBuildingChoices(
              cityId: cityId,
              options: [
                _option('port', unlocked: true),
                _option('workshop', unlocked: false),
                _option('granary', unlocked: true, completed: true),
              ],
              choice: (option) => Text(
                (option.target as BuildingProductionTargetView).building,
              ),
            ),
          ),
        ),
      ),
    );

ProductionOptionView _option(
  String building, {
  required bool unlocked,
  bool completed = false,
}) => ProductionOptionView(
  target: BuildingProductionTargetView(building),
  cost: 15,
  blocker: ProductionRejectionCodeView.buildingNotAvailable,
  availability: ProductionAvailabilityView(
    requiredTechnology: TechnologyIdView.craftsmanship,
    technologyUnlocked: unlocked,
    completedInCity: completed,
  ),
  forecast: const ProductionForecastView(
    investedProduction: 0,
    productionPerTurn: 3,
    estimatedTurns: 5,
    projectOutput: null,
    spawnBlocked: false,
  ),
);
