import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../map/read_model/map_view.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/worker_view.dart';

final class WorkerViewMapper {
  const WorkerViewMapper();

  WorkerOptionsView options(
    AonwWorkerOptionsResult wire, {
    required MapView map,
    required VisibleUnitView worker,
    required int expectedRevision,
  }) {
    _validateStamp(wire.stamp, map: map, revision: expectedRevision);
    final coordinate = _coordinate(wire.coordinate, map);
    if (wire.unitId != worker.id || coordinate != worker.coordinate) {
      throw const FormatException('Worker options mismatch request.');
    }
    final improvements = <WorkerImprovementOptionView>[];
    final seen = <FieldImprovementKind>{};
    for (final option in wire.improvements) {
      final improvement = _improvement(option.improvement);
      if (!seen.add(improvement) || option.buildTurns == 0) {
        throw const FormatException('Worker improvement options are invalid.');
      }
      improvements.add(
        WorkerImprovementOptionView(
          improvement: improvement,
          buildTurns: option.buildTurns,
        ),
      );
    }
    return WorkerOptionsView(
      stamp: _stamp(wire.stamp),
      unitId: wire.unitId,
      coordinate: coordinate,
      improvements: improvements,
      canAssign: wire.canAssign,
      canBuildRoad: wire.canBuildRoad,
      automation: wire.automation == null
          ? null
          : _automationOption(wire.automation!, map),
    );
  }

  WorkerJobView? job(AonwWorkerJobView? wire, MapView map) => switch (wire) {
    null => null,
    AonwFieldImprovementJobView() => FieldImprovementJobView(
      target: _coordinate(wire.target, map),
      improvement: _improvement(wire.improvement),
      remainingTurns: _remainingTurns(wire),
      totalTurns: wire.totalTurns,
    ),
    AonwRoadConstructionJobView() => RoadConstructionJobView(
      target: _coordinate(wire.target, map),
      remainingTurns: _remainingTurns(wire),
      totalTurns: wire.totalTurns,
    ),
  };

  FieldImprovementView fieldImprovement(
    AonwFieldImprovementView wire,
    MapView map,
  ) => FieldImprovementView(
    coordinate: _coordinate(wire.coordinate, map),
    improvement: _improvement(wire.improvement),
  );

  RoadView road(AonwRoadView wire, MapView map) => RoadView(
    coordinate: _coordinate(wire.coordinate, map),
    condition: TransportConditionView.values.byName(wire.condition.name),
  );

  ({
    WorkerRejectionCodeView? rejection,
    WorkerAutomationExecutionView? automation,
  })
  command(
    AonwCommandResult wire, {
    required MapView map,
    required WorkerActionView action,
    required int expectedRevision,
    required int currentRevision,
  }) {
    _validateStamp(
      wire.stamp,
      map: map,
      revision: wire.accepted ? expectedRevision + 1 : currentRevision,
    );
    if (!wire.accepted) return _rejected(wire);
    if (wire.rejection != null) {
      throw const FormatException('Accepted worker result is rejected.');
    }
    final evidence = wire.evidence;
    if (action case final AutomateWorkerActionView automationAction) {
      if (evidence is! AonwWorkerAutomationEvidence ||
          evidence.unitId != action.unitId) {
        throw const FormatException('Worker automation evidence is missing.');
      }
      final option = _automationOption(evidence.option, map);
      if (!_sameAutomation(option, automationAction.option)) {
        throw const FormatException(
          'Worker automation evidence mismatches option.',
        );
      }
      final movement = evidence.movement;
      if (movement != null && movement.unitId != action.unitId) {
        throw const FormatException(
          'Worker automation movement mismatches unit.',
        );
      }
      return (
        rejection: null,
        automation: WorkerAutomationExecutionView(
          option: option,
          moved: movement != null,
        ),
      );
    }
    if (evidence != null) {
      throw const FormatException(
        'Worker command contains unrelated evidence.',
      );
    }
    return (rejection: null, automation: null);
  }
}

({
  WorkerRejectionCodeView? rejection,
  WorkerAutomationExecutionView? automation,
})
_rejected(AonwCommandResult wire) {
  if (wire.rejection == null ||
      wire.events.isNotEmpty ||
      wire.evidence != null) {
    throw const FormatException('Rejected worker result has residue.');
  }
  final rejection = _rejections[wire.rejection!];
  if (rejection == null) {
    throw const FormatException('Unrelated worker rejection code.');
  }
  return (rejection: rejection, automation: null);
}

int _remainingTurns(AonwWorkerJobView wire) {
  if (wire.totalTurns == 0 || wire.remainingTurns > wire.totalTurns) {
    throw const FormatException('Worker job progress is invalid.');
  }
  return wire.remainingTurns;
}

WorkerAutomationOptionView _automationOption(
  AonwWorkerAutomationOption wire,
  MapView map,
) => WorkerAutomationOptionView(
  target: _coordinate(wire.target, map),
  action: switch (wire.action) {
    AonwWorkerImproveAction(:final improvement) =>
      ImproveWorkerAutomationActionView(improvement: _improvement(improvement)),
    AonwWorkerAssignAction() => const AssignWorkerAutomationActionView(),
  },
  movementCostUnits: wire.movementCostUnits,
  metrics: WorkerAutomationMetricsView(
    tilesExamined: wire.metrics.tilesExamined,
    legalityEvaluations: wire.metrics.legalityEvaluations,
    routesPlanned: wire.metrics.routesPlanned,
  ),
);

bool _sameAutomation(
  WorkerAutomationOptionView left,
  WorkerAutomationOptionView right,
) =>
    left.target == right.target &&
    left.movementCostUnits == right.movementCostUnits &&
    left.metrics.tilesExamined == right.metrics.tilesExamined &&
    left.metrics.legalityEvaluations == right.metrics.legalityEvaluations &&
    left.metrics.routesPlanned == right.metrics.routesPlanned &&
    _sameAutomationAction(left.action, right.action);

bool _sameAutomationAction(
  WorkerAutomationActionView left,
  WorkerAutomationActionView right,
) => switch ((left, right)) {
  (
    ImproveWorkerAutomationActionView(improvement: final leftImprovement),
    ImproveWorkerAutomationActionView(improvement: final rightImprovement),
  ) =>
    leftImprovement == rightImprovement,
  (AssignWorkerAutomationActionView(), AssignWorkerAutomationActionView()) =>
    true,
  _ => false,
};

FieldImprovementKind _improvement(AonwFieldImprovementKind value) =>
    FieldImprovementKind.values.byName(value.name);

MapHexCoordinate _coordinate(AonwCoordinate value, MapView map) {
  final coordinate = (col: value.col, row: value.row);
  if (!map.contains(coordinate)) {
    throw const FormatException('Worker coordinate is outside the map.');
  }
  return coordinate;
}

SessionStampView _stamp(AonwSessionStamp value) => SessionStampView(
  revision: value.revision,
  stateDigest: value.stateDigest,
  mapHash: value.mapHash,
  rulesetHash: value.rulesetHash,
);

void _validateStamp(
  AonwSessionStamp value, {
  required MapView map,
  required int revision,
}) {
  final digest = RegExp(r'^[0-9a-f]{64}$');
  if (value.revision != revision ||
      value.mapHash != map.contentHash ||
      !digest.hasMatch(value.stateDigest) ||
      !digest.hasMatch(value.mapHash) ||
      !digest.hasMatch(value.rulesetHash)) {
    throw const FormatException('Worker session identity is stale.');
  }
}

const _rejections = <AonwCommandRejectionCode, WorkerRejectionCodeView>{
  AonwCommandRejectionCode.staleRevision: WorkerRejectionCodeView.staleRevision,
  AonwCommandRejectionCode.matchFinished: WorkerRejectionCodeView.matchFinished,
  AonwCommandRejectionCode.workerNotFound:
      WorkerRejectionCodeView.workerNotFound,
  AonwCommandRejectionCode.workerNotControlled:
      WorkerRejectionCodeView.workerNotControlled,
  AonwCommandRejectionCode.workerUnavailable:
      WorkerRejectionCodeView.workerUnavailable,
  AonwCommandRejectionCode.workerNoMovementPoints:
      WorkerRejectionCodeView.workerNoMovementPoints,
  AonwCommandRejectionCode.workerQueuedPathActive:
      WorkerRejectionCodeView.workerQueuedPathActive,
  AonwCommandRejectionCode.workerImprovementNotSelected:
      WorkerRejectionCodeView.workerImprovementNotSelected,
  AonwCommandRejectionCode.workerActionNotControlled:
      WorkerRejectionCodeView.workerActionNotControlled,
  AonwCommandRejectionCode.workerImprovementUnavailable:
      WorkerRejectionCodeView.workerImprovementUnavailable,
  AonwCommandRejectionCode.workerJobNotActive:
      WorkerRejectionCodeView.workerJobNotActive,
  AonwCommandRejectionCode.workerAssignmentUnavailable:
      WorkerRejectionCodeView.workerAssignmentUnavailable,
  AonwCommandRejectionCode.workerAssignmentNotActive:
      WorkerRejectionCodeView.workerAssignmentNotActive,
  AonwCommandRejectionCode.workerRoadUnavailable:
      WorkerRejectionCodeView.workerRoadUnavailable,
  AonwCommandRejectionCode.roadConstructionExistingRoad:
      WorkerRejectionCodeView.roadConstructionExistingRoad,
  AonwCommandRejectionCode.roadConstructionCity:
      WorkerRejectionCodeView.roadConstructionCity,
  AonwCommandRejectionCode.roadConstructionEnemyTerritory:
      WorkerRejectionCodeView.roadConstructionEnemyTerritory,
  AonwCommandRejectionCode.roadConstructionImpassableTerrain:
      WorkerRejectionCodeView.roadConstructionImpassableTerrain,
  AonwCommandRejectionCode.workerAutomationNotActive:
      WorkerRejectionCodeView.workerAutomationNotActive,
  AonwCommandRejectionCode.workerAutomationNoTarget:
      WorkerRejectionCodeView.workerAutomationNoTarget,
  AonwCommandRejectionCode.stateRevisionOverflow:
      WorkerRejectionCodeView.stateRevisionOverflow,
};
