import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/game/input/flame_map_input_surface.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final sensitivity in [0.5, 1.0, 2.0]) {
    test('wheel applies sensitivity $sensitivity at the supplied focus', () {
      final frames = <MapViewportIntent>[];
      final surface = FlameMapInputSurface(
        onIntent: frames.add,
        requestFrame: () {},
      )..setEnabled(true);
      surface.setCameraSensitivity(sensitivity);
      surface.handleScroll(focalPoint: Vector2(80, 120), deltaY: -440);
      surface.update(0);
      final frame = frames.single as MapViewportFrameIntent;
      expect(
        frame.zoomFactor,
        closeTo(switch (sensitivity) {
          0.5 => 1.2,
          1.0 => 1.44,
          _ => 2.0736,
        }, 1e-9),
      );
      expect(frame.zoomFocalPoint, (x: 80.0, y: 120.0));
    });
  }

  test('trackpad increments compose and reverse without changing pan', () {
    final frames = <MapViewportIntent>[];
    final surface = FlameMapInputSurface(
      onIntent: frames.add,
      requestFrame: () {},
    )..setEnabled(true);
    surface.setCameraSensitivity(2);
    final focus = Vector2(80, 120);
    surface.handlePanZoomStart(focus);
    for (final scale in [1.2, 1.5]) {
      surface.handlePanZoomUpdate(
        panDelta: Vector2(3, 4),
        scale: scale,
        focalPoint: focus,
      );
    }
    surface.update(0);
    final forward = frames.single as MapViewportFrameIntent;
    expect(forward.zoomFactor, closeTo(2.25, 1e-9));
    expect(forward.screenPanDelta, (x: 6.0, y: 8.0));
    surface.handlePanZoomUpdate(
      panDelta: Vector2.zero(),
      scale: 1,
      focalPoint: focus,
    );
    surface.update(0);
    final reverse = frames.last as MapViewportFrameIntent;
    expect(forward.zoomFactor * reverse.zoomFactor, closeTo(1, 1e-9));
  });

  test(
    'pinch uses live sensitivity and reset preserves direct manipulation',
    () {
      final frames = <MapViewportIntent>[];
      final surface = FlameMapInputSurface(
        onIntent: frames.add,
        requestFrame: () {},
      )..setEnabled(true);
      surface.setCameraSensitivity(2);
      surface.handlePointerDown(1, Vector2.zero());
      surface.handlePointerDown(2, Vector2(20, 0));
      surface.handlePointerMove(2, Vector2(30, 0));
      surface.update(0);
      expect((frames.last as MapViewportFrameIntent).zoomFactor, 2.25);
      surface.setCameraSensitivity(1);
      surface.handlePointerMove(2, Vector2(60, 0));
      surface.update(0);
      expect((frames.last as MapViewportFrameIntent).zoomFactor, 2);
      expect((frames.last as MapViewportFrameIntent).screenPanDelta, (
        x: 15.0,
        y: 0.0,
      ));
    },
  );

  test('invalid or overflowing zoom cannot discard an accepted gesture', () {
    final frames = <MapViewportIntent>[];
    final surface = FlameMapInputSurface(
      onIntent: frames.add,
      requestFrame: () {},
    )..setEnabled(true);
    surface.setCameraSensitivity(2);
    final focus = Vector2(80, 120);
    surface.submitZoom(focalPoint: focus, factor: 1.5);
    for (final factor in [
      double.nan,
      double.infinity,
      -1.0,
      0.0,
      1e300,
      1e-300,
    ]) {
      surface.submitZoom(focalPoint: Vector2.zero(), factor: factor);
    }
    surface.update(0);
    expect((frames.single as MapViewportFrameIntent).zoomFactor, 2.25);
    expect((frames.single as MapViewportFrameIntent).zoomFocalPoint, (
      x: 80.0,
      y: 120.0,
    ));
  });
}
