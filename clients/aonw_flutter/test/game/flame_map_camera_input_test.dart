import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/flame_map_viewport.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'uses one camera for authored zoom picking pan and resize',
    () => AonwFlameGame(),
    (game) async {
      final scene = testMapScene(cols: 7, rows: 7, defaultZoom: 1.2);
      game.onGameResize(Vector2(900, 800));
      game.sceneSink.replaceScene(_snapshot(scene));
      await game.ready();

      final initial = game.mapCamera.debugTransform!;
      expect(game.camera.viewfinder.anchor, Anchor.center);
      expect(game.camera.viewfinder.zoom, closeTo(initial.zoom, 1e-6));
      for (var row = 0; row < scene.map.rows; row++) {
        for (var col = 0; col < scene.map.cols; col++) {
          final coordinate = (col: col, row: row);
          final screen = game.debugScreenForHex(coordinate)!;
          expect(game.debugHexAtScreen(screen), coordinate);
        }
      }

      game.mapCamera.applyIntent(const MapPanIntent((x: 48, y: -32)));
      final afterPan = game.mapCamera.debugTransform!;
      expect(afterPan.worldCenter, isNot(initial.worldCenter));

      final focal = game.debugScreenForHex((col: 3, row: 3))!;
      final focalWorld = afterPan.screenToWorld(focal);
      game.mapCamera.applyIntent(MapZoomIntent(focalPoint: focal, factor: 1.5));
      final afterZoom = game.mapCamera.debugTransform!;
      final focalWorldAfter = afterZoom.screenToWorld(focal);
      expect(focalWorldAfter.x, closeTo(focalWorld.x, 1e-9));
      expect(focalWorldAfter.y, closeTo(focalWorld.y, 1e-9));

      final centerBeforeResize = afterZoom.worldCenter;
      game.onGameResize(Vector2(1100, 700));
      expect(
        game.mapCamera.debugTransform!.worldCenter.x,
        closeTo(centerBeforeResize.x, 1e-9),
      );
      expect(
        game.mapCamera.debugTransform!.worldCenter.y,
        closeTo(centerBeforeResize.y, 1e-9),
      );

      final oracle =
          jsonDecode(_inputOracleFile().readAsStringSync())
              as Map<String, dynamic>;
      final dimensions = oracle['map']! as Map<String, dynamic>;
      final corpusScene = testMapScene(
        cols: dimensions['cols']! as int,
        rows: dimensions['rows']! as int,
        contentHash: 'e' * 64,
      );
      game.sceneSink.replaceScene(_snapshot(corpusScene));
      for (final value in oracle['inputCases']! as List<dynamic>) {
        final inputCase = value! as Map<String, dynamic>;
        if (inputCase['source'] != 'pointer') continue;
        final expected = inputCase['expectedSelectedHex']! as List<dynamic>;
        final coordinate = (col: expected[0]! as int, row: expected[1]! as int);
        final screen = game.debugScreenForHex(coordinate)!;
        expect(game.debugHexAtScreen(screen), coordinate);
      }
    },
  );

  final coalescedIntents = <MapHexIntent>[];
  testWithGame<AonwFlameGame>(
    'coalesces hover pan and scale without rebuilding static resources',
    () => AonwFlameGame(onHexIntent: coalescedIntents.add),
    (game) async {
      coalescedIntents.clear();
      final scene = testMapScene(cols: 40, rows: 30);
      game.onGameResize(Vector2(1200, 800));
      game.sceneSink.replaceScene(_snapshot(scene));
      game.setViewportActive(true);
      await game.ready();
      final surface = game.inputSurface;
      final center = game.debugScreenForHex((col: 20, row: 15))!;
      final point = Vector2(center.x, center.y);

      surface.submitHover(point);
      game.update(1 / 60);
      expect(coalescedIntents, hasLength(1));
      expect((coalescedIntents.single as MapHexHoverIntent).coordinate, (
        col: 20,
        row: 15,
      ));
      final terrainUpdates = game.world.terrainLayer.debugCacheUpdateCount;
      final referenceUpdates = game.world.referenceLayer.debugCacheUpdateCount;
      final gridUpdates = game.world.gridLayer.debugCacheUpdateCount;
      final decodedPages = game.world.referenceLayer.debugDecodedPageCount;
      final cameraUpdates = game.mapCamera.debugTransformUpdateCount;

      for (var event = 0; event < 1000; event++) {
        surface.submitHover(point);
      }
      surface.submitPan(Vector2(1, -0.5));
      surface.submitPan(Vector2(2, -1.5));
      surface.submitZoom(focalPoint: point, factor: 1.1);
      surface.submitZoom(focalPoint: point, factor: 1.2);
      game.update(1 / 60);

      expect(
        coalescedIntents,
        hasLength(1),
        reason: 'the hovered hex did not change',
      );
      expect(surface.debugFlushCount, 2);
      expect(game.mapCamera.debugTransformUpdateCount, cameraUpdates + 1);
      expect(game.world.terrainLayer.debugCacheUpdateCount, terrainUpdates);
      expect(game.world.referenceLayer.debugCacheUpdateCount, referenceUpdates);
      expect(game.world.gridLayer.debugCacheUpdateCount, gridUpdates);
      expect(game.world.referenceLayer.debugDecodedPageCount, decodedPages);

      game.setViewportActive(false);
      surface.submitSelect(point);
      expect(coalescedIntents, hasLength(1));
    },
  );

  testWidgets('routes a real Flame tap through the framework-neutral intent', (
    tester,
  ) async {
    final intents = <MapHexIntent>[];
    final game = AonwFlameGame(onHexIntent: intents.add);
    game.sceneSink.replaceScene(_snapshot(testMapScene(cols: 7, rows: 7)));
    game.setViewportActive(true);
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MapViewportGestureLayer(
          game: game,
          child: GameWidget<AonwFlameGame>(
            game: game,
            autofocus: false,
            behavior: HitTestBehavior.opaque,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await game.toBeLoaded();
    });
    await tester.pump();
    await tester.runAsync(game.ready);
    await tester.pump(const Duration(milliseconds: 10));
    expect(game.inputSurface.isMounted, isTrue);
    expect(game.inputSurface.size.x, closeTo(900, 1e-9));
    expect(game.inputSurface.size.y, closeTo(800, 1e-9));
    final screen = game.debugScreenForHex((col: 3, row: 3))!;
    final gameWidget = find.byType(GameWidget<AonwFlameGame>);
    await tester.tapAt(
      tester.getTopLeft(gameWidget) + Offset(screen.x, screen.y),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final select = intents.whereType<MapHexSelectIntent>().single;
    expect(select.coordinate, (col: 3, row: 3));

    intents.clear();
    await tester.longPressAt(
      tester.getTopLeft(gameWidget) + Offset(screen.x, screen.y),
    );
    await tester.pump();
    final longPress = intents.whereType<MapHexLongPressIntent>().single;
    expect(longPress.coordinate, (col: 3, row: 3));
    expect(longPress.screenPosition.x, closeTo(screen.x, 1e-3));
    expect(longPress.screenPosition.y, closeTo(screen.y, 1e-3));

    final beforeDrag = game.mapCamera.debugTransformUpdateCount;
    await tester.drag(gameWidget, const Offset(36, 24));
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.mapCamera.debugTransformUpdateCount, greaterThan(beforeDrag));

    final beforeScroll = game.mapCamera.debugTransformUpdateCount;
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(gameWidget),
        scrollDelta: const Offset(0, -40),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(game.mapCamera.debugTransformUpdateCount, greaterThan(beforeScroll));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

MapRenderSnapshot _snapshot(MapScene scene) => MapRenderSnapshot(
  map: scene.map,
  interaction: const MapInteractionState(),
  reference: scene.reference,
  player: scene.player,
);

File _inputOracleFile() {
  for (final path in ['test/fixtures/input/viewport_oracle.json']) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  throw StateError('Flutter viewport oracle fixture not found.');
}
