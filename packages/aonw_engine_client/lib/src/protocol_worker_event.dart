part of 'protocol_event.dart';

final class AonwWorkerCompletedJobEvent extends AonwClientEvent {
  const AonwWorkerCompletedJobEvent({
    required this.unitId,
    required this.target,
    required this.completion,
    required this.yieldDelta,
  }) : super(AonwClientEventKind.workerCompletedJob);

  final String unitId;
  final AonwCoordinate target;
  final AonwWorkerCompletion completion;
  final AonwYieldValue yieldDelta;
}

sealed class AonwWorkerCompletion {
  const AonwWorkerCompletion();
}

final class AonwFieldImprovementCompletion extends AonwWorkerCompletion {
  const AonwFieldImprovementCompletion(this.improvement);

  final AonwFieldImprovementKind improvement;
}

final class AonwRoadCompletion extends AonwWorkerCompletion {
  const AonwRoadCompletion();
}

AonwClientEvent? _workerEvent(
  Map<String, Object?> value,
  AonwClientEventKind kind,
) {
  if (kind != AonwClientEventKind.workerCompletedJob) return null;
  final completion = readObject(value['completion'], 'worker completion');
  return AonwWorkerCompletedJobEvent(
    unitId: readString(value['unitId'], 'completed worker id'),
    target: AonwCoordinate.fromJson(value['target']),
    yieldDelta: AonwYieldValue.fromJson(value['yieldDelta']),
    completion: completion['type'] == 'road'
        ? const AonwRoadCompletion()
        : AonwFieldImprovementCompletion(
            AonwFieldImprovementKind.fromJson(completion['improvement']),
          ),
  );
}
