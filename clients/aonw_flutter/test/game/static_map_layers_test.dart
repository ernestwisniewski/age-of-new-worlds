import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
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
    expect(
      cache.terrainPaths.values.fold<int>(
        0,
        (count, path) => count + path.computeMetrics().length,
      ),
      1200,
    );
    expect(cache.terrainPaths.length, lessThanOrEqualTo(14));
  });

  testWithGame<AonwFlameGame>(
    'keeps three batched static layers before ordered gameplay layers',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(cols: 7, rows: 7);
      game.sceneSink.replaceScene(_snapshot(scene));
      await game.ready();

      final layers = game.world.children.toList();
      expect(layers, hasLength(12));
      expect(layers[0], same(game.world.terrainLayer));
      expect(layers[1], same(game.world.referenceLayer));
      expect(layers[2], same(game.world.gridLayer));
      expect(layers[3], same(game.world.workerInfrastructureLayer));
      expect(layers[4], same(game.world.reachableLayer));
      expect(layers[5], same(game.world.routeLayer));
      expect(layers[6], same(game.world.objectiveLayer));
      expect(layers[7], same(game.world.cityLayer));
      expect(layers[8], same(game.world.artifactLayer));
      expect(layers[9], same(game.world.unitLayer));
      expect(layers[10], same(game.world.selectionLayer));
      expect(layers[11], same(game.world.effectHost));
      expect(layers.map((component) => component.priority), [
        0,
        10,
        20,
        25,
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
