import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/movement_camera_test_fixture.dart';

void main() {
  for (final focus in [false, true]) {
    testWithGame<AonwFlameGame>(
      'disabled movement finishes after camera focus=$focus without follow',
      AonwFlameGame.new,
      (game) async {
        await _prepare(game);
        game.setUnitMovementAnimations(false);
        game.setMovementCameraOptions((
          focusOwn: focus,
          followOwn: true,
          focusForeign: false,
          followForeign: false,
        ));
        final unit = game.world.unitLayer.componentForUnit('moving')!;
        final initialCamera = game.mapCamera.debugTransform!.worldCenter;
        game.replaceScene(movementCameraSnapshot(revision: 1));
        final origin = unit.visualCenter;
        final completion = game.waitForCommandEffects();
        var finished = false;
        completion.then((_) => finished = true);
        if (focus) {
          game.update(0.14);
          expect(unit.visualCenter, origin);
          await Future<void>.value();
          expect(finished, isFalse);
          game.update(0.14);
          game.update(0);
        }
        await completion;
        expect(game.mapCamera.isFollowing, isFalse);
        expect(
          game.mapCamera.debugTransform!.worldCenter,
          focus ? (x: origin.dx, y: origin.dy) : initialCamera,
        );
        _expectFinished(game);
      },
    );
  }

  testWithGame<AonwFlameGame>(
    'manual pan releases disabled movement waiting for focus',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.setUnitMovementAnimations(false);
      game.replaceScene(movementCameraSnapshot(revision: 1));
      final completion = game.waitForCommandEffects();
      game.update(0.1);
      game.mapCamera.applyIntent(const MapPanIntent((x: 30, y: 10)));
      final manual = game.mapCamera.debugTransform!.worldCenter;
      game.update(0);
      await completion;
      expect(game.mapCamera.debugTransform!.worldCenter, manual);
      _expectFinished(game);
    },
  );

  for (final focus in [false, true]) {
    testWithGame<AonwFlameGame>(
      'disabling movement during focus=$focus finishes the pending command',
      AonwFlameGame.new,
      (game) async {
        await _prepare(game);
        game.setMovementCameraOptions((
          focusOwn: focus,
          followOwn: true,
          focusForeign: false,
          followForeign: false,
        ));
        game.replaceScene(movementCameraSnapshot(revision: 1));
        final completion = game.waitForCommandEffects();
        game.update(0.1);
        expect(game.mapCamera.hasMotion, isTrue);
        game.setUnitMovementAnimations(false);
        await completion;
        _expectFinished(game);
        final camera = game.mapCamera.debugTransform!.worldCenter;
        game.setUnitMovementAnimations(true);
        game.replaceScene(movementCameraSnapshot(revision: 1));
        game.update(1);
        expect(game.mapCamera.debugTransform!.worldCenter, camera);
        expect(game.world.effectHost.debugCompletedMovementCount, 1);
        _expectFinished(game);
      },
    );
  }

  testWithGame<AonwFlameGame>(
    'enabling movement during camera preparation does not replay the path',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      game.setUnitMovementAnimations(false);
      game.replaceScene(movementCameraSnapshot(revision: 1));
      game.update(0.14);
      game.setUnitMovementAnimations(true);
      game.update(0.14);
      game.update(0);
      await game.waitForCommandEffects();
      _expectFinished(game);
    },
  );
}

Future<void> _prepare(AonwFlameGame game) async {
  game.onGameResize(Vector2(900, 700));
  game.setViewportActive(true);
  game.replaceScene(movementCameraSnapshot());
  await game.ready();
}

void _expectFinished(AonwFlameGame game) {
  final layer = game.world.unitLayer;
  final target = layer.visualCenterFor(
    game.world.debugStaticRenderCache!,
    'moving',
    (col: 8, row: 3),
  );
  expect(
    (layer.componentForUnit('moving')!.visualCenter - target).distance,
    closeTo(0, 0.0001),
  );
  expect(game.world.effectHost.debugActiveEffectCount, 0);
  expect(game.mapCamera.hasMotion, isFalse);
  expect(game.paused, isTrue);
}
