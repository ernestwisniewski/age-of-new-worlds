import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/infrastructure/worker_view_mapper.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = WorkerViewMapper();

  test('maps complete engine-owned options and bounded planner metrics', () {
    final worker = testVisibleUnit(kind: VisibleUnitKind.worker);
    final options = mapper.options(
      AonwWorkerOptionsResult(
        stamp: _stamp(),
        unitId: worker.id,
        coordinate: const AonwCoordinate(col: 0, row: 0),
        improvements: const [
          AonwWorkerImprovementOption(
            improvement: AonwFieldImprovementKind.farm,
            buildTurns: 3,
          ),
        ],
        canAssign: false,
        canBuildRoad: true,
        automation: _wireAutomation,
      ),
      map: testMapScene().map,
      worker: worker,
      expectedRevision: 0,
    );

    expect(options.improvements.single.improvement, FieldImprovementKind.farm);
    expect(options.canBuildRoad, isTrue);
    expect(options.automation?.target, (col: 1, row: 0));
    expect(options.automation?.metrics.tilesExamined, 3);
    expect(options.automation?.metrics.legalityEvaluations, 57);
    expect(options.automation?.metrics.routesPlanned, 2);
  });

  test('validates automation evidence against the displayed exact option', () {
    final option = _viewAutomation();
    final action = AutomateWorkerActionView(
      unitId: 'preview-commander',
      option: option,
    );
    final mapped = mapper.command(
      _acceptedAutomation(),
      map: testMapScene().map,
      action: action,
      expectedRevision: 0,
      currentRevision: 0,
    );

    expect(mapped.automation?.option.target, option.target);
    expect(mapped.automation?.moved, isFalse);
    expect(
      () => mapper.command(
        _acceptedAutomation(),
        map: testMapScene().map,
        action: AutomateWorkerActionView(
          unitId: action.unitId,
          option: WorkerAutomationOptionView(
            target: option.target,
            action: option.action,
            movementCostUnits: 4,
            metrics: option.metrics,
          ),
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('fails closed on stale identity and unrelated rejection', () {
    final worker = testVisibleUnit(kind: VisibleUnitKind.worker);
    expect(
      () => mapper.options(
        AonwWorkerOptionsResult(
          stamp: _stamp(revision: 1),
          unitId: worker.id,
          coordinate: const AonwCoordinate(col: 0, row: 0),
          improvements: const [],
          canAssign: false,
          canBuildRoad: false,
          automation: null,
        ),
        map: testMapScene().map,
        worker: worker,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.cityNotFound),
        map: testMapScene().map,
        action: const BuildRoadActionView(unitId: 'preview-commander'),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

const _wireAutomation = AonwWorkerAutomationOption(
  target: AonwCoordinate(col: 1, row: 0),
  action: AonwWorkerImproveAction(improvement: AonwFieldImprovementKind.farm),
  movementCostUnits: 2,
  metrics: AonwWorkerAutomationMetrics(
    tilesExamined: 3,
    legalityEvaluations: 57,
    routesPlanned: 2,
  ),
);

WorkerAutomationOptionView _viewAutomation() =>
    const WorkerAutomationOptionView(
      target: (col: 1, row: 0),
      action: ImproveWorkerAutomationActionView(
        improvement: FieldImprovementKind.farm,
      ),
      movementCostUnits: 2,
      metrics: WorkerAutomationMetricsView(
        tilesExamined: 3,
        legalityEvaluations: 57,
        routesPlanned: 2,
      ),
    );

AonwCommandResult _acceptedAutomation() => AonwCommandResult(
  stamp: _stamp(revision: 1),
  outcome: const AonwCommandAccepted(),
  events: const [],
  evidence: const AonwWorkerAutomationEvidence(
    unitId: 'preview-commander',
    option: _wireAutomation,
    movement: null,
  ),
  viewPatch: _patch(toRevision: 1),
);

AonwCommandResult _rejected(AonwCommandRejectionCode code) => AonwCommandResult(
  stamp: _stamp(),
  outcome: AonwCommandRejected(code),
  events: const [],
  evidence: null,
  viewPatch: _patch(),
);

AonwSessionStamp _stamp({int revision = 0}) => AonwSessionStamp(
  revision: revision,
  stateDigest: 'b' * 64,
  mapHash: 'a' * 64,
  rulesetHash: 'c' * 64,
);

AonwPlayerViewPatch _patch({int toRevision = 0}) => AonwPlayerViewPatch(
  fromRevision: 0,
  toRevision: toRevision,
  turn: 1,
  turnLifecycle: null,
  outcome: null,
  upsertedUnits: const [],
  removedUnitIds: const [],
  upsertedCities: const [],
  removedCityIds: const [],
  upsertedArtifacts: const [],
  removedArtifactIds: const [],
  upsertedFieldImprovements: const [],
  removedFieldImprovementCoordinates: const [],
  upsertedRoads: const [],
  removedRoadCoordinates: const [],
  pendingAction: null,
  cityFoundingDraft: null,
  diplomacy: null,
);
