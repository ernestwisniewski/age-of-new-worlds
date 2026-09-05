import 'dart:ui';

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_canvas_clip.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'perspective retains bounded terrain and tint culling at every viewport edge',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(cols: 40, rows: 30);
      game.replaceScene(
        MapRenderSnapshot(
          map: scene.map,
          reference: scene.reference,
          player: scene.player,
          interaction: const MapInteractionState(),
        ),
      );
      final clip = _ClipProbe();
      game.world.add(clip);
      await game.ready();
      for (final size in [Vector2(1280, 720), Vector2(390, 844)]) {
        game.onGameResize(size);
        game.mapCamera.centerOnHex((col: 20, row: 15));
        for (final cinematic in [false, true]) {
          game.setCinematicCamera(cinematic);
          for (final pixelRatio in [1.0, 2.0, 3.0]) {
            final recorder = PictureRecorder();
            game.render(Canvas(recorder)..scale(pixelRatio));
            recorder.endRecording().dispose();
            expect(clip.bounds, isNot(Rect.largest));
            expect(
              game.world.terrainLayer.debugRenderedRegionCount,
              inInclusiveRange(
                1,
                game.world.debugStaticRenderCache!.terrainRegions.length - 1,
              ),
            );
            expect(
              game.world.eraTintLayer.debugRenderedRegionCount,
              inInclusiveRange(1, game.world.eraTintLayer.debugRegionCount - 1),
            );
            _expectViewportEdges(game, size, clip.bounds!);
          }
        }
      }
    },
  );
}

final class _ClipProbe extends Component {
  Rect? bounds;

  @override
  void render(Canvas canvas) {
    bounds = mapCanvasClipBounds(canvas);
  }
}

void _expectViewportEdges(AonwFlameGame game, Vector2 size, Rect bounds) {
  for (final x in [0.0, size.x]) {
    for (final y in [0.0, size.y]) {
      final point = game.mapCamera.debugTransform!.screenToWorld((x: x, y: y));
      expect(bounds.inflate(0.001).contains(Offset(point.x, point.y)), isTrue);
    }
  }
}
