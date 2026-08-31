import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/camera/map_camera_transform.dart';
import '../../features/map/presentation/camera/map_viewport_projection.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/input/map_viewport_intent.dart';
import '../../features/map/read_model/map_view.dart';
import 'static_map_layers.dart';

final class FlameMapCameraController {
  FlameMapCameraController(this._camera);

  final CameraComponent _camera;
  MapStaticRenderCache? _cache;
  MapCameraTransform? _transform;
  Vector2 _viewport = Vector2.zero();
  double _authoredZoom = 1;
  var _transformUpdateCount = 0;

  @visibleForTesting
  MapCameraTransform? get debugTransform => _transform;

  @visibleForTesting
  int get debugTransformUpdateCount => _transformUpdateCount;

  void replaceMap({
    required MapStaticRenderCache cache,
    required double authoredZoom,
  }) {
    if (_cache?.identity == cache.identity) return;
    _cache = cache;
    _authoredZoom = authoredZoom;
    _transform = null;
    _camera.setBounds(
      Rectangle.fromLTWH(0, 0, cache.size.width, cache.size.height),
    );
    _initializeIfReady();
  }

  void clear() {
    _cache = null;
    _transform = null;
    _camera.setBounds(null);
  }

  void resize(Vector2 viewport) {
    if (viewport.x <= 0 || viewport.y <= 0) return;
    if (_viewport.x == viewport.x && _viewport.y == viewport.y) return;
    _viewport = viewport.clone();
    final transform = _transform;
    if (transform == null) {
      _initializeIfReady();
    } else {
      _apply(transform.resized((width: viewport.x, height: viewport.y)));
    }
  }

  MapHexCoordinate? hexAtScreen(AonwPoint screenPoint) {
    final cache = _cache;
    final transform = _transform;
    if (cache == null || transform == null) return null;
    return MapViewportProjection(
      cache.geometry,
    ).hexAt(transform.screenToWorld(screenPoint));
  }

  AonwPoint? screenForHex(MapHexCoordinate coordinate) {
    final cache = _cache;
    final transform = _transform;
    if (cache == null || transform == null) return null;
    final world = MapViewportProjection(cache.geometry).hexCenter(coordinate);
    return transform.worldToScreen(world);
  }

  bool applyIntent(MapViewportIntent intent) {
    final transform = _transform;
    if (transform == null) return false;
    switch (intent) {
      case MapPanIntent(:final screenDelta):
        _apply(transform.panByScreen(screenDelta));
        return true;
      case MapZoomIntent(:final focalPoint, :final factor):
        _apply(transform.zoomAtScreen(focalPoint: focalPoint, factor: factor));
        return true;
      case MapViewportFrameIntent(
        :final screenPanDelta,
        :final zoomFocalPoint,
        :final zoomFactor,
      ):
        return _applyFrameIntent(
          transform,
          screenPanDelta: screenPanDelta,
          zoomFocalPoint: zoomFocalPoint,
          zoomFactor: zoomFactor,
        );
      case MapHoverIntent() || MapSelectIntent():
        return false;
    }
  }

  bool _applyFrameIntent(
    MapCameraTransform transform, {
    required AonwPoint screenPanDelta,
    required AonwPoint? zoomFocalPoint,
    required double zoomFactor,
  }) {
    var next = transform;
    if (screenPanDelta.x != 0 || screenPanDelta.y != 0) {
      next = next.panByScreen(screenPanDelta);
    }
    if (zoomFocalPoint != null && zoomFactor != 1) {
      next = next.zoomAtScreen(focalPoint: zoomFocalPoint, factor: zoomFactor);
    }
    if (identical(next, transform)) return false;
    _apply(next);
    return true;
  }

  void _initializeIfReady() {
    final cache = _cache;
    if (cache == null || _viewport.x <= 0 || _viewport.y <= 0) return;
    _apply(
      MapCameraTransform.fitted(
        viewport: (width: _viewport.x, height: _viewport.y),
        content: (width: cache.size.width, height: cache.size.height),
        authoredZoom: _authoredZoom,
      ),
    );
  }

  void _apply(MapCameraTransform transform) {
    _transform = transform;
    _transformUpdateCount += 1;
    _camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(transform.worldCenter.x, transform.worldCenter.y)
      ..zoom = transform.zoom;
  }
}
