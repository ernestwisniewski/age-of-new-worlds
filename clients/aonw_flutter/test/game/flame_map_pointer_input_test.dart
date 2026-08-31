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
  final emitted = <MapHexIntent>[];

  testWithGame<AonwFlameGame>(
    'starts dragging at 8px and includes pending movement',
    () => AonwFlameGame(onHexIntent: emitted.add),
    (game) async {
      emitted.clear();
      await _prepare(game);
      final surface = game.inputSurface;
      final initial = game.mapCamera.debugTransform!;

      surface
        ..handlePointerDown(1, Vector2.zero())
        ..handlePointerMove(1, Vector2(3, 0));
      game.update(0);
      expect(surface.debugIsDragging, isFalse);
      expect(game.mapCamera.debugTransform!.worldCenter, initial.worldCenter);

      surface.handlePointerMove(1, Vector2(10, 0));
      expect(surface.debugIsDragging, isTrue);
      expect(game.mapCamera.debugTransform!.worldCenter, initial.worldCenter);
      game.update(0);
      expect(
        game.mapCamera.debugTransform!.worldCenter.x,
        closeTo(initial.worldCenter.x - 10, 1e-9),
      );

      surface
        ..handlePointerUp(1)
        ..submitSelect(Vector2(20, 20));
      expect(surface.debugIsDragging, isFalse);
      expect(emitted.whereType<MapHexSelectIntent>(), isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'opposing pointer jitter does not cross the drag threshold',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      final surface = game.inputSurface;
      final initial = game.mapCamera.debugTransform!;

      surface
        ..handlePointerDown(1, Vector2.zero())
        ..handlePointerMove(1, Vector2(6, 0))
        ..handlePointerMove(1, Vector2.zero());
      game.update(0);

      expect(surface.debugIsDragging, isFalse);
      expect(game.mapCamera.debugTransform!.worldCenter, initial.worldCenter);
    },
  );

  testWithGame<AonwFlameGame>(
    'pinch keeps its initial world focus under the moving midpoint',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      final surface = game.inputSurface;
      final initial = game.mapCamera.debugTransform!;
      final worldFocus = initial.screenToWorld((x: 5, y: 0));

      surface
        ..handlePointerDown(1, Vector2.zero())
        ..handlePointerDown(2, Vector2(10, 0))
        ..handlePointerMove(2, Vector2(20, 0));
      expect(game.mapCamera.debugTransform!.zoom, 1);
      game.update(0);

      final transformed = game.mapCamera.debugTransform!;
      expect(transformed.zoom, 2);
      final restored = transformed.screenToWorld((x: 10, y: 0));
      expect(restored.x, closeTo(worldFocus.x, 1e-9));
      expect(restored.y, closeTo(worldFocus.y, 1e-9));
    },
  );

  testWithGame<AonwFlameGame>(
    'wheel and trackpad use the original zoom contract',
    AonwFlameGame.new,
    (game) async {
      await _prepare(game);
      final surface = game.inputSurface;
      final focalPoint = Vector2(300, 240);
      final worldBefore = game.mapCamera.debugTransform!.screenToWorld((
        x: focalPoint.x,
        y: focalPoint.y,
      ));

      surface.handleScroll(focalPoint: focalPoint, deltaY: -40);
      game.update(0);
      expect(game.mapCamera.debugTransform!.zoom, closeTo(1.04, 1e-9));

      surface
        ..handlePanZoomStart(focalPoint)
        ..handlePanZoomUpdate(
          panDelta: Vector2.zero(),
          scale: 5 / 1.04,
          focalPoint: focalPoint,
        );
      game.update(0);
      final transformed = game.mapCamera.debugTransform!;
      expect(transformed.zoom, 5);
      final worldAfter = transformed.screenToWorld((
        x: focalPoint.x,
        y: focalPoint.y,
      ));
      expect(worldAfter.x, closeTo(worldBefore.x, 1e-9));
      expect(worldAfter.y, closeTo(worldBefore.y, 1e-9));
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
