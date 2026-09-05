import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/camera/map_viewport_projection.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/layers/map_canvas_paths.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_reference_bundle.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/map_view_mode.dart';
import 'map_canvas_clip.dart';

part 'map_terrain_regions.dart';

typedef MapStaticRenderIdentity = ({
  String mapId,
  String contentHash,
  int cols,
  int rows,
});

typedef MapElevationWallPaths = ({ui.Path right, ui.Path bottom, ui.Path left});

final class MapStaticRenderCache {
  MapStaticRenderCache._({
    required this.identity,
    required this.geometry,
    required this.projection,
    required this.tilePaths,
    required this.elevationWallPaths,
    required this.terrainPaths,
    required this.terrainRegions,
    required this.gridPath,
    required this.clipPath,
    required this.size,
  });

  factory MapStaticRenderCache.build(MapView map) {
    final geometry = AonwOddQFlatTopGeometry(
      cols: map.cols,
      rows: map.rows,
      radius: aonwMapHexRadius,
    );
    final bounds = geometry.bounds;
    final projection = MapViewportProjection(geometry);
    final terrainPaths = <MapTerrain, ui.Path>{};
    final tilePaths = <MapHexCoordinate, ui.Path>{};
    final elevationWallPaths = _buildElevationWallPaths(map, projection);
    final gridPath = ui.Path();
    for (final tile in map.tiles) {
      final hex = aonwProjectedHexPath(projection, tile.coordinate);
      tilePaths[tile.coordinate] = hex;
      terrainPaths
          .putIfAbsent(tile.displayTerrain, ui.Path.new)
          .addPath(hex, ui.Offset.zero);
      gridPath.addPath(hex, ui.Offset.zero);
    }
    return MapStaticRenderCache._(
      identity: (
        mapId: map.mapId,
        contentHash: map.contentHash,
        cols: map.cols,
        rows: map.rows,
      ),
      geometry: geometry,
      projection: projection,
      tilePaths: Map.unmodifiable(tilePaths),
      elevationWallPaths: elevationWallPaths,
      terrainPaths: Map.unmodifiable(terrainPaths),
      terrainRegions: _buildTerrainRegions(map, tilePaths),
      gridPath: gridPath,
      clipPath: aonwProjectedMapClipPath(map, projection),
      size: ui.Size(
        bounds.width,
        bounds.height * MapViewportProjection.perspectiveY,
      ),
    );
  }

  final MapStaticRenderIdentity identity;
  final AonwOddQFlatTopGeometry geometry;
  final MapViewportProjection projection;
  final Map<MapHexCoordinate, ui.Path> tilePaths;
  final MapElevationWallPaths elevationWallPaths;
  final Map<MapTerrain, ui.Path> terrainPaths;
  final List<MapTerrainRegion> terrainRegions;
  final ui.Path gridPath;
  final ui.Path clipPath;
  final ui.Size size;
}

final class MapTerrainLayerComponent extends Component with HasVisibility {
  MapTerrainLayerComponent() : super(priority: 0) {
    isVisible = false;
  }

  final _paints = <MapTerrain, ui.Paint>{
    for (final terrain in MapTerrain.values)
      terrain: ui.Paint()..color = MapPalette.terrain(terrain),
  };
  final _elevationWallRightPaint = ui.Paint()
    ..color = MapPalette.elevationWallRight;
  final _elevationWallBottomPaint = ui.Paint()
    ..color = MapPalette.elevationWallBottom;
  final _elevationWallLeftPaint = ui.Paint()
    ..color = MapPalette.elevationWallLeft;
  MapStaticRenderCache? _cache;
  var _cacheUpdateCount = 0;
  var _elevationWallsVisible = false;
  var _viewMode = MapViewMode.graphic;
  var _renderedRegionCount = 0;

  @visibleForTesting
  int get debugRenderedRegionCount => _renderedRegionCount;

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _cache?.identity;

  @visibleForTesting
  bool get debugElevationWallsVisible => _elevationWallsVisible;

  @visibleForTesting
  MapViewMode get debugViewMode => _viewMode;

  bool setWalls(bool visible) {
    if (_elevationWallsVisible == visible) return false;
    _elevationWallsVisible = visible;
    return true;
  }

  bool setViewMode(MapViewMode mode) {
    if (_viewMode == mode) return false;
    _viewMode = mode;
    _updateVisibility();
    return true;
  }

  void applyCache(MapStaticRenderCache cache) {
    if (_cache?.identity == cache.identity) return;
    _cache = cache;
    _cacheUpdateCount += 1;
    _updateVisibility();
  }

  void clearCache() {
    _cache = null;
    isVisible = false;
  }

  void _updateVisibility() {
    isVisible = _cache != null && _viewMode.showsTerrain;
  }

  @override
  void render(ui.Canvas canvas) {
    _renderedRegionCount = 0;
    final cache = _cache;
    if (cache == null) return;
    if (_elevationWallsVisible) {
      canvas.drawPath(cache.elevationWallPaths.right, _elevationWallRightPaint);
      canvas.drawPath(
        cache.elevationWallPaths.bottom,
        _elevationWallBottomPaint,
      );
      canvas.drawPath(cache.elevationWallPaths.left, _elevationWallLeftPaint);
    }
    final clip = mapCanvasClipBounds(canvas);
    for (final region in cache.terrainRegions) {
      if (!region.bounds.overlaps(clip)) continue;
      canvas.save();
      canvas.clipRect(region.clip, doAntiAlias: false);
      for (final terrain in cache.terrainPaths.keys) {
        final path = region.paths[terrain];
        if (path != null) canvas.drawPath(path, _paints[terrain]!);
      }
      canvas.restore();
      _renderedRegionCount++;
    }
  }
}

final class MapReferenceLayerComponent extends Component
    with HasGameReference<FlameGame>, HasVisibility {
  MapReferenceLayerComponent() : super(priority: 10) {
    isVisible = false;
  }

  final _paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  MapStaticRenderCache? _cache;
  MapReferenceBundle? _reference;
  List<_DecodedReferencePage> _pages = const [];
  final _imageKeys = <String>[];
  var _loadGeneration = 0;
  var _cacheUpdateCount = 0;
  var _visibilityUpdateCount = 0;
  var _referenceVisible = true;

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  int get debugVisibilityUpdateCount => _visibilityUpdateCount;

  @visibleForTesting
  int get debugDecodedPageCount => _pages.length;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _cache?.identity;

  void applyReference({
    required MapStaticRenderCache cache,
    required MapReferenceBundle reference,
    required bool visible,
  }) {
    final identityChanged = _cache?.identity != cache.identity;
    if (identityChanged) {
      _clearDecodedPages();
      _cache = cache;
      _reference = reference;
      _cacheUpdateCount += 1;
      if (isLoaded) unawaited(_loadPages());
    }
    if (_referenceVisible != visible || identityChanged) {
      _referenceVisible = visible;
      _visibilityUpdateCount += 1;
      isVisible = visible;
      _refreshGameWidget();
    }
  }

  void clearCache() {
    _clearDecodedPages();
    _cache = null;
    _reference = null;
    isVisible = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadPages();
  }

  @override
  void render(ui.Canvas canvas) {
    final cache = _cache;
    if (cache == null || _pages.isEmpty) return;
    canvas.save();
    canvas.clipPath(cache.clipPath);
    for (final page in _pages) {
      canvas.drawImageRect(page.image, page.source, page.destination, _paint);
    }
    canvas.restore();
  }

  @override
  void onRemove() {
    clearCache();
    super.onRemove();
  }

  Future<void> _loadPages() async {
    final reference = _reference;
    if (reference == null || reference.pages.isEmpty) {
      _pages = const [];
      return;
    }
    final generation = ++_loadGeneration;
    final decoded = <_DecodedReferencePage>[];
    for (final page in reference.pages) {
      final key =
          'map-reference/${reference.mapId}/${reference.mapContentHash}/${page.file}';
      if (!_imageKeys.contains(key)) _imageKeys.add(key);
      final image = await game.images.fetchOrGenerate(
        key,
        () => _decodeImage(page.bytes),
      );
      if (generation != _loadGeneration) return;
      decoded.add((
        image: image,
        source: ui.Rect.fromLTWH(
          0,
          0,
          page.pixelWidth.toDouble(),
          page.pixelHeight.toDouble(),
        ),
        destination: ui.Rect.fromLTWH(
          page.destination.x,
          page.destination.y * MapViewportProjection.perspectiveY,
          page.destination.width,
          page.destination.height * MapViewportProjection.perspectiveY,
        ),
      ));
    }
    if (generation != _loadGeneration) return;
    _pages = List.unmodifiable(decoded);
    _refreshGameWidget();
  }

  void _clearDecodedPages() {
    _loadGeneration += 1;
    _pages = const [];
    if (isLoaded) {
      for (final key in _imageKeys) {
        game.images.clear(key);
      }
    }
    _imageKeys.clear();
  }

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}

final class MapGridLayerComponent extends Component with HasVisibility {
  MapGridLayerComponent() : super(priority: 20) {
    isVisible = false;
  }

  final _paint = ui.Paint()
    ..color = MapPalette.grid
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.2;
  MapStaticRenderCache? _cache;
  var _cacheUpdateCount = 0;
  var _gridVisible = false;

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  bool get debugGridVisible => _gridVisible;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _cache?.identity;

  bool setGridVisible(bool visible) {
    if (_gridVisible == visible) return false;
    _gridVisible = visible;
    _updateVisibility();
    return true;
  }

  void applyCache(MapStaticRenderCache cache) {
    if (_cache?.identity == cache.identity) return;
    _cache = cache;
    _cacheUpdateCount += 1;
    _updateVisibility();
  }

  void clearCache() {
    _cache = null;
    isVisible = false;
  }

  void _updateVisibility() {
    isVisible = _cache != null && _gridVisible;
  }

  @override
  void render(ui.Canvas canvas) {
    final cache = _cache;
    if (cache == null) return;
    canvas.drawPath(cache.gridPath, _paint);
  }
}

typedef _DecodedReferencePage = ({
  ui.Image image,
  ui.Rect source,
  ui.Rect destination,
});

Future<ui.Image> _decodeImage(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

MapElevationWallPaths _buildElevationWallPaths(
  MapView map,
  MapViewportProjection projection,
) {
  final paths = (right: ui.Path(), bottom: ui.Path(), left: ui.Path());
  final heights = {for (final tile in map.tiles) tile.coordinate: tile.height};
  for (final tile in map.tiles) {
    final coordinate = tile.coordinate;
    final bottomRight = coordinate.col.isOdd
        ? (col: coordinate.col + 1, row: coordinate.row + 1)
        : (col: coordinate.col + 1, row: coordinate.row);
    final bottom = (col: coordinate.col, row: coordinate.row + 1);
    final bottomLeft = coordinate.col.isOdd
        ? (col: coordinate.col - 1, row: coordinate.row + 1)
        : (col: coordinate.col - 1, row: coordinate.row);
    final corners = [
      for (var corner = 0; corner < 4; corner += 1)
        projection.hexCorner(coordinate, corner),
    ];
    _addElevationWall(
      paths.right,
      from: corners[0],
      to: corners[1],
      heightDelta: tile.height - (heights[bottomRight] ?? 0),
    );
    _addElevationWall(
      paths.bottom,
      from: corners[1],
      to: corners[2],
      heightDelta: tile.height - (heights[bottom] ?? 0),
    );
    _addElevationWall(
      paths.left,
      from: corners[2],
      to: corners[3],
      heightDelta: tile.height - (heights[bottomLeft] ?? 0),
    );
  }
  return paths;
}

void _addElevationWall(
  ui.Path target, {
  required AonwPoint from,
  required AonwPoint to,
  required int heightDelta,
}) {
  if (heightDelta <= 0) return;
  final depth = (3 + heightDelta * 2) * MapViewportProjection.perspectiveY;
  target
    ..moveTo(from.x, from.y)
    ..lineTo(to.x, to.y)
    ..lineTo(to.x, to.y + depth)
    ..lineTo(from.x, from.y + depth)
    ..close();
}
