import '../../cities/read_model/city_view.dart';
import '../../research/read_model/research_view.dart';
import 'hex_inspection_values.dart';
import 'map_view.dart';
import 'pending_action_view.dart';
import 'player_map_view.dart';

export 'hex_inspection_values.dart';

/// Disclosed facts and assessment provided by the authoritative engine.
final class HexInspectionView {
  HexInspectionView({
    required this.stamp,
    required this.coordinate,
    required this.baseTerrain,
    required List<MapTerrain> terrainTags,
    required List<MapResource> resources,
    required this.height,
    required this.hasRiver,
    required this.canFoundCityOnTerrain,
    required this.yieldValue,
    required this.score,
    required this.kind,
    required this.recommendation,
    required List<HexAssessmentTagView> tags,
    required this.improvementAccess,
    required List<HexImprovementOptionView> improvements,
  }) : terrainTags = List.unmodifiable(terrainTags),
       resources = List.unmodifiable(resources),
       tags = List.unmodifiable(tags),
       improvements = List.unmodifiable(improvements);

  final SessionStampView stamp;
  final MapHexCoordinate coordinate;
  final MapTerrain baseTerrain;
  final List<MapTerrain> terrainTags;
  final List<MapResource> resources;
  final int height;
  final bool hasRiver;

  /// Terrain suitability does not authorize a founding command.
  final bool canFoundCityOnTerrain;
  final YieldValueView yieldValue;
  final HexAssessmentScoreView score;
  final HexAssessmentKindView kind;
  final HexRecommendationView recommendation;
  final List<HexAssessmentTagView> tags;
  final HexImprovementAccessView improvementAccess;
  final List<HexImprovementOptionView> improvements;
}

final class HexAssessmentScoreView {
  const HexAssessmentScoreView({
    required this.city,
    required this.defense,
    required this.economy,
  });
  final int city;
  final int defense;
  final int economy;
}

final class HexImprovementOptionView {
  const HexImprovementOptionView({
    required this.kind,
    required this.requiredTechnology,
    required this.technologyUnlocked,
    required this.buildTurns,
    required this.yieldDelta,
  });
  final FieldImprovementKind kind;
  final TechnologyIdView? requiredTechnology;
  final bool technologyUnlocked;
  final int buildTurns;
  final YieldValueView yieldDelta;
}
