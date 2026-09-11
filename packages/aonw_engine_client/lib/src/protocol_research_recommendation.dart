part of 'protocol_query.dart';

enum AonwResearchRecommendationReason {
  boost,
  workerYields,
  unlocks,
  effects,
  nearCompletion;

  factory AonwResearchRecommendationReason.fromJson(Object? source) {
    final name = readString(source, 'research recommendation reason');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException(
        'Unknown research recommendation reason $name.',
      ),
    );
  }
}

final class AonwResearchRecommendation {
  AonwResearchRecommendation({
    required this.technology,
    required this.score,
    required this.turnsRemaining,
    required List<AonwResearchRecommendationReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  factory AonwResearchRecommendation.fromJson(Object? source) {
    final value = readObject(source, 'research recommendation');
    requireKeys(value, const {
      'technologyId',
      'score',
      'turnsRemaining',
      'reasons',
    }, 'research recommendation');
    final turns = value['turnsRemaining'] == null
        ? null
        : readInt(value['turnsRemaining'], 'research turn estimate');
    final rawReasons = value['reasons'];
    if (rawReasons is List &&
        rawReasons.length > AonwResearchRecommendationReason.values.length) {
      throw const FormatException('Too many recommendation reasons.');
    }
    final reasons = readList(
      rawReasons,
      'recommendation reasons',
      (item, _) => AonwResearchRecommendationReason.fromJson(item),
    );
    if (turns != null && (turns <= 0 || turns > 0xffffffff) ||
        reasons.length > AonwResearchRecommendationReason.values.length ||
        reasons.toSet().length != reasons.length) {
      throw const FormatException('Invalid research recommendation details.');
    }
    return AonwResearchRecommendation(
      technology: AonwTechnologyId.fromJson(value['technologyId']),
      score: readInt(value['score'], 'recommendation score'),
      turnsRemaining: turns,
      reasons: reasons,
    );
  }

  final AonwTechnologyId technology;
  final int score;
  final int? turnsRemaining;
  final List<AonwResearchRecommendationReason> reasons;
}

List<AonwResearchRecommendation> _researchRecommendations(Object? source) {
  if (source is List && source.length > 3) {
    throw const FormatException('Too many research recommendations.');
  }
  final entries = readList(
    source,
    'research recommendations',
    (item, _) => AonwResearchRecommendation.fromJson(item),
  );
  if (entries.length > 3 ||
      entries.map((entry) => entry.technology).toSet().length !=
          entries.length) {
    throw const FormatException('Invalid research recommendation list.');
  }
  for (var index = 1; index < entries.length; index++) {
    if (entries[index].score > entries[index - 1].score) {
      throw const FormatException('Research recommendations are not ordered.');
    }
  }
  return entries;
}
