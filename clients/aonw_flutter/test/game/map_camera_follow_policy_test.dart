import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/presentation/flame_command_transition.dart';
import 'package:aonw_flutter/game/presentation/map_movement_camera_visibility.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/movement_camera_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'following has a frame-independent half-life and stops when its target vanishes',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.replaceScene(movementCameraSnapshot());
      const start = (x: 100.0, y: 80.0);
      const target = (x: 500.0, y: 280.0);
      game.mapCamera.centerOnWorld(start);
      game.mapCamera.followWorldPoint(() => target);
      game.update(0.1);
      final oneStep = game.mapCamera.debugTransform!.worldCenter;
      expect(oneStep, (x: 300.0, y: 180.0));
      game.mapCamera.centerOnWorld(start);
      game.mapCamera.followWorldPoint(() => target);
      game.update(0.05);
      game.update(0.05);
      final twoSteps = game.mapCamera.debugTransform!.worldCenter;
      expect(twoSteps.x, closeTo(oneStep.x, 0.0001));
      expect(twoSteps.y, closeTo(oneStep.y, 0.0001));
      game.mapCamera.followWorldPoint(() => null);
      game.update(0.01);
      expect(game.mapCamera.hasMotion, isFalse);
      expect(game.paused, isTrue);
      final updates = game.mapCamera.debugTransformUpdateCount;
      game.update(1);
      expect(game.mapCamera.debugTransformUpdateCount, updates);
    },
  );

  test('a visible foreign unit may follow its disclosed movement history', () {
    const movement = FlameUnitMovementTransition(
      unitId: 'moving',
      from: (col: 6, row: 3),
      to: (col: 8, row: 3),
      fromRevision: 0,
      toRevision: 1,
      path: [(col: 6, row: 3), (col: 7, row: 3), (col: 8, row: 3)],
    );
    final visible = MapFogView(
      enabled: true,
      discoveredHexes: movement.path,
      visibleHexes: movement.path,
    );
    final partiallyVisible = MapFogView(
      enabled: true,
      discoveredHexes: movement.path,
      visibleHexes: [movement.to],
    );
    expect(
      canFocusMapMovement(
        movementCameraSnapshot(foreign: true, fog: visible),
        movement,
      ),
      isTrue,
    );
    expect(
      canFocusMapMovement(
        movementCameraSnapshot(
          revision: 1,
          foreign: true,
          fog: partiallyVisible,
        ),
        movement,
      ),
      isTrue,
    );
    expect(
      canFocusMapMovement(
        movementCameraSnapshot(foreign: true, fog: partiallyVisible),
        movement,
      ),
      isFalse,
    );
    expect(
      canFocusMapMovement(
        movementCameraSnapshot(fog: partiallyVisible),
        movement,
      ),
      isTrue,
    );
    expect(
      canFocusMapMovement(
        movementCameraSnapshot(),
        const FlameUnitMovementTransition(
          unitId: 'missing',
          from: (col: 6, row: 3),
          to: (col: 8, row: 3),
          fromRevision: 0,
          toRevision: 1,
        ),
      ),
      isFalse,
    );
  });
}
