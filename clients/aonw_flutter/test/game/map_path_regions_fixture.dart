import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_palette.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/map/fog_map_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:aonw_flutter/game/map/worker_infrastructure_layer.dart';
import 'package:aonw_flutter/game/presentation/flame_scene_patch.dart';

import '../support/map_test_fixture.dart';

typedef RegionComparison = ({
  String name,
  void Function(ui.Canvas) actual,
  void Function(ui.Canvas) expected,
  int Function() rendered,
  int Function() builds,
});

List<RegionComparison> regionalPathComparisons() {
  final scene = testMapScene(
    cols: 40,
    rows: 30,
    cities: [testCityView(center: (col: 5, row: 5))],
    roads: [
      for (var col = 0; col < 40; col++)
        for (var row = 0; row < 30; row++)
          if ((col + row) % 3 != 0)
            RoadView(
              coordinate: (col: col, row: row),
              condition: TransportConditionView.operational,
            ),
    ],
  );
  final map = _withHeights(scene.map);
  final cache = MapStaticRenderCache.build(map);
  final terrain = MapTerrainLayerComponent()
    ..applyCache(cache)
    ..setWalls(true);
  final grid = MapGridLayerComponent()..applyCache(cache);
  final referenceTerrain = MapTerrainLayerComponent()..applyCache(cache);
  final fogView = MapFogView(
    enabled: true,
    discoveredHexes: [
      for (final hex in cache.tilePaths.keys)
        if ((hex.col + hex.row) % 3 != 0) hex,
    ],
    visibleHexes: [
      for (final hex in cache.tilePaths.keys)
        if ((hex.col + hex.row) % 3 == 2) hex,
    ],
  );
  final fog = MapFogLayerComponent()..applyFog(cache, fogView);
  final roads = MapWorkerInfrastructureLayerComponent()
    ..applyPatch(
      FlameScenePatch.between(
        null,
        MapRenderSnapshot(
          map: map,
          reference: scene.reference,
          player: scene.player,
          interaction: const MapInteractionState(),
        ),
      ),
      cache,
    );
  final hidden = ui.Path();
  final discovered = ui.Path();
  for (final entry in cache.tilePaths.entries) {
    switch (fogView.visibilityAt(entry.key)) {
      case MapFogVisibilityView.hidden:
        hidden.addPath(entry.value, ui.Offset.zero);
      case MapFogVisibilityView.discovered:
        discovered.addPath(entry.value, ui.Offset.zero);
      case MapFogVisibilityView.visible:
        break;
    }
  }
  return [
    (
      name: 'terrain and elevation walls',
      actual: terrain.render,
      expected: (canvas) {
        canvas
          ..drawPath(
            cache.elevationWallPaths.right,
            ui.Paint()..color = MapPalette.elevationWallRight,
          )
          ..drawPath(
            cache.elevationWallPaths.bottom,
            ui.Paint()..color = MapPalette.elevationWallBottom,
          )
          ..drawPath(
            cache.elevationWallPaths.left,
            ui.Paint()..color = MapPalette.elevationWallLeft,
          );
        // The existing terrain batching is covered separately. Isolate walls.
        referenceTerrain.render(canvas);
      },
      rendered: () => terrain.debugRenderedWallRegionCount,
      builds: () => terrain.debugCacheUpdateCount,
    ),
    (
      name: 'grid',
      actual: grid.render,
      expected: (canvas) => canvas.drawPath(
        cache.gridPath,
        _stroke(MapPalette.grid, 1.2)..strokeCap = ui.StrokeCap.butt,
      ),
      rendered: () => grid.debugRenderedRegionCount,
      builds: () => grid.debugCacheUpdateCount,
    ),
    (
      name: 'fog',
      actual: fog.render,
      expected: (canvas) {
        canvas
          ..drawPath(hidden, _fogPaint(MapPalette.fogHidden, 3.2))
          ..drawPath(discovered, _fogPaint(MapPalette.fogDiscovered, 2.4));
      },
      rendered: () => fog.debugRenderedRegionCount,
      builds: () => fog.debugPathBuildCount,
    ),
    (
      name: 'roads',
      actual: roads.render,
      expected: (canvas) {
        canvas
          ..drawPath(roads.debugRoadPath, _stroke(MapPalette.roadEdge, 9))
          ..drawPath(roads.debugRoadPath, _stroke(MapPalette.roadAsphalt, 7))
          ..drawPath(
            roads.debugMarkingPath,
            _stroke(MapPalette.roadMarking, 1.5),
          );
      },
      rendered: () => roads.debugRenderedRoadRegionCount,
      builds: () => roads.debugRoadGeometryBuildCount,
    ),
  ];
}

ui.Paint _stroke(ui.Color color, double width) => ui.Paint()
  ..color = color
  ..style = ui.PaintingStyle.stroke
  ..strokeCap = ui.StrokeCap.round
  ..strokeWidth = width;

ui.Paint _fogPaint(ui.Color color, double blur) => ui.Paint()
  ..color = color
  ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, blur);

MapView _withHeights(MapView source) => MapView(
  mapId: source.mapId,
  contentHash: source.contentHash,
  gridLayout: source.gridLayout,
  cols: source.cols,
  rows: source.rows,
  defaultZoom: source.defaultZoom,
  objectives: source.objectives,
  tiles: [
    for (final tile in source.tiles)
      MapTileView(
        coordinate: tile.coordinate,
        displayTerrain: tile.displayTerrain,
        yieldTerrain: tile.yieldTerrain,
        movementTerrains: tile.movementTerrains,
        terrainTags: tile.terrainTags,
        resources: tile.resources,
        height: (tile.coordinate.col + tile.coordinate.row) % 5,
      ),
  ],
);
