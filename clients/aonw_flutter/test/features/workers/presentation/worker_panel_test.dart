import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:aonw_flutter/features/workers/presentation/worker_panel.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('shows progress semantics and confirms exact pending selection', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    WorkerActionView? dispatched;
    final unit = testVisibleUnit(
      kind: VisibleUnitKind.worker,
      workerBuildCharges: 1,
      workerJob: const FieldImprovementJobView(
        target: (col: 0, row: 0),
        improvement: FieldImprovementKind.farm,
        remainingTurns: 2,
        totalTurns: 3,
      ),
    );
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: WorkerPanel(
              state: WorkerState(unitId: unit.id, options: _options(unit.id)),
              unit: unit,
              pendingAction: PendingWorkerActionSelectionView(
                unitId: unit.id,
                improvement: FieldImprovementKind.farm,
              ),
              onAction: (value) => dispatched = value,
            ),
          ),
        ),
      ),
    );

    final progress = tester.getSemantics(
      find.byKey(const ValueKey('worker-job-progress')),
    );
    expect(progress.label, contains('Progress'));
    expect(progress.value, '1 / 3');
    await tester.tap(find.textContaining('Confirm improvement'));
    expect(dispatched, isA<ConfirmWorkerImprovementActionView>());
    expect(
      (dispatched! as ConfirmWorkerImprovementActionView).improvement,
      FieldImprovementKind.farm,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('displays exact bounded automation evidence and dispatches it', (
    tester,
  ) async {
    WorkerActionView? dispatched;
    final unit = testVisibleUnit(kind: VisibleUnitKind.worker);
    const option = WorkerAutomationOptionView(
      target: (col: 1, row: 0),
      action: ImproveWorkerAutomationActionView(
        improvement: FieldImprovementKind.mine,
      ),
      movementCostUnits: 4,
      metrics: WorkerAutomationMetricsView(
        tilesExamined: 3,
        legalityEvaluations: 57,
        routesPlanned: 2,
      ),
    );
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: WorkerPanel(
            state: WorkerState(
              unitId: unit.id,
              options: _options(unit.id, automation: option),
              lastAutomation: const WorkerAutomationExecutionView(
                option: option,
                moved: false,
              ),
            ),
            unit: unit,
            pendingAction: null,
            onAction: (value) => dispatched = value,
          ),
        ),
      ),
    );

    expect(find.textContaining('3 / 57 / 2'), findsOneWidget);
    await tester.tap(find.textContaining('Automate'));
    expect(dispatched, isA<AutomateWorkerActionView>());
    expect((dispatched! as AutomateWorkerActionView).option, same(option));
  });
}

WorkerOptionsView _options(
  String unitId, {
  WorkerAutomationOptionView? automation,
}) => WorkerOptionsView(
  stamp: testSessionStamp(),
  unitId: unitId,
  coordinate: (col: 0, row: 0),
  improvements: const [
    WorkerImprovementOptionView(
      improvement: FieldImprovementKind.farm,
      buildTurns: 3,
    ),
  ],
  canAssign: false,
  canBuildRoad: true,
  automation: automation,
);
