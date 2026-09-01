import 'dart:ui' as ui;

import '../../features/map/read_model/map_view.dart';
import 'static_map_layers.dart';

List<ui.Offset> mapProjectedTopFaceCorners(
  MapStaticRenderCache cache,
  MapHexCoordinate coordinate, {
  double scale = 1,
}) {
  final projectedCenter = cache.projection.hexCenter(coordinate);
  final topFaceCenter = cache.projection.hexTopFaceCenter(coordinate);
  return List.generate(6, (index) {
    final corner = cache.projection.hexCorner(coordinate, index);
    return ui.Offset(
      topFaceCenter.x + (corner.x - projectedCenter.x) * scale,
      topFaceCenter.y + (corner.y - projectedCenter.y) * scale,
    );
  }, growable: false);
}

ui.Offset mapProjectedTopFaceCenter(
  MapStaticRenderCache cache,
  MapHexCoordinate coordinate,
) {
  final center = cache.projection.hexTopFaceCenter(coordinate);
  return ui.Offset(center.x, center.y);
}

ui.Path mapPathFromCorners(List<ui.Offset> corners) {
  final path = ui.Path();
  if (corners.isEmpty) return path;
  path.moveTo(corners.first.dx, corners.first.dy);
  for (final corner in corners.skip(1)) {
    path.lineTo(corner.dx, corner.dy);
  }
  return path..close();
}

ui.Path mapProjectedTopFacePath(
  MapStaticRenderCache cache,
  MapHexCoordinate coordinate, {
  double scale = 1,
}) => mapPathFromCorners(
  mapProjectedTopFaceCorners(cache, coordinate, scale: scale),
);
