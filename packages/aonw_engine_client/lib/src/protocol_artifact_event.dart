part of 'protocol_event.dart';

final class AonwArtifactExcavationStartedEvent extends AonwClientEvent {
  const AonwArtifactExcavationStartedEvent({
    required this.artifactId,
    required this.ownerPlayerId,
    required this.unitId,
    required this.coordinate,
  }) : super(AonwClientEventKind.artifactExcavationStarted);

  final String artifactId;
  final String ownerPlayerId;
  final String unitId;
  final AonwCoordinate coordinate;
}

final class AonwArtifactCarriedEvent extends AonwClientEvent {
  const AonwArtifactCarriedEvent({
    required this.artifactId,
    required this.ownerPlayerId,
    required this.unitId,
    required this.coordinate,
  }) : super(AonwClientEventKind.artifactCarried);

  final String artifactId;
  final String ownerPlayerId;
  final String unitId;
  final AonwCoordinate coordinate;
}

final class AonwArtifactStoredEvent extends AonwClientEvent {
  const AonwArtifactStoredEvent({
    required this.artifactId,
    required this.ownerPlayerId,
    required this.sourceUnitId,
    required this.cityId,
    required this.coordinate,
  }) : super(AonwClientEventKind.artifactStored);

  final String artifactId;
  final String ownerPlayerId;
  final String? sourceUnitId;
  final String cityId;
  final AonwCoordinate coordinate;
}

AonwClientEvent? _artifactEvent(
  Map<String, Object?> value,
  AonwClientEventKind kind,
) => switch (kind) {
  AonwClientEventKind.artifactExcavationStarted =>
    AonwArtifactExcavationStartedEvent(
      artifactId: readString(value['artifactId'], 'excavated artifact id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'artifact owner id'),
      unitId: readString(value['unitId'], 'excavating unit id'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
    ),
  AonwClientEventKind.artifactCarried => AonwArtifactCarriedEvent(
    artifactId: readString(value['artifactId'], 'carried artifact id'),
    ownerPlayerId: readString(value['ownerPlayerId'], 'artifact owner id'),
    unitId: readString(value['unitId'], 'carrying unit id'),
    coordinate: AonwCoordinate.fromJson(value['coordinate']),
  ),
  AonwClientEventKind.artifactStored => AonwArtifactStoredEvent(
    artifactId: readString(value['artifactId'], 'stored artifact id'),
    ownerPlayerId: readString(value['ownerPlayerId'], 'artifact owner id'),
    sourceUnitId: readNullableString(value['sourceUnitId'], 'source unit id'),
    cityId: readString(value['cityId'], 'storing city id'),
    coordinate: AonwCoordinate.fromJson(value['coordinate']),
  ),
  _ => null,
};
