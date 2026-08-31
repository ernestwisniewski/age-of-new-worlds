import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'WASD and arrows continuously pan at the original camera speed',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      expect(game.keyboardPanDelta(1), (x: 0, y: 0));
      final initial = game.mapCamera.debugTransform!;

      game.setKeyboardPanDirection(x: 1, y: -1);
      expect(game.keyboardPanDelta(1), (x: 200, y: -200));
      game.update(0.5);

      final moved = game.mapCamera.debugTransform!;
      expect(moved.worldCenter.x, closeTo(initial.worldCenter.x - 100, 1e-9));
      expect(moved.worldCenter.y, closeTo(initial.worldCenter.y + 100, 1e-9));

      game.setKeyboardPanDirection(x: 0, y: 0);
      game.update(1);
      expect(game.mapCamera.debugTransform!.worldCenter, moved.worldCenter);
    },
  );

  testWithGame<AonwFlameGame>(
    'keyboard movement retains the original zoom scaling',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.mapCamera.applyIntent(
        const MapZoomIntent(focalPoint: (x: 450, y: 400), factor: 2),
      );
      final initial = game.mapCamera.debugTransform!;

      game.setKeyboardPanDirection(x: 1, y: 0);
      expect(game.keyboardPanDelta(1), (x: 100, y: 0));
      game.update(1);

      expect(
        game.mapCamera.debugTransform!.worldCenter.x,
        closeTo(initial.worldCenter.x - 50, 1e-9),
      );
      game.setViewportActive(false);
      expect(game.keyboardPanDelta(1), (x: 0, y: 0));
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
