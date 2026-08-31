import '../../read_model/map_view.dart';
import '../geometry/odd_q_flat_top_geometry.dart';

final class MapViewportProjection {
  const MapViewportProjection(this.geometry);

  static const perspectiveY = 0.62;
  static const _topFaceAnchorOffsetY = -12.0;

  final AonwOddQFlatTopGeometry geometry;

  AonwPoint project(AonwPoint canonicalPoint) {
    final bounds = geometry.bounds;
    return (
      x: canonicalPoint.x - bounds.x,
      y: (canonicalPoint.y - bounds.y) * perspectiveY,
    );
  }

  AonwPoint unproject(AonwPoint canvasPoint) {
    final bounds = geometry.bounds;
    return (
      x: canvasPoint.x + bounds.x,
      y: canvasPoint.y / perspectiveY + bounds.y,
    );
  }

  AonwPoint hexCenter(MapHexCoordinate coordinate) {
    return project(geometry.center(coordinate));
  }

  AonwPoint hexTopFaceCenter(MapHexCoordinate coordinate) {
    final center = hexCenter(coordinate);
    return (x: center.x, y: center.y + _topFaceAnchorOffsetY * perspectiveY);
  }

  AonwPoint hexCorner(MapHexCoordinate coordinate, int corner) {
    return project(geometry.corner(coordinate, corner));
  }

  MapHexCoordinate? hexAt(AonwPoint canvasPoint) {
    final coordinate = geometry.hexAt(unproject(canvasPoint));
    if (coordinate.col < 0 ||
        coordinate.col >= geometry.cols ||
        coordinate.row < 0 ||
        coordinate.row >= geometry.rows) {
      return null;
    }
    return coordinate;
  }
}
