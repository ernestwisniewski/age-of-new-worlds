import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/movement_camera_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'reduced motion focuses immediately and commits the final unit position',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.setReducedMotion(true);
      game.replaceScene(movementCameraSnapshot(revision: 1));
      final cache = game.world.debugStaticRenderCache!;
      final origin = game.world.unitLayer.centerFor(cache, (col: 6, row: 3));
      final target = game.world.unitLayer.visualCenterFor(cache, 'moving', (
        col: 8,
        row: 3,
      ));
      final center = game.mapCamera.debugTransform!.worldCenter;
      expect(center.x, closeTo(origin.dx, 0.0001));
      expect(center.y, closeTo(origin.dy, 0.0001));
      expect(
        (game.world.unitLayer.componentForUnit('moving')!.visualCenter - target)
            .distance,
        closeTo(0, 0.0001),
      );
      expect(game.mapCamera.hasMotion, isFalse);
      expect(game.world.effectHost.debugActiveEffectCount, 0);
      await game.waitForCommandEffects();
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'focuses the movement origin before advancing the executed path',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      final cache = game.world.debugStaticRenderCache!;
      game.replaceScene(movementCameraSnapshot(revision: 1));
      final unit = game.world.unitLayer.componentForUnit('moving')!;
      final origin = unit.visualCenter;
      final completion = game.waitForCommandEffects();
      game.update(0.14);
      expect(unit.visualCenter, origin);
      expect(game.mapCamera.hasMotion, isTrue);
      game.update(0.14);
      expect(unit.visualCenter, origin);
      expect(game.mapCamera.debugTransform!.worldCenter, (
        x: origin.dx,
        y: origin.dy,
      ));
      game.update(0.6);
      expect(
        (unit.visualCenter -
                game.world.unitLayer.centerFor(cache, (col: 7, row: 3)))
            .distance,
        closeTo(0, 0.0001),
      );
      expect(game.mapCamera.hasMotion, isFalse);
      game.update(0.6);
      await completion;
      expect(
        (unit.visualCenter -
                game.world.unitLayer.visualCenterFor(cache, 'moving', (
                  col: 8,
                  row: 3,
                )))
            .distance,
        closeTo(0, 0.0001),
      );
      expect(game.paused, isTrue);
      expect(game.world.debugStaticRenderCache, same(cache));
    },
  );

  for (final foreign in [false, true]) {
    testWithGame<AonwFlameGame>(
      'applies independent focus and follow choices for foreign=$foreign',
      AonwFlameGame.new,
      (game) async {
        for (final focus in [false, true]) {
          for (final follow in [false, true]) {
            game.clearScene();
            await _prepare(game, foreign: foreign);
            game.setMovementCameraOptions((
              focusOwn: !foreign && focus,
              followOwn: !foreign && follow,
              focusForeign: foreign && focus,
              followForeign: foreign && follow,
            ));
            final initial = game.mapCamera.debugTransform!.worldCenter;
            game.replaceScene(
              movementCameraSnapshot(revision: 1, foreign: foreign),
            );
            final origin = game.world.unitLayer
                .componentForUnit('moving')!
                .visualCenter;
            expect(game.mapCamera.hasMotion, focus);
            if (focus) game.update(0.28);
            game.update(0.1);
            expect(game.mapCamera.isFollowing, follow);
            final center = game.mapCamera.debugTransform!.worldCenter;
            if (!focus && !follow) {
              expect(center, initial);
            } else if (follow) {
              expect(center.x, greaterThan(focus ? origin.dx : initial.x));
            } else {
              expect(center, (x: origin.dx, y: origin.dy));
            }
            game.update(2);
            await game.waitForCommandEffects();
            expect(game.mapCamera.hasMotion, isFalse);
            expect(game.paused, isTrue);
          }
        }
      },
    );
  }

  testWithGame<AonwFlameGame>(
    'manual pan cancels preparation without reattaching follow after refresh',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.setMovementCameraOptions((
        focusOwn: true,
        followOwn: true,
        focusForeign: false,
        followForeign: false,
      ));
      game.replaceScene(movementCameraSnapshot(revision: 1));
      game.update(0.1);
      game.mapCamera.applyIntent(const MapPanIntent((x: 30, y: 10)));
      final manual = game.mapCamera.debugTransform!.worldCenter;
      game.replaceScene(movementCameraSnapshot(revision: 1));
      game.update(0.1);
      expect(game.mapCamera.isFollowing, isFalse);
      expect(game.mapCamera.debugTransform!.worldCenter, manual);
      game.update(2);
      await game.waitForCommandEffects();
      expect(game.mapCamera.debugTransform!.worldCenter, manual);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'a selected entity takes control from a moving unit and survives completion',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.setMovementCameraOptions((
        focusOwn: false,
        followOwn: true,
        focusForeign: false,
        followForeign: false,
      ));
      game.replaceScene(movementCameraSnapshot(revision: 1));
      game.update(0.12);
      expect(game.mapCamera.isFollowing, isTrue);
      game.replaceScene(
        movementCameraSnapshot(revision: 1, selected: 'anchor'),
      );
      expect(game.mapCamera.isFollowing, isFalse);
      game.update(0.42);
      game.update(1);
      await game.waitForCommandEffects();
      final anchor = game.world.unitLayer
          .componentForUnit('anchor')!
          .visualCenter;
      expect(game.mapCamera.debugTransform!.worldCenter, (
        x: anchor.dx,
        y: anchor.dy,
      ));
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'settings, reduced motion, replay jumps and hiding the map release the camera',
    AonwFlameGame.new,
    (game) async {
      for (final action in ['settings', 'reduced', 'epoch', 'hidden', 'skip']) {
        game.clearScene();
        game.setReducedMotion(false);
        await _prepare(game);
        game.setMovementCameraOptions((
          focusOwn: true,
          followOwn: true,
          focusForeign: false,
          followForeign: false,
        ));
        game.replaceScene(movementCameraSnapshot(revision: 1));
        game.update(0.1);
        switch (action) {
          case 'settings':
            game.setMovementCameraOptions((
              focusOwn: false,
              followOwn: false,
              focusForeign: false,
              followForeign: false,
            ));
          case 'reduced':
            game.setReducedMotion(true);
          case 'epoch':
            game.replaceScene(movementCameraSnapshot(revision: 1, epoch: 1));
          case 'hidden':
            game.setViewportActive(false);
            game.setViewportActive(true);
          case 'skip':
            game.skipEffects();
        }
        expect(game.mapCamera.hasMotion, isFalse, reason: action);
        game.update(2);
        await game.waitForCommandEffects();
        expect(game.paused, isTrue, reason: action);
      }
    },
  );
}

Future<void> _prepare(AonwFlameGame game, {bool foreign = false}) async {
  game.onGameResize(Vector2(900, 700));
  game.setViewportActive(true);
  game.replaceScene(movementCameraSnapshot(foreign: foreign));
  await game.ready();
}
