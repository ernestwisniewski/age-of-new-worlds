import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_session_port.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'previews locally and correlates exactly one confirmed construction',
    () async {
      final worker = testVisibleUnit(kind: VisibleUnitKind.worker);
      final options = _options(worker);
      final updatedPlayer = PlayerMapView.preview(
        pendingAction: null,
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1),
        turn: 1,
        units: [
          testVisibleUnit(
            kind: VisibleUnitKind.worker,
            workerJob: const FieldImprovementJobView(
              target: (col: 0, row: 0),
              improvement: FieldImprovementKind.farm,
              remainingTurns: 3,
              totalTurns: 3,
            ),
          ),
        ],
      );
      final session = FakeGameSession.success(
        testMapScene(units: [worker]),
        reachableResult: testReachableView(unitId: worker.id),
        workerOptionsResult: options,
        workerResult: WorkerCommandResultView.accepted(
          player: updatedPlayer,
          automation: null,
        ),
      );
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.select(worker.coordinate);
      await pumpEventQueue();
      final loaded = (controller.state as GameSessionReady).interaction.worker;
      expect(loaded?.options?.improvements.single.buildTurns, 3);
      expect(session.workerOptionCalls, 1);

      final initial = controller.state as GameSessionReady;
      expect(loaded?.actionsOpen, isFalse);
      controller.setWorkerActionsOpen(true);
      controller.previewWorkerImprovement(worker.id, FieldImprovementKind.farm);
      expect(session.workerCommandCalls, 0);
      expect(
        (controller.state as GameSessionReady).recipient,
        same(initial.recipient),
      );
      expect(
        (controller.state as GameSessionReady)
            .interaction
            .worker
            ?.previewedImprovement,
        FieldImprovementKind.farm,
      );
      final action = ConfirmWorkerImprovementActionView(
        unitId: worker.id,
        improvement: FieldImprovementKind.farm,
      );
      controller.executeWorkerAction(action);
      controller.setWorkerActionsOpen(false);
      expect(
        (controller.state as GameSessionReady).interaction.worker?.actionsOpen,
        isTrue,
      );
      controller.executeWorkerAction(action);
      await pumpEventQueue();

      expect(session.workerCommandCalls, 1);
      expect(session.lastWorkerExpectedRevision, 0);
      expect(session.lastWorkerAction, same(action));
      final ready = controller.state as GameSessionReady;
      expect(ready.recipient.stamp.revision, 1);
      expect(ready.recipient.pendingAction, isNull);
      expect(
        ready.recipient.controlledUnitById(worker.id)?.workerJob,
        isA<FieldImprovementJobView>(),
      );
      expect(ready.interaction.worker?.actionsOpen, isFalse);
      expect(ready.interaction.worker?.previewedImprovement, isNull);
    },
  );

  test('keeps rejection typed and does not apply a client fallback', () async {
    final worker = testVisibleUnit(kind: VisibleUnitKind.worker);
    final session = FakeGameSession.success(
      testMapScene(units: [worker]),
      reachableResult: testReachableView(unitId: worker.id),
      workerOptionsResult: _options(worker),
      workerResult: const WorkerCommandResultView.rejected(
        rejectionCode: WorkerRejectionCodeView.workerRoadUnavailable,
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select(worker.coordinate);
    await pumpEventQueue();
    controller.executeWorkerAction(BuildRoadActionView(unitId: worker.id));
    await pumpEventQueue();

    final state = (controller.state as GameSessionReady).interaction.worker!;
    expect(state.failure?.code, WorkerFailureCode.rejected);
    expect(
      state.failure?.rejectionCode,
      WorkerRejectionCodeView.workerRoadUnavailable,
    );
    expect((controller.state as GameSessionReady).recipient.stamp.revision, 0);
  });
}

WorkerOptionsView _options(VisibleUnitView worker) => WorkerOptionsView(
  stamp: testSessionStamp(),
  unitId: worker.id,
  coordinate: worker.coordinate,
  improvements: const [
    WorkerImprovementOptionView(
      improvement: FieldImprovementKind.farm,
      buildTurns: 3,
    ),
  ],
  canAssign: false,
  canBuildRoad: true,
  automation: const WorkerAutomationOptionView(
    target: (col: 1, row: 0),
    action: ImproveWorkerAutomationActionView(
      improvement: FieldImprovementKind.farm,
    ),
    movementCostUnits: 4,
    metrics: WorkerAutomationMetricsView(
      tilesExamined: 2,
      legalityEvaluations: 10,
      routesPlanned: 1,
    ),
  ),
);
