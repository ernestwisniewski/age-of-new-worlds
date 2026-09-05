part of 'protocol_event.dart';

final class AonwTechnologyResearchedEvent extends AonwClientEvent {
  const AonwTechnologyResearchedEvent({
    required this.playerId,
    required this.technology,
  }) : super(AonwClientEventKind.technologyResearched);

  final String playerId;
  final AonwTechnologyId technology;
}

final class AonwResearchPointsGainedEvent extends AonwClientEvent {
  const AonwResearchPointsGainedEvent({
    required this.playerId,
    required this.points,
  }) : super(AonwClientEventKind.researchPointsGained);

  final String playerId;
  final int points;
}

AonwClientEvent? _researchEvent(
  Map<String, Object?> value,
  AonwClientEventKind kind,
) => switch (kind) {
  AonwClientEventKind.technologyResearched => AonwTechnologyResearchedEvent(
    playerId: readString(value['playerId'], 'research player id'),
    technology: AonwTechnologyId.fromJson(value['technologyId']),
  ),
  AonwClientEventKind.researchPointsGained => AonwResearchPointsGainedEvent(
    playerId: readString(value['playerId'], 'research player id'),
    points: readInt(value['points'], 'gained research points'),
  ),
  _ => null,
};
