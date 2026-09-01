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

typedef MapStaticRenderIdentity = ({
  String mapId,
  String contentHash,
  int cols,
  int rows,
});

final class MapStaticRenderCache {
  MapStaticRenderCache._({
    required this.identity,
    required this.geometry,
    required this.projection,
    required this.tilePaths,
    required this.terrainPaths,
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
      terrainPaths: Map.unmodifiable(terrainPaths),
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
  final Map<MapTerrain, ui.Path> terrainPaths;
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
  MapStaticRenderCache? _cache;
  var _cacheUpdateCount = 0;

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _cache?.identity;

  void applyCache(MapStaticRenderCache cache) {
    if (_cache?.identity == cache.identity) return;
    _cache = cache;
    _cacheUpdateCount += 1;
    isVisible = true;
  }

  void clearCache() {
    _cache = null;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final cache = _cache;
    if (cache == null) return;
    for (final entry in cache.terrainPaths.entries) {
      canvas.drawPath(entry.value, _paints[entry.key]!);
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

  @visibleForTesting
  int get debugCacheUpdateCount => _cacheUpdateCount;

  @visibleForTesting
  MapStaticRenderIdentity? get debugIdentity => _cache?.identity;

  void applyCache(MapStaticRenderCache cache) {
    if (_cache?.identity == cache.identity) return;
    _cache = cache;
    _cacheUpdateCount += 1;
    isVisible = true;
  }

  void clearCache() {
    _cache = null;
    isVisible = false;
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
