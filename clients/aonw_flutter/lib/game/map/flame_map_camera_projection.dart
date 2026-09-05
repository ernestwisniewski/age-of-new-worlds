part of 'flame_map_camera.dart';

extension FlameMapCameraProjection on FlameMapCameraController {
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
