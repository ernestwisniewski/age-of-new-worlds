import 'dart:math' as math;

const int mapPageSize = 2048;
const int mapPageGutter = 2;
const int mapPageCoreSize = mapPageSize - mapPageGutter * 2;
const int mapAtlasMaxPixels = 16000000;
const double mapHexRadius = 60;

double mapWorldWidth(int columns) =>
    mapHexRadius * 2 + (columns - 1) * 1.5 * mapHexRadius;

double mapWorldHeight(int columns, int rows) {
  final halfHeight = math.sqrt(3) / 2 * mapHexRadius;
  return halfHeight +
      (rows - 1) * math.sqrt(3) * mapHexRadius +
      (columns > 1 ? halfHeight : 0) +
      halfHeight;
}

double mapCompilationScale(double worldWidth, double worldHeight) {
  final preferredPixels = worldWidth * worldHeight * 4;
  if (preferredPixels <= mapAtlasMaxPixels) return 2;
  return math
      .sqrt(mapAtlasMaxPixels / (worldWidth * worldHeight))
      .clamp(1.0, 2.0)
      .toDouble();
}

MapTilePixelPlacement mapTilePlacement(int column, int row, double scale) {
  final sqrt3 = math.sqrt(3);
  final tileHeight = sqrt3 * mapHexRadius;
  final centerX = mapHexRadius + column * 1.5 * mapHexRadius;
  final centerY =
      sqrt3 / 2 * mapHexRadius +
      row * sqrt3 * mapHexRadius +
      (column.isOdd ? sqrt3 / 2 * mapHexRadius : 0);
  final exactLeft = (centerX - mapHexRadius) * scale;
  final exactTop = (centerY - tileHeight / 2) * scale;
  final exactWidth = mapHexRadius * 2 * scale;
  final exactHeight = tileHeight * scale;
  final rasterLeft = exactLeft.floor();
  final rasterTop = exactTop.floor();
  final rasterRight = (exactLeft + exactWidth).ceil();
  final rasterBottom = (exactTop + exactHeight).ceil();
  return MapTilePixelPlacement(
    rasterLeft: rasterLeft,
    rasterTop: rasterTop,
    rasterWidth: math.max(1, rasterRight - rasterLeft),
    rasterHeight: math.max(1, rasterBottom - rasterTop),
    exactLeft: exactLeft,
    exactTop: exactTop,
    exactWidth: exactWidth,
    exactHeight: exactHeight,
  );
}

bool unitHexContains(double horizontal, double vertical) {
  final left = vertical <= 0.5 ? 0.25 - 0.5 * vertical : 0.5 * vertical - 0.25;
  final right = vertical <= 0.5 ? 0.75 + 0.5 * vertical : 1.25 - 0.5 * vertical;
  return horizontal >= left && horizontal <= right;
}

final class MapTilePixelPlacement {
  const MapTilePixelPlacement({
    required this.rasterLeft,
    required this.rasterTop,
    required this.rasterWidth,
    required this.rasterHeight,
    required this.exactLeft,
    required this.exactTop,
    required this.exactWidth,
    required this.exactHeight,
  });

  final int rasterLeft;
  final int rasterTop;
  final int rasterWidth;
  final int rasterHeight;
  final double exactLeft;
  final double exactTop;
  final double exactWidth;
  final double exactHeight;
}
