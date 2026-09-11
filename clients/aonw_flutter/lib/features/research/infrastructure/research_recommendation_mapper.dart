part of 'research_view_mapper.dart';

List<ResearchRecommendationView> _recommendations(
  AonwResearchOptionsResult wire,
) {
  final entries = wire.recommendations;
  final available = wire.options
      .where(
        (option) => option.availability == AonwTechnologyAvailability.available,
      )
      .map((option) => option.technology)
      .toSet();
  final seen = <AonwTechnologyId>{};
  int? previousScore;
  if (entries.length > 3) {
    throw const FormatException('Too many research recommendations.');
  }
  for (final entry in entries) {
    _validateRecommendationDetails(entry);
    if (!available.contains(entry.technology) ||
        !seen.add(entry.technology) ||
        previousScore != null && entry.score > previousScore) {
      throw const FormatException(
        'Invalid research recommendation projection.',
      );
    }
    previousScore = entry.score;
  }
  return [
    for (final entry in entries)
      ResearchRecommendationView(
        technology: TechnologyIdView.values.byName(entry.technology.name),
        score: entry.score,
        turnsRemaining: entry.turnsRemaining,
        reasons: [
          for (final reason in entry.reasons)
            ResearchRecommendationReasonView.values.byName(reason.name),
        ],
      ),
  ];
}

void _validateRecommendationDetails(AonwResearchRecommendation entry) {
  final turns = entry.turnsRemaining;
  if (turns != null && (turns <= 0 || turns > 0xffffffff) ||
      entry.reasons.toSet().length != entry.reasons.length) {
    throw const FormatException('Invalid research recommendation details.');
  }
}
