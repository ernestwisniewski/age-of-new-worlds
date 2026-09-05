import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:aonw_flutter/game/map/unit_map_layer.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';
import '../support/movement_camera_test_fixture.dart';

void main() {
  testWidgets('changes visible idle poses without a continuous Flame loop', (
    tester,
  ) async {
    final game = await _mountIdleGame(tester);
    final layer = game.world.unitLayer;
    final unit = layer.componentForUnit('near')!;
    final distant = layer.componentForUnit('far')!;
    final writes = game.world.debugSceneWriteCount;
    final cache = game.world.debugStaticRenderCache;
    final effects = game.world.effectHost.debugActiveUpdateCount;
    final paints = unit.debugPaintCount;
    expect(layer.debugAnimationScheduled, isTrue);
    expect(game.paused, isTrue);
    await tester.pump(const Duration(milliseconds: 303));
    expect(_index(unit), 0);
    expect(unit.debugPaintCount, paints);
    await tester.pump(const Duration(milliseconds: 1));
    expect(_index(unit), 1);
    expect(unit.debugPaintCount, greaterThan(paints));
    expect(_index(distant), 0);
    expect(layer.debugAnimationTicks, 1);
    expect(game.paused, isTrue);
    expect(game.world.debugSceneWriteCount, writes);
    expect(game.world.debugStaticRenderCache, same(cache));
    expect(game.world.effectHost.debugActiveUpdateCount, effects);
    await game.waitForCommandEffects();
    game.update(100);
    expect(
      _index(unit),
      1,
      reason: 'Flame must not advance idle a second time',
    );
    await _unmount(tester, game);
  });

  testWidgets('preserves partial frames and cancels timers while disabled', (
    tester,
  ) async {
    final game = await _mountIdleGame(tester);
    final layer = game.world.unitLayer;
    final unit = layer.componentForUnit('near')!;
    await tester.pump(const Duration(milliseconds: 100));
    game.setUnitIdleAnimations(false);
    expect(layer.debugAnimationScheduled, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(_index(unit), 0);
    game.setUnitIdleAnimations(true);
    await tester.pump(const Duration(milliseconds: 204));
    expect(_index(unit), 1);
    for (final stop in ['reduced', 'hidden', 'offscreen', 'zoom']) {
      _disable(game, stop);
      final frame = unit.debugSpriteFrame;
      final ticks = layer.debugAnimationTicks;
      expect(layer.debugAnimationScheduled, isFalse, reason: stop);
      await tester.pump(const Duration(seconds: 10));
      expect(unit.debugSpriteFrame, same(frame), reason: stop);
      expect(layer.debugAnimationTicks, ticks, reason: stop);
      _enable(game, stop);
      expect(layer.debugAnimationScheduled, isTrue, reason: stop);
    }
    expect(layer.idleAnimationsEnabled, isTrue);
    await _unmount(tester, game);
  });

  testWidgets('sleeps through cycle pauses and selection removes the pause', (
    tester,
  ) async {
    final game = await _mountIdleGame(tester);
    final layer = game.world.unitLayer;
    final unit = layer.componentForUnit('near')!;
    await tester.pump(const Duration(milliseconds: 1821));
    expect(_index(unit), 0);
    final ticks = layer.debugAnimationTicks;
    final paints = unit.debugPaintCount;
    await tester.pump(const Duration(milliseconds: 500));
    expect(layer.debugAnimationTicks, ticks);
    expect(unit.debugPaintCount, paints);
    game.setSmoothCameraMovement(false);
    game.replaceScene(_snapshot(selected: 'near'));
    expect(unit, same(layer.componentForUnit('near')));
    await tester.pump(const Duration(milliseconds: 304));
    expect(_index(unit), 1);
    await tester.pump(const Duration(milliseconds: 1517));
    expect(_index(unit), 0);
    await tester.pump(const Duration(milliseconds: 304));
    expect(_index(unit), 1, reason: 'selected units have no inter-cycle pause');
    await _unmount(tester, game);
  });

  testWidgets('marching leaves the idle clock and completion rejoins it', (
    tester,
  ) async {
    final game = await _mountIdleGame(tester);
    game.setMovementCameraOptions((
      focusOwn: false,
      followOwn: false,
      focusForeign: false,
      followForeign: false,
    ));
    game.replaceScene(movementCameraSnapshot());
    await tester.runAsync(game.ready);
    final layer = game.world.unitLayer;
    final unit = layer.componentForUnit('moving')!;
    await tester.runAsync(unit.debugLoadSprite);
    game.mapCamera.centerOnHex((col: 6, row: 3));
    expect(layer.debugAnimationUnitCount, 1);
    game.replaceScene(movementCameraSnapshot(revision: 1));
    expect(layer.debugAnimationUnitCount, 0);
    expect(layer.debugAnimationScheduled, isFalse);
    game.world.effectHost.update(0.15);
    final walking = unit.debugSpriteFrame;
    expect(unit.advanceStationary(1), isFalse);
    expect(unit.debugSpriteFrame, same(walking));
    await tester.pump(const Duration(milliseconds: 304));
    // Drive the movement host explicitly, with the viewport stopped, to isolate
    // its time from the idle clock after the real timer has been cancelled.
    game.setViewportActive(false);
    final frame = unit.debugSpriteFrame;
    await tester.pump(const Duration(seconds: 1));
    expect(unit.debugSpriteFrame, same(frame));
    expect(walking!.id.value, contains('.walk.'));
    game.skipEffects();
    game.mapCamera.centerOnHex((col: 8, row: 3));
    game.setViewportActive(true);
    expect(layer.debugAnimationUnitCount, 1);
    expect(unit.debugSpriteFrame!.id.value, 'unit.commander.idle.0');
    await tester.pump(const Duration(milliseconds: 304));
    expect(unit.debugSpriteFrame!.id.value, 'unit.commander.idle.1');
    await _unmount(tester, game);
  });

  testWidgets(
    'cinematic idle culling respects the viewport clip and camera movement',
    (tester) async {
      final game = await _mountIdleGame(tester);
      final layer = game.world.unitLayer;
      final distant = layer.componentForUnit('far')!;
      expect(layer.debugAnimationUnitCount, 1);
      game.setCinematicCamera(true);
      expect(layer.debugAnimationUnitCount, 1);
      await tester.pump(const Duration(milliseconds: 304));
      expect(_index(distant), 0);
      final near = layer.componentForUnit('near')!;
      final nearFrame = near.debugSpriteFrame;
      game.mapCamera.centerOnHex((col: 19, row: 15));
      expect(layer.debugAnimationUnitCount, 1);
      await tester.pump(const Duration(milliseconds: 304));
      expect(_index(distant), 1);
      expect(near.debugSpriteFrame, same(nearFrame));
      game.setCinematicCamera(false);
      expect(layer.debugAnimationUnitCount, 1);
      game.clearScene();
      expect(layer.debugAnimationScheduled, isFalse);
      await _unmount(tester, game);
    },
  );
}

Future<AonwFlameGame> _mountIdleGame(WidgetTester tester) async {
  await tester.runAsync(() async {
    final sprite = MapUnitSpriteAnimation(
      kind: VisibleUnitKind.commander,
      onLoaded: () {},
    );
    await sprite.load();
    sprite.dispose();
  });
  final layer = MapUnitLayerComponent(
    now: tester.binding.clock.now,
    idlePauseDuration: () => 0.8,
  );
  final game = AonwFlameGame(world: AonwWorld(unitLayer: layer));
  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  game.replaceScene(_snapshot());
  await tester.runAsync(game.ready);
  await tester.pump();
  for (final id in ['near', 'far']) {
    await tester.runAsync(layer.componentForUnit(id)!.debugLoadSprite);
  }
  game.setViewportActive(true);
  await tester.pump();
  return game;
}

Future<void> _unmount(WidgetTester tester, AonwFlameGame game) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(game.world.unitLayer.debugAnimationScheduled, isFalse);
}

MapRenderSnapshot _snapshot({String? selected}) {
  final scene = testMapScene(
    cols: 20,
    rows: 16,
    units: [
      testVisibleUnit(id: 'near', coordinate: (col: 2, row: 2)),
      testVisibleUnit(id: 'far', coordinate: (col: 19, row: 15)),
    ],
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: scene.player,
    interaction: MapInteractionState(selectedUnitId: selected),
  );
}

int _index(MapUnitComponent unit) =>
    int.parse(unit.debugSpriteFrame!.id.value.split('.').last);

void _disable(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'reduced':
      game.setReducedMotion(true);
    case 'hidden':
      game.setViewportActive(false);
    case 'offscreen':
      game.mapCamera.centerOnWorld((x: -10000, y: -10000));
    case 'zoom':
      game.mapCamera.applyIntent(
        MapZoomIntent(focalPoint: game.mapCamera.viewportCenter!, factor: 0.84),
      );
  }
}

void _enable(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'reduced':
      game.setReducedMotion(false);
    case 'hidden':
      game.setViewportActive(true);
    case 'offscreen':
      game.mapCamera.centerOnHex((col: 2, row: 2));
    case 'zoom':
      game.mapCamera.applyIntent(
        MapZoomIntent(
          focalPoint: game.mapCamera.viewportCenter!,
          factor: 0.85 / 0.84,
        ),
      );
  }
}
