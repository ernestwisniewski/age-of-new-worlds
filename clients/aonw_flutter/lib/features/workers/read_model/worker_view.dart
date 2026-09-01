import '../../map/read_model/map_view.dart';
import '../../map/read_model/pending_action_view.dart';
import '../../map/read_model/player_map_view.dart';

final class WorkerImprovementOptionView {
  const WorkerImprovementOptionView({
    required this.improvement,
    required this.buildTurns,
  });

  final FieldImprovementKind improvement;
  final int buildTurns;
}

sealed class WorkerAutomationActionView {
  const WorkerAutomationActionView();
}

final class ImproveWorkerAutomationActionView
    extends WorkerAutomationActionView {
  const ImproveWorkerAutomationActionView({required this.improvement});

  final FieldImprovementKind improvement;
}

final class AssignWorkerAutomationActionView
    extends WorkerAutomationActionView {
  const AssignWorkerAutomationActionView();
}

final class WorkerAutomationMetricsView {
  const WorkerAutomationMetricsView({
    required this.tilesExamined,
    required this.legalityEvaluations,
    required this.routesPlanned,
  });

  final int tilesExamined;
  final int legalityEvaluations;
  final int routesPlanned;
}

final class WorkerAutomationOptionView {
  const WorkerAutomationOptionView({
    required this.target,
    required this.action,
    required this.movementCostUnits,
    required this.metrics,
  });

  final MapHexCoordinate target;
  final WorkerAutomationActionView action;
  final int movementCostUnits;
  final WorkerAutomationMetricsView metrics;
}

final class WorkerOptionsView {
  WorkerOptionsView({
    required this.stamp,
    required this.unitId,
    required this.coordinate,
    required List<WorkerImprovementOptionView> improvements,
    required this.canAssign,
    required this.canBuildRoad,
    required this.automation,
  }) : improvements = List.unmodifiable(improvements);

  final SessionStampView stamp;
  final String unitId;
  final MapHexCoordinate coordinate;
  final List<WorkerImprovementOptionView> improvements;
  final bool canAssign;
  final bool canBuildRoad;
  final WorkerAutomationOptionView? automation;

  bool get isEmpty =>
      improvements.isEmpty && !canAssign && !canBuildRoad && automation == null;
}

sealed class WorkerJobView {
  const WorkerJobView({
    required this.target,
    required this.remainingTurns,
    required this.totalTurns,
  });

  final MapHexCoordinate target;
  final int remainingTurns;
  final int totalTurns;
}

final class FieldImprovementJobView extends WorkerJobView {
  const FieldImprovementJobView({
    required super.target,
    required this.improvement,
    required super.remainingTurns,
    required super.totalTurns,
  });

  final FieldImprovementKind improvement;
}

final class RoadConstructionJobView extends WorkerJobView {
  const RoadConstructionJobView({
    required super.target,
    required super.remainingTurns,
    required super.totalTurns,
  });
}

enum TransportConditionView { operational, pillaged }

final class FieldImprovementView {
  const FieldImprovementView({
    required this.coordinate,
    required this.improvement,
    this.eraColumn = 0,
  });

  final MapHexCoordinate coordinate;
  final FieldImprovementKind improvement;
  final int eraColumn;
}

final class RoadView {
  const RoadView({required this.coordinate, required this.condition});

  final MapHexCoordinate coordinate;
  final TransportConditionView condition;
}

sealed class WorkerActionView {
  const WorkerActionView({required this.unitId});

  final String unitId;
}

final class SelectWorkerImprovementActionView extends WorkerActionView {
  const SelectWorkerImprovementActionView({
    required super.unitId,
    required this.improvement,
  });

  final FieldImprovementKind improvement;
}

final class ConfirmWorkerImprovementActionView extends WorkerActionView {
  const ConfirmWorkerImprovementActionView({
    required super.unitId,
    required this.improvement,
  });

  final FieldImprovementKind improvement;
}

final class CancelWorkerJobActionView extends WorkerActionView {
  const CancelWorkerJobActionView({required super.unitId});
}

final class AssignWorkerToHexActionView extends WorkerActionView {
  const AssignWorkerToHexActionView({required super.unitId});
}

final class CancelWorkerAssignmentActionView extends WorkerActionView {
  const CancelWorkerAssignmentActionView({required super.unitId});
}

final class BuildRoadActionView extends WorkerActionView {
  const BuildRoadActionView({required super.unitId});
}

final class AutomateWorkerActionView extends WorkerActionView {
  const AutomateWorkerActionView({required super.unitId, required this.option});

  final WorkerAutomationOptionView option;
}

enum WorkerRejectionCodeView {
  staleRevision,
  matchFinished,
  workerNotFound,
  workerNotControlled,
  workerUnavailable,
  workerNoMovementPoints,
  workerQueuedPathActive,
  workerImprovementNotSelected,
  workerActionNotControlled,
  workerImprovementUnavailable,
  workerJobNotActive,
  workerAssignmentUnavailable,
  workerAssignmentNotActive,
  workerRoadUnavailable,
  roadConstructionExistingRoad,
  roadConstructionCity,
  roadConstructionEnemyTerritory,
  roadConstructionImpassableTerrain,
  workerAutomationNotActive,
  workerAutomationNoTarget,
  stateRevisionOverflow,
}

final class WorkerAutomationExecutionView {
  const WorkerAutomationExecutionView({
    required this.option,
    required this.moved,
  });

  final WorkerAutomationOptionView option;
  final bool moved;
}
