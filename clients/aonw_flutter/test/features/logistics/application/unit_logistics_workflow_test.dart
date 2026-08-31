import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('loads engine logistics options and correlates one command', () async {
    final unit = testVisibleUnit();
    final updatedPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1),
      turn: 1,
      pendingAction: null,
      units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
    );
    final session = FakeGameSession.success(
      testMapScene(units: [unit]),
      reachableResult: testReachableView(),
      logisticsOptions: UnitLogisticsOptionsView(
        stamp: testSessionStamp(),
        unitId: unit.id,
        autoExplore: const AutoExploreOptionView(
          target: (col: 1, row: 0),
          totalCostUnits: 4,
        ),
        merchantRouteDestinations: const [],
        merchantTravelDestinations: const [],
        detachments: const [],
      ),
      logisticsResult: UnitLogisticsCommandResultView.accepted(
        player: updatedPlayer,
        execution: const AutoExploreExecutionView(target: (col: 1, row: 0)),
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select(unit.coordinate);
    await pumpEventQueue();
    final options =
        (controller.state as GameSessionReady).interaction.unitLogistics;
    expect(options?.options?.autoExplore?.totalCostUnits, 4);
    expect(session.logisticsOptionCalls, 1);

    final action = AutoExploreActionView(unitId: unit.id);
    controller.executeUnitLogistics(action);
    controller.executeUnitLogistics(action);
    await pumpEventQueue();

    expect(session.logisticsCommandCalls, 1);
    expect(session.lastLogisticsExpectedRevision, 0);
    expect(session.lastLogisticsAction, same(action));
    final ready = controller.state as GameSessionReady;
    expect(ready.recipient.stamp.revision, 1);
    expect(ready.interaction.selected, (col: 1, row: 0));
  });
}
