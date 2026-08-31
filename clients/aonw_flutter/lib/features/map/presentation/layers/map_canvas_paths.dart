import 'dart:ui';

import '../../read_model/map_view.dart';
import '../geometry/odd_q_flat_top_geometry.dart';

Path aonwHexPath(
  AonwOddQFlatTopGeometry geometry,
  MapHexCoordinate coordinate,
) {
  final first = geometry.corner(coordinate, 0);
  final path = Path()..moveTo(first.x, first.y);
  for (var corner = 1; corner < 6; corner++) {
    final point = geometry.corner(coordinate, corner);
    path.lineTo(point.x, point.y);
  }
  return path..close();
}

Path aonwMapClipPath(
  MapView map,
  AonwOddQFlatTopGeometry geometry, {
  bool translateToOrigin = false,
}) {
  final bounds = geometry.bounds;
  final offset = translateToOrigin ? Offset(-bounds.x, -bounds.y) : Offset.zero;
  final path = Path();
  for (final tile in map.tiles) {
    path.addPath(aonwHexPath(geometry, tile.coordinate), offset);
  }
  return path;
}
