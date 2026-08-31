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

  test('rejects canvas points outside the map', () {
    const projection = MapViewportProjection(
      AonwOddQFlatTopGeometry(cols: 2, rows: 2),
    );

    expect(projection.hexAt((x: -100, y: -100)), isNull);
  });
}
