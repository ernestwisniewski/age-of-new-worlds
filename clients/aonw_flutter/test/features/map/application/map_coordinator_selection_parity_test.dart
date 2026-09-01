import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('previews an engine-owned route beyond current-turn reach', () async {
    final scene = testMapScene(cols: 4, units: [testVisibleUnit()]);
    final session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      routeResult: _multiTurnRoute(),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select((col: 0, row: 0));
    await pumpEventQueue();
    controller.select((col: 3, row: 0));
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.interaction.route?.target, (col: 3, row: 0));
    expect(ready.interaction.route?.totalCostUnits, 20);
    expect(session.combatPreviewCalls, 0);
  });

  test('keeps a visible foreign target on the combat query path', () async {
    final scene = testMapScene(
      units: [
        testVisibleUnit(),
        testVisibleUnit(
          id: 'foreign',
          ownerPlayerId: 'foreign-player',
          coordinate: (col: 2, row: 0),
        ),
      ],
    );
    final session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      combatPreviewResult: testCombatPreviewView(defender: (col: 2, row: 0)),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select((col: 0, row: 0));
    await pumpEventQueue();
    controller.select((col: 2, row: 0));
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.interaction.combat?.preview, isNotNull);
    expect(session.combatPreviewCalls, 1);
    expect(session.lastCombatDefender, (col: 2, row: 0));
    expect(ready.interaction.route, isNull);
  });
}

RoutePlanView _multiTurnRoute() => RoutePlanView(
  stamp: testSessionStamp(),
  unitId: 'preview-commander',
  target: const (col: 3, row: 0),
  destination: const (col: 3, row: 0),
  totalCostUnits: 20,
  availableMovementUnits: 12,
  remainingMovementUnits: 0,
  steps: const [
    MovementStepView(
      coordinate: (col: 0, row: 0),
      enterCostUnits: 0,
      cumulativeCostUnits: 0,
    ),
    MovementStepView(
      coordinate: (col: 1, row: 0),
      enterCostUnits: 4,
      cumulativeCostUnits: 4,
    ),
    MovementStepView(
      coordinate: (col: 2, row: 0),
      enterCostUnits: 8,
      cumulativeCostUnits: 12,
    ),
    MovementStepView(
      coordinate: (col: 3, row: 0),
      enterCostUnits: 8,
      cumulativeCostUnits: 20,
    ),
  ],
);
