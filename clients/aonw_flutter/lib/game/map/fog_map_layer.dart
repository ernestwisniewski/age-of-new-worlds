import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'static_map_layers.dart';

/// Recipient-safe fog rendered between map infrastructure and interaction
/// overlays, matching the legacy Flame layer order.
final class MapFogLayerComponent extends Component with HasVisibility {
  MapFogLayerComponent() : super(priority: 27) {
    isVisible = false;
  }

  final _hiddenPaint = ui.Paint()
    ..color = MapPalette.fogHidden
    ..style = ui.PaintingStyle.fill
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.2);
  final _discoveredPaint = ui.Paint()
    ..color = MapPalette.fogDiscovered
    ..style = ui.PaintingStyle.fill
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.4);

  MapStaticRenderIdentity? _cacheIdentity;
  MapFogView? _fog;
  ui.Path? _hiddenPath;
  ui.Path? _discoveredPath;
  var _hiddenHexCount = 0;
  var _discoveredHexCount = 0;
  var _pathBuildCount = 0;

  @visibleForTesting
  int get debugHiddenHexCount => _hiddenHexCount;

  @visibleForTesting
  int get debugDiscoveredHexCount => _discoveredHexCount;

  @visibleForTesting
  int get debugPathBuildCount => _pathBuildCount;

  @visibleForTesting
  int get debugHiddenPathMetricCount =>
      _hiddenPath?.computeMetrics().length ?? 0;

  @visibleForTesting
  int get debugDiscoveredPathMetricCount =>
      _discoveredPath?.computeMetrics().length ?? 0;

  void applyFog(MapStaticRenderCache cache, MapFogView fog) {
    if (_cacheIdentity == cache.identity && _fogViewsEqual(_fog, fog)) return;
    _cacheIdentity = cache.identity;
    _fog = fog;
    if (!fog.enabled) {
      _clearPaths();
      return;
    }

    final hiddenPath = ui.Path();
    final discoveredPath = ui.Path();
    var hiddenHexCount = 0;
    var discoveredHexCount = 0;
    for (final entry in cache.tilePaths.entries) {
      switch (fog.visibilityAt(entry.key)) {
        case MapFogVisibilityView.hidden:
          hiddenPath.addPath(entry.value, ui.Offset.zero);
          hiddenHexCount += 1;
        case MapFogVisibilityView.discovered:
          discoveredPath.addPath(entry.value, ui.Offset.zero);
          discoveredHexCount += 1;
        case MapFogVisibilityView.visible:
          break;
      }
    }
    _hiddenPath = hiddenPath;
    _discoveredPath = discoveredPath;
    _hiddenHexCount = hiddenHexCount;
    _discoveredHexCount = discoveredHexCount;
    _pathBuildCount += 1;
    isVisible = hiddenHexCount > 0 || discoveredHexCount > 0;
  }

  void clearLayer() {
    _cacheIdentity = null;
    _fog = null;
    _clearPaths();
  }

  void _clearPaths() {
    _hiddenPath = null;
    _discoveredPath = null;
    _hiddenHexCount = 0;
    _discoveredHexCount = 0;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    final hiddenPath = _hiddenPath;
    if (hiddenPath != null && _hiddenHexCount > 0) {
      canvas.drawPath(hiddenPath, _hiddenPaint);
    }
    final discoveredPath = _discoveredPath;
    if (discoveredPath != null && _discoveredHexCount > 0) {
      canvas.drawPath(discoveredPath, _discoveredPaint);
    }
  }
}

bool _fogViewsEqual(MapFogView? first, MapFogView second) {
  if (identical(first, second)) return true;
  if (first == null || first.enabled != second.enabled) return false;
  return _coordinatesEqual(first.discoveredHexes, second.discoveredHexes) &&
      _coordinatesEqual(first.visibleHexes, second.visibleHexes);
}

bool _coordinatesEqual(
  List<MapHexCoordinate> first,
  List<MapHexCoordinate> second,
) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
