part of 'static_map_layers.dart';

final class MapTerrainRegion {
  MapTerrainRegion(this.clip, Map<MapTerrain, ui.Path> paths)
    : paths = Map.unmodifiable(paths),
      bounds = clip.intersect(
        paths.values
            .map((path) => path.getBounds())
            .reduce((left, right) => left.expandToInclude(right))
            .inflate(5),
      );

  final Map<MapTerrain, ui.Path> paths;
  final ui.Rect bounds;
  final ui.Rect clip;
}

List<MapTerrainRegion> _buildTerrainRegions(
  MapView map,
  Map<MapHexCoordinate, ui.Path> tilePaths,
) {
  const span = 512.0;
  final regions = <(int, int), Map<MapTerrain, ui.Path>>{};
  for (final tile in map.tiles) {
    final path = tilePaths[tile.coordinate]!;
    // Retain complete neighboring hexes for antialiasing at the minimum zoom.
    final bounds = path.getBounds().inflate(5);
    for (
      var x = (bounds.left / span).floor();
      x <= (bounds.right / span).floor();
      x++
    ) {
      for (
        var y = (bounds.top / span).floor();
        y <= (bounds.bottom / span).floor();
        y++
      ) {
        final region = regions[(x, y)] ??= {};
        (region[tile.displayTerrain] ??= ui.Path()).addPath(
          path,
          ui.Offset.zero,
        );
      }
    }
  }
  return List.unmodifiable([
    for (final entry in regions.entries)
      MapTerrainRegion(
        ui.Rect.fromLTWH(entry.key.$1 * span, entry.key.$2 * span, span, span),
        entry.value,
      ),
  ]);
}
