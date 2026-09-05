part of 'flame_map_camera.dart';

extension FlameMapCameraProjection on FlameMapCameraController {
  /// Flame clips the world to this viewport before cinematic projection.
  Rect get visibleWorldBounds {
    final transform = _transform;
    if (transform == null) return Rect.zero;
    final width = transform.viewport.width / transform.zoom;
    final height = transform.viewport.height / transform.zoom;
    return Rect.fromLTWH(
      transform.worldCenter.x - width / 2,
      transform.worldCenter.y - height / 2,
      width,
      height,
    );
  }

  Rect get cinematicClipBounds => _cinematicProjection.clipBounds;

  bool get cinematicEnabled => _cinematicEnabled;

  Float64List? get cinematicMatrix =>
      _cinematicEnabled ? _cinematicProjection.matrix : null;

  bool setCinematicEnabled(bool enabled) {
    if (_cinematicEnabled == enabled) return false;
    _cinematicEnabled = enabled;
    return true;
  }

  AonwPoint projectScreenPoint(AonwPoint point) =>
      _cinematicEnabled ? _cinematicProjection.project(point) : point;

  AonwPoint _unprojectScreenPoint(AonwPoint point) =>
      _cinematicEnabled ? _cinematicProjection.unproject(point) : point;
}
