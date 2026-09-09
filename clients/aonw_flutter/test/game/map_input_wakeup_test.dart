import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/game/input/flame_map_input_surface.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final input in ['pan', 'zoom', 'hover']) {
    test('cancelled $input frame lets the next input wake the renderer', () {
      var requested = 0;
      final frames = <MapViewportIntent>[];
      final surface = FlameMapInputSurface(
        onIntent: frames.add,
        requestFrame: () => requested += 1,
      )..setEnabled(true);
      switch (input) {
        case 'pan':
          surface.submitPan(Vector2(4, 3));
          surface.submitPan(Vector2(-4, -3));
        case 'zoom':
          surface.submitZoom(focalPoint: Vector2(10, 20), factor: 2);
          surface.submitZoom(focalPoint: Vector2(10, 20), factor: 0.5);
        case 'hover':
          surface.submitHover(Vector2(10, 20));
          surface.submitHoverExit();
      }
      expect(requested, 1);
      surface.update(0);
      expect(frames.whereType<MapViewportFrameIntent>(), isEmpty);
      surface.submitPan(Vector2(2, 3));
      expect(requested, 2);
      surface.update(0);
      expect(frames.whereType<MapViewportFrameIntent>().single.screenPanDelta, (
        x: 2.0,
        y: 3.0,
      ));
      surface.update(0);
      expect(requested, 2);
      expect(frames.whereType<MapViewportFrameIntent>(), hasLength(1));
    });
  }
}
