import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/presentation/production_panel.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets(
    'shows exact costs and resources and dispatches only legal choice',
    (tester) async {
      final semantics = tester.ensureSemantics();
      ProductionActionView? dispatched;
      await tester.pumpWidget(
        LocalizedTestApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: SingleChildScrollView(
                child: ProductionPanel(
                  state: ProductionState(
                    cityId: 'preview-city',
                    options: _options(),
                    resources: _resources(),
                  ),
                  onAction: (value) => dispatched = value,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Strategic resources: Oil 2'), findsOneWidget);
      final available = find.widgetWithText(
        OutlinedButton,
        'Granary · cost 12',
      );
      final blocked = find.widgetWithText(
        OutlinedButton,
        'Workshop · cost 15 · This building is unavailable.',
      );
      expect(available, findsOneWidget);
      expect(blocked, findsOneWidget);
      expect(tester.widget<OutlinedButton>(blocked).onPressed, isNull);

      await tester.tap(available);
      expect(dispatched, isA<StartBuildingActionView>());
      expect((dispatched! as StartBuildingActionView).building, 'granary');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

ProductionOptionsView _options() => ProductionOptionsView(
  stamp: testSessionStamp(),
  cityId: 'preview-city',
  currentTarget: null,
  investedProduction: 4,
  productionOverflow: 1,
  buildings: const [
    ProductionOptionView(
      target: BuildingProductionTargetView('granary'),
      cost: 12,
      blocker: null,
    ),
    ProductionOptionView(
      target: BuildingProductionTargetView('workshop'),
      cost: 15,
      blocker: ProductionRejectionCodeView.buildingNotAvailable,
    ),
  ],
  units: const [],
  projects: const [],
  wonders: const [],
  specializations: const [],
);

StrategicResourceProjectionView _resources() => StrategicResourceProjectionView(
  stamp: testSessionStamp(),
  playerId: 'preview-player',
  output: const [
    StrategicResourceAmountView(resource: MapResource.oil, amount: 2),
  ],
  sources: const [],
);
