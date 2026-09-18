import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/production/application/production_inspection_state.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/presentation/production_building_details.dart';
import 'package:aonw_flutter/features/production/presentation/production_detail_widgets.dart';
import 'package:aonw_flutter/features/production/presentation/production_target_details.dart';
import 'package:aonw_flutter/features/production/presentation/production_wonder_details.dart';
import 'package:aonw_flutter/features/production/read_model/production_details_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'production_details_effects_fixture.dart';
import 'production_details_fixture.dart';

void main() {
  testWidgets(
    'building impact uses city output and preserves fractional bonuses',
    (tester) async {
      final base = detailFixture(detailsOptions(_target), _target);
      final values = base.effects as BuildingProductionDetailsView;
      final effects = BuildingProductionDetailsView(
        requirements: [
          ProductionRequirementStatusView(
            requirement: ProductionRequirementView(
              kind: ProductionRequirementKindView.resourceAny,
              resources: [MapResource.iron, MapResource.coal],
            ),
            met: false,
          ),
        ],
        flatYield: values.flatYield,
        riverYieldPerHex: _yield(1),
        maxRiverApplications: 3,
        riverApplications: 2,
        sciencePerTurn: 0,
        maxControlledHexesDelta: 2,
        foodDepositBasisPoints: 12550,
        current: values.current,
        completed: values.completed,
      );
      await tester.pumpWidget(
        _app(ProductionBuildingDetails(option: base.option, effects: effects)),
      );
      expect(find.text('3 → 5 (+2)'), findsOneWidget);
      expect(find.text('+25.5% food stored after turn'), findsOneWidget);
      expect(
        find.text('+1 production per controlled river tile (max 3)'),
        findsOneWidget,
      );
      expect(find.text('Applied river tiles: 2'), findsOneWidget);
      expect(find.text('Resource: Iron or Coal'), findsOneWidget);
      final requirement = tester.widget<ProductionDetailLine>(
        find.widgetWithText(ProductionDetailLine, 'Resource: Iron or Coal'),
      );
      expect(requirement.met, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'wonder separates passive bonuses from completion and translates terrain',
    (tester) async {
      const target = WonderProductionTargetView('greatLibrary');
      final option = detailsOptions(target).optionFor(target)!;
      final effects = WonderProductionDetailsView(
        requirements: [
          ProductionRequirementStatusView(
            requirement: ProductionRequirementView(
              kind: ProductionRequirementKindView.hostTerrainAny,
              terrains: [MapTerrain.grassland],
            ),
            met: true,
          ),
        ],
        hostYield: _yield(2),
        empireYieldPerCity: _yield(1),
        empireSciencePerCity: 3,
        empireGoldBasisPoints: 2500,
        empireProductionBasisPoints: 1250,
        stabilityDelta: 2,
        grantsFreeActiveTechnology: true,
        productionBurst: 12,
        grantGold: 50,
      );
      await tester.pumpWidget(
        _app(ProductionWonderDetails(option: option, effects: effects)),
      );
      expect(find.text('+25% empire gold'), findsOneWidget);
      expect(find.text('+12.5% empire production'), findsOneWidget);
      expect(
        find.text('+12 production overflow in the host city'),
        findsOneWidget,
      );
      expect(find.text('Completes the active research'), findsOneWidget);
      expect(find.text('Terrain: Grassland'), findsOneWidget);
      await tester.pumpWidget(
        _app(
          ProductionWonderDetails(option: option, effects: effects),
          locale: 'pl',
        ),
      );
      expect(find.textContaining('grassland'), findsNothing);
      expect(find.textContaining('12,5%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading and failed inspection expose no stale numerical content and can retry',
    (tester) async {
      var retries = 0;
      var closed = false;
      Widget app(ProductionInspectionState state) => LocalizedTestApp(
        home: Scaffold(
          body: ProductionTargetDetails(
            inspection: state,
            onClose: () => closed = true,
            onRetry: () => retries++,
          ),
        ),
      );
      await tester.pumpWidget(
        app(const ProductionInspectionState(target: _target, correlationId: 1)),
      );
      expect(find.text('Workshop'), findsOneWidget);
      expect(find.byType(ProductionBuildingDetails), findsNothing);
      expect(find.textContaining('cost:'), findsNothing);
      await tester.pumpWidget(
        app(
          const ProductionInspectionState(
            target: _target,
            correlationId: 1,
            loading: false,
            failure: ProductionFailureView(ProductionFailureCode.requestFailed),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('The production request could not be completed.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      await tester.tap(find.byKey(const ValueKey('close-production-details')));
      expect(closed, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}

const _target = BuildingProductionTargetView('workshop');
YieldValueView _yield(int production) =>
    YieldValueView(food: 0, production: production, gold: 0, defense: 0);
Widget _app(Widget child, {String locale = 'en'}) => LocalizedTestApp(
  locale: Locale(locale),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
