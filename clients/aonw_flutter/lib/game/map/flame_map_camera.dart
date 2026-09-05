import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/camera/map_camera_transform.dart';
import '../../features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import '../../features/map/presentation/input/map_viewport_intent.dart';
import '../../features/map/presentation/map_render_snapshot.dart';
import '../../features/map/read_model/map_view.dart';
import 'static_map_layers.dart';

part 'flame_map_camera_motion.dart';

MapHexCoordinate? initialMapFocus(MapRenderSnapshot snapshot) {
  final actorPlayerId = snapshot.player.actorPlayerId;
  for (final unit in snapshot.player.units) {
    if (unit.ownerPlayerId == actorPlayerId) return unit.coordinate;
  }
  for (final city in snapshot.player.cities) {
    if (city.ownerPlayerId == actorPlayerId) return city.center;
  }
  return null;
}

final class FlameMapCameraController {
  FlameMapCameraController(
    this._camera, {
    void Function(double)? onZoomChanged,
    void Function(MapCameraTransform)? onTransformChanged,
    void Function(bool)? onActivityChanged,
  }) : _onZoomChanged = onZoomChanged,
       _onTransformChanged = onTransformChanged,
       _onActivityChanged = onActivityChanged;

  final CameraComponent _camera;
  final void Function(double)? _onZoomChanged;
  final void Function(MapCameraTransform)? _onTransformChanged;
  final void Function(bool)? _onActivityChanged;
  _MapCameraMotion? _motion;
  bool _motionEnabled = true;
  MapStaticRenderCache? _cache;
  MapCameraTransform? _transform;
  Vector2 _viewport = Vector2.zero();
  AonwPoint? _pendingWorldCenter;
  double _authoredZoom = 1;
  var _transformUpdateCount = 0;

  @visibleForTesting
  MapCameraTransform? get debugTransform => _transform;

  @visibleForTesting
  int get debugTransformUpdateCount => _transformUpdateCount;

  double get zoom => _transform?.zoom ?? 1;

  AonwPoint? get viewportCenter {
    final transform = _transform;
    if (transform == null) return null;
    return (x: transform.viewport.width / 2, y: transform.viewport.height / 2);
  }

  bool replaceMap({
    required MapStaticRenderCache cache,
    required double authoredZoom,
  }) {
    if (_cache?.identity == cache.identity) return false;
    cancelMotion();
    _cache = cache;
    _authoredZoom = authoredZoom;
    _transform = null;
    _pendingWorldCenter = null;
    _camera.setBounds(null);
    _initializeIfReady();
    return true;
  }

  void clear() {
    cancelMotion();
    _cache = null;
    _transform = null;
    _pendingWorldCenter = null;
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
    return cache.projection.hexAt(transform.screenToWorld(screenPoint));
  }

  AonwPoint? worldAtScreen(AonwPoint screenPoint) =>
      _transform?.screenToWorld(screenPoint);

  AonwPoint? screenForHex(MapHexCoordinate coordinate) {
    final cache = _cache;
    final transform = _transform;
    if (cache == null || transform == null) return null;
    final world = cache.projection.hexCenter(coordinate);
    return transform.worldToScreen(world);
  }

  void centerOnHex(MapHexCoordinate coordinate) {
    final cache = _cache;
    if (cache == null) return;
    centerOnWorld(cache.projection.hexCenter(coordinate));
  }

  bool applyIntent(MapViewportIntent intent) {
    final transform = _transform;
    if (transform == null) return false;
    switch (intent) {
      case MapPanIntent(:final screenDelta):
        return _applyFrameIntent(
          transform,
          screenPanDelta: screenDelta,
          zoomFocalPoint: null,
          zoomFactor: 1,
        );
      case MapZoomIntent(:final focalPoint, :final factor):
        return _applyFrameIntent(
          transform,
          screenPanDelta: (x: 0, y: 0),
          zoomFocalPoint: focalPoint,
          zoomFactor: factor,
        );
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
      case MapHoverIntent() || MapHoverExitIntent() || MapSelectIntent():
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
    if (zoomFocalPoint != null && _validZoomFactor(zoomFactor)) {
      next = next.zoomAtScreen(focalPoint: zoomFocalPoint, factor: zoomFactor);
    }
    if (identical(next, transform)) return false;
    cancelMotion();
    _apply(next);
    return true;
  }

  void _initializeIfReady() {
    final cache = _cache;
    if (cache == null || _viewport.x <= 0 || _viewport.y <= 0) return;
    _apply(
      MapCameraTransform.initial(
        viewport: (width: _viewport.x, height: _viewport.y),
        content: (width: cache.size.width, height: cache.size.height),
        authoredZoom: _authoredZoom,
        worldCenter: _pendingWorldCenter,
      ),
    );
    _pendingWorldCenter = null;
  }

  void _apply(MapCameraTransform transform) {
    _transform = transform;
    _transformUpdateCount += 1;
    _onZoomChanged?.call(transform.zoom);
    _camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(transform.worldCenter.x, transform.worldCenter.y)
      ..zoom = transform.zoom;
    _onTransformChanged?.call(transform);
  }
}

bool _validZoomFactor(double factor) =>
    factor.isFinite && factor > 0 && factor != 1;
