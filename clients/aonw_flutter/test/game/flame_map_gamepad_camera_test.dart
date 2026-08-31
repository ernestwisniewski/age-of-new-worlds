import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_gamepad_input.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'right stick and triggers retain the original camera speeds',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      final initial = game.mapCamera.debugTransform!;

      game.applyGamepadCameraFrame(
        const MapGamepadFrame(cameraX: 1, cameraY: 1, zoom: 1),
        0.5,
      );

      final moved = game.mapCamera.debugTransform!;
      expect(moved.worldCenter.x, closeTo(initial.worldCenter.x - 260, 1e-9));
      expect(moved.worldCenter.y, closeTo(initial.worldCenter.y + 260, 1e-9));
      expect(moved.zoom, closeTo(initial.zoom * 1.675, 1e-9));
    },
  );
}

Future<void> _prepare(AonwFlameGame game) async {
  game.onGameResize(Vector2(900, 800));
  game.replaceScene(_snapshot(testMapScene(cols: 7, rows: 7)));
  game.setViewportActive(true);
  await game.ready();
}

MapRenderSnapshot _snapshot(MapScene scene) => MapRenderSnapshot(
  map: scene.map,
  interaction: const MapInteractionState(),
  reference: scene.reference,
  player: scene.player,
);
