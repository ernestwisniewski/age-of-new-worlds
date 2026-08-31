import '../../read_model/map_view.dart';
import '../geometry/odd_q_flat_top_geometry.dart';

final class MapViewportProjection {
  const MapViewportProjection(this.geometry);

  final AonwOddQFlatTopGeometry geometry;

  AonwPoint hexCenter(MapHexCoordinate coordinate) {
    final center = geometry.center(coordinate);
    final bounds = geometry.bounds;
    return (x: center.x - bounds.x, y: center.y - bounds.y);
  }

  MapHexCoordinate? hexAt(AonwPoint canvasPoint) {
    final bounds = geometry.bounds;
    final coordinate = geometry.hexAt((
      x: canvasPoint.x + bounds.x,
      y: canvasPoint.y + bounds.y,
    ));
    if (coordinate.col < 0 ||
        coordinate.col >= geometry.cols ||
        coordinate.row < 0 ||
        coordinate.row >= geometry.rows) {
      return null;
    }
    return coordinate;
  }
}
