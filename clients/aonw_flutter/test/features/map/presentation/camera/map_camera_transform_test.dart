import 'package:aonw_flutter/features/map/presentation/camera/map_camera_transform.dart';
import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches the centered Canvas fit in logical pixels', () {
    final camera = MapCameraTransform.fitted(
      viewport: (width: 900, height: 800),
      content: (width: 750, height: 600),
      authoredZoom: 1.25,
    );

    expect(camera.zoom, closeTo(1.5, 1e-9));
    expect(camera.worldCenter.x, closeTo(375, 1e-9));
    expect(camera.worldCenter.y, closeTo(300, 1e-9));
    final origin = camera.worldToScreen((x: 0, y: 0));
    expect(origin.x, closeTo(-112.5, 1e-9));
    expect(origin.y, closeTo(-50, 1e-9));
  });

  test('round-trips centers edges corners and outside across DPR values', () {
    const geometry = AonwOddQFlatTopGeometry(cols: 7, rows: 7, radius: 60);
    const projection = MapViewportProjection(geometry);
    final bounds = geometry.bounds;

    for (final dpr in [1.0, 1.5, 2.0, 3.0]) {
      final logicalViewport = (width: 1200 / dpr, height: 900 / dpr);
      final camera = MapCameraTransform.fitted(
        viewport: logicalViewport,
        content: (width: bounds.width, height: bounds.height),
        authoredZoom: 1,
      );
      final center = projection.hexCenter((col: 3, row: 3));
      final cornerWorld = geometry.corner((col: 3, row: 3), 2);
      final corner = (x: cornerWorld.x - bounds.x, y: cornerWorld.y - bounds.y);
      final nextCornerWorld = geometry.corner((col: 3, row: 3), 3);
      final edge = (
        x: (cornerWorld.x + nextCornerWorld.x) / 2 - bounds.x,
        y: (cornerWorld.y + nextCornerWorld.y) / 2 - bounds.y,
      );

      for (final world in [center, corner, edge]) {
        final logical = camera.worldToScreen(world);
        final physical = (x: logical.x * dpr, y: logical.y * dpr);
        final restoredLogical = (x: physical.x / dpr, y: physical.y / dpr);
        final roundTrip = camera.screenToWorld(restoredLogical);
        expect(roundTrip.x, closeTo(world.x, 1e-9));
        expect(roundTrip.y, closeTo(world.y, 1e-9));
      }

      final outsideScreen = camera.worldToScreen((x: -100, y: -100));
      expect(projection.hexAt(camera.screenToWorld(outsideScreen)), isNull);
    }
  });

  test('keeps the focal world point stable and clamps pan after resize', () {
    var camera = MapCameraTransform.fitted(
      viewport: (width: 500, height: 400),
      content: (width: 1200, height: 900),
      authoredZoom: 1,
    );
    const focal = (x: 140.0, y: 110.0);
    final beforeZoom = camera.screenToWorld(focal);

    camera = camera.zoomAtScreen(focalPoint: focal, factor: 1.8);
    final afterZoom = camera.screenToWorld(focal);
    expect(afterZoom.x, closeTo(beforeZoom.x, 1e-9));
    expect(afterZoom.y, closeTo(beforeZoom.y, 1e-9));

    final beforeResizeCenter = camera.worldCenter;
    camera = camera.resized((width: 700, height: 500));
    expect(camera.worldCenter.x, closeTo(beforeResizeCenter.x, 1e-9));
    expect(camera.worldCenter.y, closeTo(beforeResizeCenter.y, 1e-9));

    camera = camera.panByScreen((x: 100000, y: 100000));
    expect(camera.worldCenter.x, greaterThanOrEqualTo(0));
    expect(camera.worldCenter.y, greaterThanOrEqualTo(0));
    expect(camera.worldCenter.x, lessThanOrEqualTo(camera.content.width));
    expect(camera.worldCenter.y, lessThanOrEqualTo(camera.content.height));
  });
}
