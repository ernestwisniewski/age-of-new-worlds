import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/flame_map_camera.dart';
import 'package:aonw_flutter/game/map/map_cinematic_projection.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/movement_camera_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'visible world bounds preserve the viewport clip through projection and resize',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(movementCameraSnapshot());
      await game.ready();
      for (final size in [Vector2(900, 700), Vector2(390, 844)]) {
        game.onGameResize(size);
        for (final zoom in [0.2, 1.0, 5.0]) {
          game.setCinematicCamera(false);
          game.mapCamera.applyIntent(
            MapZoomIntent(
              focalPoint: game.mapCamera.viewportCenter!,
              factor: zoom / game.mapCamera.zoom,
            ),
          );
          final flat = game.mapCamera.visibleWorldBounds;
          game.setCinematicCamera(true);
          final cinematic = game.mapCamera.visibleWorldBounds;
          expect(cinematic, flat);
          expect(cinematic.width, closeTo(size.x / zoom, 1e-8));
          expect(cinematic.height, closeTo(size.y / zoom, 1e-8));
        }
      }
    },
  );

  test('cinematic perspective preserves its reference shape and inverse', () {
    final projection = MapCinematicProjection();
    for (final size in [
      Vector2(1280, 720),
      Vector2(768, 1024),
      Vector2(390, 844),
    ]) {
      projection.resize(size.x, size.y);
      final matrix = projection.matrix;
      projection.resize(size.x, size.y);
      expect(projection.matrix, same(matrix));
      final topLeft = projection.project((x: 0, y: 0));
      expect(topLeft.x, closeTo(size.x * 0.13 / 1.26, 1e-9));
      expect(topLeft.y, closeTo(size.y * 0.26 / 1.26, 1e-9));
      for (final point in [
        (x: 0.0, y: 0.0),
        (x: size.x, y: 0.0),
        (x: 0.0, y: size.y),
        (x: size.x, y: size.y),
        (x: size.x * 0.3, y: size.y * 0.6),
      ]) {
        final projected = projection.project(point);
        final restored = projection.unproject(projected);
        expect(restored.x, closeTo(point.x, 1e-9));
        expect(restored.y, closeTo(point.y, 1e-9));
        if (point.y == size.y) {
          expect(projected.x, closeTo(point.x, 1e-9));
          expect(projected.y, closeTo(point.y, 1e-9));
        }
      }
    }
  });

  testWithGame<AonwFlameGame>(
    'projection preserves picking and zoom focus through resize and camera motion',
    AonwFlameGame.new,
    (game) async {
      game.setViewportActive(true);
      game.setCinematicCamera(true);
      game.replaceScene(movementCameraSnapshot());
      await game.ready();
      final cache = game.world.debugStaticRenderCache;
      for (final size in [Vector2(900, 700), Vector2(390, 844)]) {
        game.onGameResize(size);
        game.mapCamera.centerOnHex((col: 6, row: 3));
        for (var col = 1; col < 11; col++) {
          final coordinate = (col: col, row: 3);
          final point = game.debugScreenForHex(coordinate)!;
          expect(game.debugHexAtScreen(point), coordinate);
        }
        const focal = (x: 250.0, y: 350.0);
        final before = game.mapCamera.worldAtScreen(focal)!;
        game.mapCamera.applyIntent(
          const MapZoomIntent(focalPoint: focal, factor: 1.3),
        );
        final after = game.mapCamera.worldAtScreen(focal)!;
        expect(after.x, closeTo(before.x, 1e-9));
        expect(after.y, closeTo(before.y, 1e-9));
        game.mapCamera.followWorldPoint(() => (x: 600, y: 500));
        game.update(0.1);
        final point = game.debugScreenForHex((col: 5, row: 3))!;
        expect(game.debugHexAtScreen(point), (col: 5, row: 3));
        game.skipEffects();
      }
      game.setReducedMotion(true);
      game.setSmoothCameraMovement(false);
      expect(game.mapCamera.cinematicEnabled, isTrue);
      expect(game.paused, isTrue);
      final updates = game.mapCamera.debugTransformUpdateCount;
      game.update(1);
      game.setCinematicCamera(false);
      expect(game.mapCamera.cinematicMatrix, isNull);
      expect(game.mapCamera.debugTransformUpdateCount, updates);
      expect(game.world.debugStaticRenderCache, same(cache));
    },
  );

  final intents = <MapHexIntent>[];
  testWithGame<AonwFlameGame>(
    'projection changes refresh a stationary hover without rewriting the scene',
    () => AonwFlameGame(onHexIntent: intents.add),
    (game) async {
      intents.clear();
      game.onGameResize(Vector2(900, 700));
      game.replaceScene(movementCameraSnapshot());
      game.setViewportActive(true);
      await game.ready();
      game.mapCamera.centerOnHex((col: 6, row: 3));
      final point = game.debugScreenForHex((col: 6, row: 3))!;
      game.handleViewportHover(Vector2(point.x, point.y));
      game.update(0);
      expect((intents.last as MapHexHoverIntent).coordinate, (col: 6, row: 3));
      final beforeChange = intents.length;
      game.setCinematicCamera(true);
      expect(intents, hasLength(beforeChange));
      game.update(0);
      final projectedHex = game.debugHexAtScreen(point);
      expect(projectedHex, isNot((col: 6, row: 3)));
      expect((intents.last as MapHexHoverIntent).coordinate, projectedHex);
      final count = intents.length;
      game.setCinematicCamera(true);
      expect(intents, hasLength(count));
      game.handleViewportExit();
      game.setCinematicCamera(false);
      expect(intents, hasLength(count + 1));
      expect((intents.last as MapHexHoverIntent).coordinate, isNull);
      expect(game.paused, isTrue);
    },
  );
}
