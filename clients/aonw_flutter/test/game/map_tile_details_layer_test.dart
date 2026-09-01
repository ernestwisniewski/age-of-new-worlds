import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/game/map/map_display_options.dart';
import 'package:aonw_flutter/game/map/map_tile_details_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  test('matches legacy projected tile detail geometry', () {
    const center = ui.Offset(100, 100);
    final terrain = MapTileDetailLayout.terrainIcons(
      center: center,
      iconCount: 4,
    );
    final resources = MapTileDetailLayout.resourceIcons(
      topCenter: center,
      iconCount: 4,
    );

    expect(terrain, hasLength(4));
    expect(terrain.first.center.dx, 73);
    expect(
      terrain.first.height,
      closeTo(
        MapTileDetailLayout.terrainIconSize *
            MapViewportProjection.perspectiveY,
        1e-9,
      ),
    );
    expect(terrain.last.center.dx, 100);
    expect(resources, hasLength(4));
    expect(resources.first.center.dx, 64);
    expect(
      resources.first.height,
      closeTo(
        MapTileDetailLayout.resourceIconSize *
            MapViewportProjection.perspectiveY,
        1e-9,
      ),
    );
    expect(
      MapTileDetailLayout.heightBadge(topCenter: center, paragraphHeight: 10),
      const ui.Offset(52, 96.9),
    );
  });

  test('batches sorted tile details without a component per hex', () {
    final source = testMapScene(cols: 2, rows: 2).map;
    final map = _withTileDetails(source);
    final cache = MapStaticRenderCache.build(map);
    final layer = MapTileDetailsLayerComponent();

    layer.applyMap(map, cache);

    expect(layer.debugCacheUpdateCount, 1);
    expect(layer.debugTerrainIconCount, 5);
    expect(layer.debugResourceIconCount, 2);
    expect(layer.debugHeightBadgeCount, 1);
    expect(layer.children, isEmpty);
    expect(layer.isVisible, isTrue, reason: 'resources default to visible');

    layer.applyMap(map, cache);
    expect(layer.debugCacheUpdateCount, 1);

    expect(
      layer.setOptions(const MapDisplayOptions(showGrid: true)),
      isFalse,
      reason: 'grid visibility does not invalidate tile details',
    );
    layer.setOptions(const MapDisplayOptions(showResourceIcons: false));
    expect(layer.isVisible, isFalse);
  });
}

MapView _withTileDetails(MapView source) => MapView(
  mapId: source.mapId,
  contentHash: source.contentHash,
  gridLayout: source.gridLayout,
  cols: source.cols,
  rows: source.rows,
  defaultZoom: source.defaultZoom,
  objectives: source.objectives,
  tiles: [
    for (final tile in source.tiles)
      if (tile.coordinate == (col: 0, row: 0))
        MapTileView(
          coordinate: tile.coordinate,
          displayTerrain: tile.displayTerrain,
          yieldTerrain: tile.yieldTerrain,
          movementTerrains: tile.movementTerrains,
          terrainTags: const [MapTerrain.forest, MapTerrain.plains],
          resources: const [MapResource.wheat, MapResource.gold],
          height: 2,
        )
      else
        tile,
  ],
);
