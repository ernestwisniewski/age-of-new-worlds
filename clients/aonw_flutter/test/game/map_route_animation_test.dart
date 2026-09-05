import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/map/map_interaction_geometry.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/route_animation_test_fixture.dart';

void main() {
  testWidgets(
    'flows along cached route geometry with six walking ghost frames',
    (tester) async {
      final game = await _mount(tester);
      final route = game.world.routeLayer;
      final cache = game.world.debugStaticRenderCache!;
      final writes = game.world.debugSceneWriteCount;
      final start = mapProjectedTopFaceCenter(cache, (col: 2, row: 2));
      final next = mapProjectedTopFaceCenter(cache, (col: 3, row: 2));
      expect((route.debugGhostPosition! - start).distance, lessThan(0.0001));
      expect(route.debugGhostMirrored, isFalse);
      final frames = <String>{route.debugGhostFrameId!};
      for (var index = 0; index < 5; index++) {
        route.update(0.14);
        frames.add(route.debugGhostFrameId!);
      }
      route.update(0.30);
      expect(frames, {for (var i = 0; i < 6; i++) 'unit.commander.walk.$i'});
      expect(route.debugFlowPhase, closeTo(24, 0.00001));
      final expected = start + (next - start) / (next - start).distance * 19.68;
      expect((route.debugGhostPosition! - expected).distance, lessThan(0.001));
      expect(route.debugPathBuildCount, 1);
      expect(game.world.debugSceneWriteCount, writes);
      expect(game.world.debugStaticRenderCache, same(cache));
      expect(game.paused, isFalse);
      await game.waitForCommandEffects();
      final phase = route.debugFlowPhase;
      game.replaceScene(routeAnimationSnapshot());
      game.replaceCursor((col: 5, row: 2));
      expect(route.debugPathBuildCount, 1);
      expect(route.debugFlowPhase, phase);
      game.replaceScene(routeAnimationSnapshot(reverse: true));
      expect(route.debugPathBuildCount, 2);
      expect(route.debugFlowPhase, 0);
      expect(route.debugGhostMirrored, isTrue);
      expect(route.debugGhostFrameId, 'unit.commander.walk.0');
      await _unmount(tester);
    },
  );

  testWidgets(
    'pauses outside the viewport and resets when motion is disabled',
    (tester) async {
      final game = await _mount(tester);
      final route = game.world.routeLayer;
      for (final mode in ['hidden', 'offscreen', 'disabled', 'reduced']) {
        route.update(0.31);
        _stop(game, mode);
        final phase = route.debugFlowPhase;
        final frame = route.debugGhostFrameId;
        final updates = route.debugActiveUpdateCount;
        expect(game.paused, isTrue, reason: mode);
        route.update(20);
        await tester.pump(const Duration(seconds: 2));
        expect(route.debugFlowPhase, phase, reason: mode);
        expect(route.debugGhostFrameId, frame, reason: mode);
        expect(route.debugActiveUpdateCount, updates, reason: mode);
        expect(route.isVisible, isTrue);
        if (mode == 'disabled' || mode == 'reduced') {
          expect(phase, 0);
          expect(frame, 'unit.commander.walk.0');
        }
        _resume(game, mode);
        expect(game.paused, isFalse, reason: mode);
      }
      game.setCinematicCamera(true);
      expect(game.paused, isFalse);
      game.mapCamera.centerOnHex((col: 19, row: 15));
      expect(game.paused, isTrue);
      game.mapCamera.centerOnHex((col: 3, row: 2));
      expect(game.paused, isFalse);
      game.replaceScene(routeAnimationSnapshot(showRoute: false));
      expect(game.paused, isTrue);
      expect(route.isVisible, isFalse);
      expect(route.debugGhostFrameId, isNull);
      expect(route.debugGhostPosition, isNull);
      expect(route.debugPathBuildCount, 1);
      await _unmount(tester);
    },
  );

  testWidgets(
    'caches dashed strokes per phase and invalidates changed geometry',
    (tester) async {
      final game = await _mount(tester);
      final route = game.world.routeLayer;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      route.render(canvas);
      final initial = route.debugDashBuildCount;
      route.render(canvas);
      expect(route.debugDashBuildCount, initial);
      route.update(0.1);
      route.render(canvas);
      expect(
        route.debugDashBuildCount,
        initial + route.debugSegmentCount,
        reason: 'target remains static and glow reuses the line dashes',
      );
      final beforeCulling = route.debugDashBuildCount;
      canvas.save();
      canvas.clipRect(const ui.Rect.fromLTWH(-10000, -10000, 10, 10));
      route.update(0.1);
      route.render(canvas);
      canvas.restore();
      expect(route.debugDashBuildCount, beforeCulling);
      recorder.endRecording().dispose();
      game.replaceScene(routeAnimationSnapshot(roads: false));
      expect(route.debugPathBuildCount, 2);
      expect(route.debugSegmentFollowsRoad(0), isFalse);
      game.replaceScene(
        routeAnimationSnapshot(roads: false, mapId: 'different-map'),
      );
      expect(route.debugPathBuildCount, 3);
      final phase = route.debugFlowPhase;
      for (final dt in [double.nan, double.infinity, -1.0, 0.0]) {
        route.update(dt);
      }
      expect(route.debugFlowPhase, phase);
      route.update(10000 / 24);
      expect(route.debugFlowPhase, closeTo(0, 0.00001));
      await _unmount(tester);
    },
  );
}

Future<AonwFlameGame> _mount(WidgetTester tester) async {
  await tester.runAsync(() async {
    final sprite = MapUnitSpriteAnimation(
      kind: VisibleUnitKind.commander,
      onLoaded: () {},
    );
    await sprite.load();
    sprite.dispose();
  });
  final game = AonwFlameGame();
  game.setUnitIdleAnimations(false);
  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  game.replaceScene(routeAnimationSnapshot());
  await tester.runAsync(game.ready);
  await tester.pump();
  await tester.runAsync(game.world.routeLayer.debugLoadGhost);
  game.mapCamera.centerOnHex((col: 3, row: 2));
  game.setViewportActive(true);
  return game;
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void _stop(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'hidden':
      game.setViewportActive(false);
    case 'offscreen':
      game.mapCamera.centerOnWorld((x: -10000, y: -10000));
    case 'disabled':
      game.setRouteAnimations(false);
    case 'reduced':
      game.setReducedMotion(true);
  }
}

void _resume(AonwFlameGame game, String mode) {
  switch (mode) {
    case 'hidden':
      game.setViewportActive(true);
    case 'offscreen':
      game.mapCamera.centerOnHex((col: 3, row: 2));
    case 'disabled':
      game.setRouteAnimations(true);
    case 'reduced':
      game.setReducedMotion(false);
  }
}
