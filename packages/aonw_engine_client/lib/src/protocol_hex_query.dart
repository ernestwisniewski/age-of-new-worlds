part of 'protocol_query.dart';

final class AonwHexInspectionResult extends AonwQueryResult {
  const AonwHexInspectionResult({
    required this.stamp,
    required this.inspection,
  });
  factory AonwHexInspectionResult.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'stamp',
      'inspection',
    }, 'hex inspection result');
    return AonwHexInspectionResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      inspection: AonwHexInspection.fromJson(value['inspection']),
    );
  }
  final AonwSessionStamp stamp;
  final AonwHexInspection inspection;
}

final class AonwHexInspection {
  AonwHexInspection({
    required this.coordinate,
    required this.baseTerrain,
    required List<AonwMapTerrain> terrainTags,
    required List<AonwMapResource> resources,
    required this.height,
    required this.hasRiver,
    required this.canFoundCityOnTerrain,
    required this.yieldValue,
    required this.score,
    required this.kind,
    required this.recommendation,
    required List<AonwHexAssessmentTag> tags,
    required this.improvementAccess,
    required List<AonwHexImprovementOption> improvements,
  }) : terrainTags = List.unmodifiable(terrainTags),
       resources = List.unmodifiable(resources),
       tags = List.unmodifiable(tags),
       improvements = List.unmodifiable(improvements);

  factory AonwHexInspection.fromJson(Object? source) {
    final value = readObject(source, 'AonwHexInspection');
    requireKeys(value, const {
      'coordinate',
      'baseTerrain',
      'terrainTags',
      'resources',
      'height',
      'hasRiver',
      'canFoundCityOnTerrain',
      'yieldValue',
      'score',
      'kind',
      'recommendation',
      'tags',
      'improvementAccess',
      'improvements',
    }, 'AonwHexInspection');
    return AonwHexInspection(
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      baseTerrain: AonwMapTerrain.fromJson(value['baseTerrain']),
      terrainTags: readList(
        value['terrainTags'],
        'terrain tags',
        (item, _) => AonwMapTerrain.fromJson(item),
      ),
      resources: readList(
        value['resources'],
        'resources',
        (item, _) => AonwMapResource.fromJson(item),
      ),
      height: readUnsigned(value['height'], 'height'),
      hasRiver: readBool(value['hasRiver'], 'has river'),
      canFoundCityOnTerrain: readBool(
        value['canFoundCityOnTerrain'],
        'can found city on terrain',
      ),
      yieldValue: AonwYieldValue.fromJson(value['yieldValue']),
      score: AonwHexAssessmentScore.fromJson(value['score']),
      kind: AonwHexAssessmentKind.fromJson(value['kind']),
      recommendation: AonwHexRecommendation.fromJson(value['recommendation']),
      tags: readList(
        value['tags'],
        'assessment tags',
        (item, _) => AonwHexAssessmentTag.fromJson(item),
      ),
      improvementAccess: AonwHexImprovementAccess.fromJson(
        value['improvementAccess'],
      ),
      improvements: readList(
        value['improvements'],
        'hex improvements',
        (item, _) => AonwHexImprovementOption.fromJson(item),
      ),
    );
  }

  final AonwCoordinate coordinate;
  final AonwMapTerrain baseTerrain;
  final List<AonwMapTerrain> terrainTags;
  final List<AonwMapResource> resources;
  final int height;
  final bool hasRiver;
  final bool canFoundCityOnTerrain;
  final AonwYieldValue yieldValue;
  final AonwHexAssessmentScore score;
  final AonwHexAssessmentKind kind;
  final AonwHexRecommendation recommendation;
  final List<AonwHexAssessmentTag> tags;
  final AonwHexImprovementAccess improvementAccess;
  final List<AonwHexImprovementOption> improvements;
}

final class AonwHexAssessmentScore {
  const AonwHexAssessmentScore({
    required this.city,
    required this.defense,
    required this.economy,
  });

  factory AonwHexAssessmentScore.fromJson(Object? source) {
    final value = readObject(source, 'AonwHexAssessmentScore');
    requireKeys(value, const {
      'city',
      'defense',
      'economy',
    }, 'AonwHexAssessmentScore');
    return AonwHexAssessmentScore(
      city: readInt(value['city'], 'hex city score'),
      defense: readInt(value['defense'], 'hex defense score'),
      economy: readInt(value['economy'], 'hex economy score'),
    );
  }

  final int city;
  final int defense;
  final int economy;
}

final class AonwHexImprovementOption {
  const AonwHexImprovementOption({
    required this.kind,
    required this.requiredTechnology,
    required this.technologyUnlocked,
    required this.buildTurns,
    required this.yieldDelta,
  });

  factory AonwHexImprovementOption.fromJson(Object? source) {
    final value = readObject(source, 'AonwHexImprovementOption');
    requireKeys(value, const {
      'kind',
      'requiredTechnology',
      'technologyUnlocked',
      'buildTurns',
      'yieldDelta',
    }, 'AonwHexImprovementOption');
    return AonwHexImprovementOption(
      kind: AonwFieldImprovementKind.fromJson(value['kind']),
      requiredTechnology: value['requiredTechnology'] == null
          ? null
          : AonwTechnologyId.fromJson(value['requiredTechnology']),
      technologyUnlocked: readBool(
        value['technologyUnlocked'],
        'technology unlocked',
      ),
      buildTurns: readUnsigned(value['buildTurns'], 'build turns'),
      yieldDelta: AonwYieldValue.fromJson(value['yieldDelta']),
    );
  }

  final AonwFieldImprovementKind kind;
  final AonwTechnologyId? requiredTechnology;
  final bool technologyUnlocked;
  final int buildTurns;
  final AonwYieldValue yieldDelta;
}
