import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/hex_inspection_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';

final class FakeHexInspectionSession implements HexInspectionSessionPort {
  FakeHexInspectionSession({required this.scene, this.onInspect});
  final MapScene scene;
  final Future<HexInspectionView> Function(
    int revision,
    MapHexCoordinate coordinate,
  )?
  onInspect;
  final requests = <({int revision, MapHexCoordinate coordinate})>[];

  @override
  Future<HexInspectionView> inspectHex({
    required int expectedRevision,
    required MapHexCoordinate coordinate,
  }) async {
    requests.add((revision: expectedRevision, coordinate: coordinate));
    return onInspect == null
        ? testHexInspectionView(scene: scene, coordinate: coordinate)
        : onInspect!(expectedRevision, coordinate);
  }
}

HexInspectionView testHexInspectionView({
  required MapScene scene,
  MapHexCoordinate coordinate = const (col: 0, row: 0),
  List<MapResource> resources = const [],
}) {
  final tile = scene.map.tileAt(coordinate)!;
  return HexInspectionView(
    stamp: scene.player.stamp,
    coordinate: coordinate,
    baseTerrain: tile.yieldTerrain,
    terrainTags: tile.terrainTags,
    resources: resources,
    height: tile.height,
    hasRiver: false,
    canFoundCityOnTerrain: false,
    yieldValue: const YieldValueView(
      food: 0,
      production: 0,
      gold: 0,
      defense: 0,
    ),
    score: const HexAssessmentScoreView(city: 0, defense: 0, economy: 0),
    kind: HexAssessmentKindView.mapTile,
    recommendation: HexRecommendationView.neutral,
    tags: const [],
    improvementAccess: const HexOutsideControlledCityView(),
    improvements: const [],
  );
}
