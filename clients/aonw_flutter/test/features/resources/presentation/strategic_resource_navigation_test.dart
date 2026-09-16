import 'package:aonw_flutter/features/diplomacy/application/diplomacy_session_port.dart';
import 'package:aonw_flutter/features/diplomacy/presentation/diplomacy_overlay.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';
import 'strategic_resource_fixture.dart';

void main() {
  testWidgets('inventory selects the referenced city in the shared map', (
    tester,
  ) async {
    final (controller, session) = await _mount(tester);
    final city = find.descendant(
      of: find.byKey(const ValueKey('resource-allocation-warsaw')),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(city);
    await tester.tap(city);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('resource-details-resources')),
      findsNothing,
    );
    final ready = controller.state as GameSessionReady;
    expect(ready.interaction.selected, (col: 1, row: 1));
    expect(session.cityInspectionCalls, 1);
    expect(session.productionOverviewCalls, 1);
    expect(session.cityCommandCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Open trade preselects the partner and a resource trade', (
    tester,
  ) async {
    final (_, session) = await _mount(tester);
    final trade = find.descendant(
      of: find.byKey(const ValueKey('resource-partner-partner')),
      matching: find.byType(OutlinedButton),
    );
    await tester.ensureVisible(trade);
    await tester.tap(trade);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('resource-details-resources')),
      findsNothing,
    );
    final panel = tester.widget<DiplomacyPanel>(find.byType(DiplomacyPanel));
    expect(panel.initialTargetPlayerId, 'partner');
    expect(panel.initialTrade, isTrue);
    final submit = find.byKey(const ValueKey('submit-diplomacy-action'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(session.diplomacyCommandCalls, 1);
    final action = session.lastDiplomacyAction as OpenResourceTradeActionView;
    expect(action.targetPlayerId, 'partner');
    expect(tester.takeException(), isNull);
  });
}

Future<(MapPresentationController, FakeGameSession)> _mount(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scene = testMapScene(
    cols: 7,
    rows: 7,
  ).withPlayer(strategicResourcePlayer());
  final session = FakeGameSession.success(
    scene,
    cityInspection: testCityInspectionView(cityId: 'warsaw'),
    diplomacyResult: const DiplomacyCommandResultView.rejected(
      rejectionCode: DiplomacyRejectionCodeView.resourceTradeExportUnavailable,
    ),
  );
  final controller = MapPresentationController(
    capabilities: testGameSessionCapabilities(session),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    LocalizedTestApp(
      home: MapScreen(controller: controller, onOpenSettings: () {}),
    ),
  );
  await tester.pumpAndSettle();
  final resources = find.byKey(const ValueKey('resource-resources'));
  await tester.ensureVisible(resources);
  await tester.tap(resources);
  await tester.pumpAndSettle();
  return (controller, session);
}
