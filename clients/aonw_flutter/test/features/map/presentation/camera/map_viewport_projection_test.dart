import 'package:aonw_flutter/features/map/presentation/camera/map_viewport_projection.dart';
import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips every hex center through canvas coordinates', () {
    const geometry = AonwOddQFlatTopGeometry(cols: 7, rows: 7, radius: 60);
    const projection = MapViewportProjection(geometry);

    for (var row = 0; row < geometry.rows; row++) {
      for (var col = 0; col < geometry.cols; col++) {
        final coordinate = (col: col, row: row);
        expect(projection.hexAt(projection.hexCenter(coordinate)), coordinate);
      }
    }
  });

  test('matches the original 0.62 board projection and top-face anchor', () {
    const geometry = AonwOddQFlatTopGeometry(cols: 7, rows: 7, radius: 60);
    const projection = MapViewportProjection(geometry);
    const coordinate = (col: 3, row: 2);
    final canonical = geometry.center(coordinate);
    final bounds = geometry.bounds;
    final center = projection.hexCenter(coordinate);
    final topFace = projection.hexTopFaceCenter(coordinate);

    expect(center.x, closeTo(canonical.x - bounds.x, 1e-9));
    expect(
      center.y,
      closeTo(
        (canonical.y - bounds.y) * MapViewportProjection.perspectiveY,
        1e-9,
      ),
    );
    expect(topFace.x, center.x);
    expect(topFace.y, closeTo(center.y - 12 * 0.62, 1e-9));

    const point = (x: 321.5, y: 456.25);
    final restored = projection.unproject(projection.project(point));
    expect(restored.x, closeTo(point.x, 1e-9));
    expect(restored.y, closeTo(point.y, 1e-9));
  });

  test('rejects canvas points outside the map', () {
    const projection = MapViewportProjection(
      AonwOddQFlatTopGeometry(cols: 2, rows: 2),
    );

    expect(projection.hexAt((x: -100, y: -100)), isNull);
  });
}
