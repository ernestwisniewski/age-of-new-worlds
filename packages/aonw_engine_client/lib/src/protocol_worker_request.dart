part of 'protocol.dart';

/// Worker-specific request constructors for the strict client protocol.
abstract final class AonwWorkerRequest {
  static AonwClientRequest options({
    required int expectedRevision,
    required String unitId,
  }) => AonwClientRequest._({
    'type': 'query',
    'query': {
      'type': 'workerOptions',
      'expectedRevision': expectedRevision,
      'unitId': unitId,
    },
  });

  static AonwClientRequest selectImprovement({
    required int expectedRevision,
    required String unitId,
    required AonwFieldImprovementKind improvement,
  }) => _workerCommand('selectWorkerImprovement', expectedRevision, unitId, {
    'improvement': improvement.name,
  });

  static AonwClientRequest confirmImprovement({
    required int expectedRevision,
    required String unitId,
    AonwFieldImprovementKind? improvement,
  }) => _workerCommand('confirmWorkerImprovement', expectedRevision, unitId, {
    'improvement': improvement?.name,
  });

  static AonwClientRequest cancelJob({
    required int expectedRevision,
    required String unitId,
  }) => _workerCommand('cancelWorkerJob', expectedRevision, unitId);

  static AonwClientRequest assignToHex({
    required int expectedRevision,
    required String unitId,
  }) => _workerCommand('assignWorkerToHex', expectedRevision, unitId);

  static AonwClientRequest cancelAssignment({
    required int expectedRevision,
    required String unitId,
  }) => _workerCommand('cancelWorkerAssignment', expectedRevision, unitId);

  static AonwClientRequest buildRoad({
    required int expectedRevision,
    required String unitId,
  }) => _workerCommand('buildRoad', expectedRevision, unitId);

  static AonwClientRequest automate({
    required int expectedRevision,
    required String unitId,
  }) => _workerCommand('automateWorker', expectedRevision, unitId);

  static AonwClientRequest _workerCommand(
    String type,
    int expectedRevision,
    String unitId, [
    Map<String, Object?> fields = const {},
  ]) => AonwClientRequest._({
    'type': 'dispatch',
    'command': {
      'type': type,
      'expectedRevision': expectedRevision,
      'unitId': unitId,
      ...fields,
    },
  });
}
