part of 'map_feedback_mapper.dart';

MapFloatingTextCueView _workerCue(
  AonwWorkerCompletedJobEvent event,
  MapEventIdentityView identity,
) {
  final delta = event.yieldDelta;
  return MapFloatingTextCueView(
    identity: identity,
    coordinate: (col: event.target.col, row: event.target.row),
    colorValue: 0xff86efac,
    content: switch (event.completion) {
      AonwRoadCompletion() => const MapMessageTextView(
        MapFeedbackMessageView.roadCompleted,
      ),
      AonwFieldImprovementCompletion(:final improvement) =>
        MapImprovementYieldTextView(
          improvement: FieldImprovementKind.values.byName(improvement.name),
          yieldDelta: YieldValueView(
            food: delta.food,
            production: delta.production,
            gold: delta.gold,
            defense: delta.defense,
          ),
        ),
    },
  );
}

MapFloatingTextCueView? _unitStatusCue(
  AonwUnitStatusEvent event,
  MapEventIdentityView identity,
  MapHexCoordinate? coordinate,
) {
  final MapFeedbackMessageView message;
  switch (event) {
    case AonwUnitKilledEvent():
      message = MapFeedbackMessageView.unitKilled;
    case AonwUnitRetreatedEvent():
      message = MapFeedbackMessageView.unitRetreated;
  }
  return coordinate == null
      ? null
      : MapFloatingTextCueView(
          identity: identity,
          coordinate: coordinate,
          content: MapMessageTextView(message),
          colorValue: message == MapFeedbackMessageView.unitKilled
              ? 0xfff87171
              : 0xfffbbf24,
          delay: const Duration(milliseconds: 180),
        );
}

List<MapFeedbackCueView> _artifactCues(
  AonwClientEvent event,
  MapEventIdentityView identity,
  String actor,
) {
  final (
    String owner,
    AonwCoordinate coordinate,
    MapFeedbackMessageView message,
    MapTextAnchorView anchor,
  )
  data;
  switch (event) {
    case AonwArtifactExcavationStartedEvent():
      data = (
        event.ownerPlayerId,
        event.coordinate,
        MapFeedbackMessageView.artifactExcavationStarted,
        MapUnitTextAnchorView(event.unitId),
      );
    case AonwArtifactCarriedEvent():
      data = (
        event.ownerPlayerId,
        event.coordinate,
        MapFeedbackMessageView.artifactCarried,
        MapUnitTextAnchorView(event.unitId),
      );
    case AonwArtifactStoredEvent():
      data = (
        event.ownerPlayerId,
        event.coordinate,
        MapFeedbackMessageView.artifactStored,
        MapCityTextAnchorView(event.cityId),
      );
    default:
      return const [];
  }
  if (data.$1 != actor) return const [];
  final coordinate = (col: data.$2.col, row: data.$2.row);
  return [
    MapParticleCueView(
      identity: identity,
      coordinate: coordinate,
      kind: MapParticleKindView.technologyResearched,
      colorValue: 0xffffd166,
    ),
    MapFloatingTextCueView(
      identity: identity,
      coordinate: coordinate,
      content: MapMessageTextView(data.$3),
      colorValue: 0xffffd166,
      style: MapFloatingTextStyleView.bubble,
      anchor: data.$4,
      delay: const Duration(milliseconds: 120),
    ),
  ];
}
