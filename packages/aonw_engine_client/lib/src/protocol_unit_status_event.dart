part of 'protocol_event.dart';

sealed class AonwUnitStatusEvent extends AonwClientEvent {
  const AonwUnitStatusEvent(
    super.kind, {
    required this.attackerUnitId,
    required this.target,
    required this.subjectUnitId,
  });

  final String attackerUnitId;
  final AonwCombatTarget target;
  final String subjectUnitId;
}

final class AonwUnitKilledEvent extends AonwUnitStatusEvent {
  const AonwUnitKilledEvent({
    required super.attackerUnitId,
    required super.target,
    required super.subjectUnitId,
  }) : super(AonwClientEventKind.unitKilled);
}

final class AonwUnitRetreatedEvent extends AonwUnitStatusEvent {
  const AonwUnitRetreatedEvent({
    required super.attackerUnitId,
    required super.target,
    required super.subjectUnitId,
  }) : super(AonwClientEventKind.unitRetreated);
}

AonwClientEvent? _unitStatusEvent(
  Map<String, Object?> value,
  AonwClientEventKind kind,
) => switch (kind) {
  AonwClientEventKind.unitKilled => AonwUnitKilledEvent(
    attackerUnitId: readString(value['attackerUnitId'], 'attacking unit id'),
    target: AonwCombatTarget.fromJson(value['target']),
    subjectUnitId: readString(value['subjectUnitId'], 'killed unit id'),
  ),
  AonwClientEventKind.unitRetreated => AonwUnitRetreatedEvent(
    attackerUnitId: readString(value['attackerUnitId'], 'attacking unit id'),
    target: AonwCombatTarget.fromJson(value['target']),
    subjectUnitId: readString(value['subjectUnitId'], 'retreating unit id'),
  ),
  _ => null,
};
