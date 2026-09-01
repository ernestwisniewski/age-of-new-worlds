import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_display_options.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'owns one world and one camera behind the typed scene sink',
    AonwFlameGame.new,
    (game) async {
      expect(game.children.whereType<AonwWorld>(), hasLength(1));
      expect(game.children.whereType<CameraComponent>(), hasLength(1));
      expect(game.camera.world, same(game.world));

      final scene = testMapScene();
      final snapshot = MapRenderSnapshot(
        map: scene.map,
        interaction: const MapInteractionState(),
        reference: scene.reference,
        player: scene.player,
      );
      game.sceneSink.replaceScene(snapshot);

      expect(game.world.debugScene, same(snapshot));
      expect(game.world.debugSceneWriteCount, 1);

      game.sceneSink.clearScene();
      expect(game.world.debugScene, isNull);
      expect(game.world.debugSceneWriteCount, 2);
    },
  );

  testWithGame<AonwFlameGame>(
    'combines route visibility with explicit continuous rendering',
    AonwFlameGame.new,
    (game) async {
      expect(game.paused, isTrue);
      expect(game.debugViewportActive, isFalse);

      game.setViewportActive(true);
      expect(game.debugViewportActive, isTrue);
      expect(game.paused, isTrue, reason: 'the empty world is idle');

      game.setContinuousRendering(true);
      expect(game.paused, isFalse);

      game.setViewportActive(false);
      expect(game.paused, isTrue);

      game.setViewportActive(true);
      expect(game.paused, isFalse);
    },
  );

  testWithGame<AonwFlameGame>(
    'applies map display settings without replacing the scene',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene();
      final snapshot = MapRenderSnapshot(
        map: scene.map,
        interaction: const MapInteractionState(),
        reference: scene.reference,
        player: scene.player,
      );
      game.sceneSink.replaceScene(snapshot);
      await game.ready();

      expect(game.world.terrainLayer.debugElevationWallsVisible, isFalse);
      expect(
        game.world.tileDetailsLayer.debugOptions.showResourceIcons,
        isTrue,
      );
      game.setMapDisplayOptions(
        const MapDisplayOptions(
          showElevationWalls: true,
          showTerrainIcons: true,
          showResourceIcons: false,
          showHeightBadges: true,
        ),
      );

      expect(game.world.terrainLayer.debugElevationWallsVisible, isTrue);
      expect(game.world.tileDetailsLayer.debugOptions.showTerrainIcons, isTrue);
      expect(
        game.world.tileDetailsLayer.debugOptions.showResourceIcons,
        isFalse,
      );
      expect(game.world.tileDetailsLayer.debugOptions.showHeightBadges, isTrue);
      expect(game.world.debugScene, same(snapshot));
      expect(game.world.debugSceneWriteCount, 1);
    },
  );
}
