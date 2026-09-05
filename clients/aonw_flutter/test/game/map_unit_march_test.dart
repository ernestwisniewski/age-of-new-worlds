import 'dart:ui' as ui;

import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/movement_camera_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWithGame<AonwFlameGame>(
    'marches linearly between hex centers and settles in the city stack',
    AonwFlameGame.new,
    (game) async {
      game.onGameResize(Vector2(900, 700));
      game.setViewportActive(true);
      game.setMovementCameraOptions((
        focusOwn: false,
        followOwn: false,
        focusForeign: false,
        followForeign: false,
      ));
      game.replaceScene(movementCameraSnapshot());
      await game.ready();
      final unit = game.world.unitLayer.componentForUnit('moving')!;
      await unit.debugLoadSprite();
      game.replaceScene(movementCameraSnapshot(revision: 1));
      final cache = game.world.debugStaticRenderCache!;
      final layer = game.world.unitLayer;
      final origin = layer.centerFor(cache, (col: 6, row: 3));
      final middle = layer.centerFor(cache, (col: 7, row: 3));
      final destination = layer.centerFor(cache, (col: 8, row: 3));
      final host = game.world.effectHost;
      final completion = game.waitForCommandEffects();
      _expectCenter(unit.visualCenter, origin);
      expect(unit.debugOnCity, isFalse);
      expect(unit.debugSpriteSize, const ui.Size(64, 86));
      game.update(0.15);
      _expectCenter(unit.visualCenter, ui.Offset.lerp(origin, middle, 0.25)!);
      expect(unit.debugSpriteAction, MapUnitSpriteAction.walk);
      expect(unit.debugSpriteFrame!.id.value, 'unit.commander.walk.1');
      expect(unit.debugSpriteMirrored, isFalse);
      final center = unit.visualCenter;
      game.replaceScene(
        movementCameraSnapshot(revision: 1, selected: 'moving'),
      );
      _expectCenter(unit.visualCenter, center);
      game.update(0.45);
      _expectCenter(unit.visualCenter, middle);
      game.update(0.3);
      _expectCenter(
        unit.visualCenter,
        ui.Offset.lerp(middle, destination, 0.5)!,
      );
      expect(unit.debugOnCity, isFalse);
      expect(unit.debugSpriteSize, const ui.Size(64, 86));
      game.update(0.3);
      await completion;
      _expectCenter(unit.visualCenter, destination.translate(26, 26));
      expect(unit.debugOnCity, isTrue);
      expect(unit.debugSpriteSize, const ui.Size(42, 57));
      expect(unit.debugSpriteAction, MapUnitSpriteAction.idle);
      expect(unit.debugSpriteFrame!.id.value, 'unit.commander.idle.0');
      expect(host.debugCompletedMovementCount, 1);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'reduced motion freezes idle frames while other presentation time advances',
    AonwFlameGame.new,
    (game) async {
      game.setReducedMotion(true);
      game.replaceScene(movementCameraSnapshot());
      await game.ready();
      final unit = game.world.unitLayer.componentForUnit('moving')!;
      await unit.debugLoadSprite();
      final frame = unit.debugSpriteFrame;
      unit.update(0.31);
      expect(unit.debugSpriteFrame, same(frame));
      game.setReducedMotion(false);
      unit.update(0.31);
      expect(unit.debugSpriteFrame, isNot(same(frame)));
      game.setReducedMotion(true);
      final frozen = unit.debugSpriteFrame;
      game.replaceScene(movementCameraSnapshot(revision: 1));
      expect(unit.debugSpriteAction, MapUnitSpriteAction.idle);
      expect(unit.debugSpriteFrame, same(frozen));
      expect(game.world.effectHost.debugActiveEffectCount, 0);
    },
  );

  testWithGame<AonwFlameGame>(
    'turns the sprite with the route and holds direction on vertical steps',
    AonwFlameGame.new,
    (game) async {
      const path = [
        (col: 6, row: 3),
        (col: 5, row: 3),
        (col: 5, row: 4),
        (col: 6, row: 4),
      ];
      game.replaceScene(movementCameraSnapshot(path: path));
      await game.ready();
      final unit = game.world.unitLayer.componentForUnit('moving')!;
      game.replaceScene(movementCameraSnapshot(revision: 1, path: path));
      final host = game.world.effectHost;
      host.update(0.3);
      expect(unit.debugSpriteMirrored, isTrue);
      host.update(0.3);
      expect(unit.debugSpriteMirrored, isTrue);
      host.update(0.6);
      expect(unit.debugSpriteMirrored, isFalse);
      game.skipEffects();
      expect(unit.debugSpriteAction, MapUnitSpriteAction.idle);
      expect(unit.debugSpriteMirrored, isFalse);
    },
  );
}

void _expectCenter(ui.Offset actual, ui.Offset expected) =>
    expect((actual - expected).distance, lessThan(0.0001));
