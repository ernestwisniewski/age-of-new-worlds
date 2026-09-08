import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../../cities/read_model/city_view.dart';
import '../../research/read_model/research_view.dart';
import '../read_model/hex_inspection_view.dart';
import '../read_model/map_view.dart';
import '../read_model/pending_action_view.dart';
import '../read_model/player_map_view.dart';

final class HexInspectionViewMapper {
  const HexInspectionViewMapper();

  HexInspectionView fromWire(
    AonwHexInspectionResult wire, {
    required MapView map,
    required PlayerMapView player,
    required int expectedRevision,
    required MapHexCoordinate coordinate,
  }) {
    _validate(wire, map, player, expectedRevision, coordinate);
    final value = wire.inspection;
    return HexInspectionView(
      stamp: SessionStampView(
        revision: wire.stamp.revision,
        stateDigest: wire.stamp.stateDigest,
        mapHash: wire.stamp.mapHash,
        rulesetHash: wire.stamp.rulesetHash,
      ),
      coordinate: coordinate,
      baseTerrain: MapTerrain.values.byName(value.baseTerrain.name),
      terrainTags: [
        for (final terrain in value.terrainTags)
          MapTerrain.values.byName(terrain.name),
      ],
      resources: [
        for (final resource in value.resources)
          MapResource.values.byName(resource.name),
      ],
      height: value.height,
      hasRiver: value.hasRiver,
      canFoundCityOnTerrain: value.canFoundCityOnTerrain,
      yieldValue: _yield(value.yieldValue),
      score: HexAssessmentScoreView(
        city: value.score.city,
        defense: value.score.defense,
        economy: value.score.economy,
      ),
      kind: HexAssessmentKindView.values.byName(value.kind.name),
      recommendation: HexRecommendationView.values.byName(
        value.recommendation.name,
      ),
      tags: [
        for (final tag in value.tags)
          HexAssessmentTagView.values.byName(tag.name),
      ],
      improvementAccess: _access(value.improvementAccess),
      improvements: [
        for (final option in value.improvements) _improvement(option),
      ],
    );
  }
}

void _validate(
  AonwHexInspectionResult value,
  MapView map,
  PlayerMapView player,
  int revision,
  MapHexCoordinate coordinate,
) {
  final stamp = value.stamp;
  final current = player.stamp;
  if (revision != current.revision ||
      stamp.revision != revision ||
      (stamp.stateDigest, stamp.mapHash, stamp.rulesetHash) !=
          (current.stateDigest, current.mapHash, current.rulesetHash) ||
      stamp.mapHash != map.contentHash) {
    throw const FormatException('Hex inspection state identity is stale.');
  }
  final profile = value.inspection;
  final tile = map.tileAt(coordinate);
  if (tile == null ||
      (col: profile.coordinate.col, row: profile.coordinate.row) !=
          coordinate ||
      profile.baseTerrain.name != tile.yieldTerrain.name ||
      profile.height != tile.height ||
      !_sameTerrainTags(profile.terrainTags, tile.terrainTags)) {
    throw const FormatException(
      'Hex inspection does not match the requested map tile.',
    );
  }
}

bool _sameTerrainTags(List<AonwMapTerrain> wire, List<MapTerrain> terrain) =>
    wire.length == terrain.length &&
    wire.indexed.every((entry) => entry.$2.name == terrain[entry.$1].name);

HexImprovementAccessView _access(AonwHexImprovementAccess value) =>
    switch (value) {
      AonwHexOutsideControlledCity() => const HexOutsideControlledCityView(),
      AonwHexCityCenter() => const HexCityCenterView(),
      AonwHexAlreadyImproved() => const HexAlreadyImprovedView(),
      AonwHexControlledCity(:final cityId) => HexControlledCityView(cityId),
    };

HexImprovementOptionView _improvement(AonwHexImprovementOption value) =>
    HexImprovementOptionView(
      kind: FieldImprovementKind.values.byName(value.kind.name),
      requiredTechnology: value.requiredTechnology == null
          ? null
          : TechnologyIdView.values.byName(value.requiredTechnology!.name),
      technologyUnlocked: value.technologyUnlocked,
      buildTurns: value.buildTurns,
      yieldDelta: _yield(value.yieldDelta),
    );

YieldValueView _yield(AonwYieldValue value) => YieldValueView(
  food: value.food,
  production: value.production,
  gold: value.gold,
  defense: value.defense,
);
