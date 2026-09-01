import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/fog_map_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  test('cache batches a 40 by 30 map without a component per hex', () {
    final map = testMapScene(cols: 40, rows: 30).map;
    final cache = MapStaticRenderCache.build(map);

    expect(cache.identity.cols, 40);
    expect(cache.identity.rows, 30);
    expect(cache.gridPath.computeMetrics(), hasLength(1200));
    expect(cache.tilePaths, hasLength(1200));
    expect(
      cache.terrainPaths.values.fold<int>(
        0,
        (count, path) => count + path.computeMetrics().length,
      ),
      1200,
    );
    expect(cache.terrainPaths.length, lessThanOrEqualTo(14));
    expect(
      cache.size.height,
      closeTo(
        cache.geometry.bounds.height * MapViewportProjection.perspectiveY,
        1e-9,
      ),
    );
    expect(cache.clipPath.getBounds(), cache.gridPath.getBounds());
  });

  test('cache matches legacy neighbor-aware elevation walls', () {
    final source = testMapScene(cols: 2, rows: 2).map;
    final cache = MapStaticRenderCache.build(
      _withHeight(source, coordinate: (col: 0, row: 0), height: 2),
    );

    expect(cache.elevationWallPaths.right.computeMetrics(), hasLength(1));
    expect(cache.elevationWallPaths.bottom.computeMetrics(), hasLength(1));
    expect(cache.elevationWallPaths.left.computeMetrics(), hasLength(1));
    expect(
      cache.elevationWallPaths.bottom.getBounds().height,
      closeTo(7 * MapViewportProjection.perspectiveY, 1e-5),
    );
  });

  testWithGame<AonwFlameGame>(
    'keeps three batched static layers before ordered gameplay layers',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(cols: 7, rows: 7);
      game.sceneSink.replaceScene(_snapshot(scene));
      await game.ready();

      final layers = game.world.children.toList();
      expect(layers, hasLength(13));
      expect(layers[0], same(game.world.terrainLayer));
      expect(layers[1], same(game.world.referenceLayer));
      expect(layers[2], same(game.world.gridLayer));
      expect(layers[3], same(game.world.workerInfrastructureLayer));
      expect(layers[4], same(game.world.fogLayer));
      expect(layers[5], same(game.world.reachableLayer));
      expect(layers[6], same(game.world.routeLayer));
      expect(layers[7], same(game.world.objectiveLayer));
      expect(layers[8], same(game.world.cityLayer));
      expect(layers[9], same(game.world.artifactLayer));
      expect(layers[10], same(game.world.unitLayer));
      expect(layers[11], same(game.world.selectionLayer));
      expect(layers[12], same(game.world.effectHost));
      expect(layers.map((component) => component.priority), [
        0,
        10,
        20,
        25,
        27,
        30,
        40,
        43,
        45,
        47,
        50,
        60,
        70,
      ]);
      expect(
        layers,
        everyElement(
          predicate<Component>((layer) {
            return layer.children.isEmpty;
          }),
        ),
      );
      expect(game.world.terrainLayer.debugCacheUpdateCount, 1);
      expect(game.world.referenceLayer.debugCacheUpdateCount, 1);
      expect(game.world.gridLayer.debugCacheUpdateCount, 1);
      expect(game.world.fogLayer.isVisible, isFalse);
    },
  );

  testWithGame<AonwFlameGame>(
    'reuses caches across visibility resize and idle updates',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(cols: 7, rows: 7);
      game.sceneSink.replaceScene(_snapshot(scene));
      await game.ready();
      final terrainIdentity = game.world.terrainLayer.debugIdentity;
      final referenceIdentity = game.world.referenceLayer.debugIdentity;
      final gridIdentity = game.world.gridLayer.debugIdentity;

      for (var frame = 0; frame < 120; frame++) {
        game.update(1 / 60);
      }
      game.onGameResize(Vector2(1200, 800));
      game.sceneSink.replaceScene(
        _snapshot(
          scene,
          interaction: const MapInteractionState(referenceVisible: false),
        ),
      );

      expect(game.world.terrainLayer.debugIdentity, same(terrainIdentity));
      expect(game.world.referenceLayer.debugIdentity, same(referenceIdentity));
      expect(game.world.gridLayer.debugIdentity, same(gridIdentity));
      expect(game.world.terrainLayer.debugCacheUpdateCount, 1);
      expect(game.world.referenceLayer.debugCacheUpdateCount, 1);
      expect(game.world.gridLayer.debugCacheUpdateCount, 1);
      expect(game.world.referenceLayer.debugVisibilityUpdateCount, 2);
      expect(game.world.referenceLayer.isVisible, isFalse);

      final replacement = testMapScene(cols: 7, rows: 7, contentHash: 'd' * 64);
      game.sceneSink.replaceScene(_snapshot(replacement));

      expect(game.world.terrainLayer.debugCacheUpdateCount, 2);
      expect(game.world.referenceLayer.debugCacheUpdateCount, 2);
      expect(game.world.gridLayer.debugCacheUpdateCount, 2);
    },
  );

  test('batches recipient fog and reuses unchanged visibility paths', () {
    final layer = MapFogLayerComponent();
    final cache = MapStaticRenderCache.build(
      testMapScene(cols: 3, rows: 2).map,
    );
    final fog = MapFogView(
      enabled: true,
      discoveredHexes: const [(col: 1, row: 0), (col: 2, row: 0)],
      visibleHexes: const [(col: 2, row: 0)],
    );
    layer.applyFog(cache, fog);

    expect(layer.isVisible, isTrue);
    expect(layer.debugHiddenHexCount, 4);
    expect(layer.debugDiscoveredHexCount, 1);
    expect(layer.debugHiddenPathMetricCount, 4);
    expect(layer.debugDiscoveredPathMetricCount, 1);
    expect(layer.debugPathBuildCount, 1);

    final equalFog = MapFogView(
      enabled: true,
      discoveredHexes: const [(col: 1, row: 0), (col: 2, row: 0)],
      visibleHexes: const [(col: 2, row: 0)],
    );
    layer.applyFog(cache, equalFog);
    expect(layer.debugPathBuildCount, 1);

    layer.applyFog(cache, MapFogView.disabled());
    expect(layer.isVisible, isFalse);
    expect(layer.debugHiddenPathMetricCount, 0);
    expect(layer.debugDiscoveredPathMetricCount, 0);
  });
}

MapRenderSnapshot _snapshot(
  MapScene scene, {
  MapInteractionState interaction = const MapInteractionState(),
}) => MapRenderSnapshot(
  map: scene.map,
  interaction: interaction,
  reference: scene.reference,
  player: scene.player,
);

MapView _withHeight(
  MapView source, {
  required MapHexCoordinate coordinate,
  required int height,
}) => MapView(
  mapId: source.mapId,
  contentHash: source.contentHash,
  gridLayout: source.gridLayout,
  cols: source.cols,
  rows: source.rows,
  defaultZoom: source.defaultZoom,
  tiles: [
    for (final tile in source.tiles)
      MapTileView(
        coordinate: tile.coordinate,
        displayTerrain: tile.displayTerrain,
        yieldTerrain: tile.yieldTerrain,
        movementTerrains: tile.movementTerrains,
        terrainTags: tile.terrainTags,
        resources: tile.resources,
        height: tile.coordinate == coordinate ? height : tile.height,
      ),
  ],
  objectives: source.objectives,
);
