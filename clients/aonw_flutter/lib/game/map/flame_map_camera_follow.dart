part of 'flame_map_camera.dart';

extension FlameMapCameraFollow on FlameMapCameraController {
  bool get isFollowing => _trackedPoint != null;

  void followWorldPoint(AonwPoint? Function() point) {
    final wasActive = hasMotion;
    _motionGeneration++;
    _motion = null;
    _trackedPoint = point;
    if (!wasActive) _onActivityChanged?.call(true);
  }

  bool _updateTrackedPoint(double dt) {
    final tracked = _trackedPoint;
    if (tracked == null) return false;
    final target = tracked();
    final transform = _transform;
    if (target == null || transform == null) {
      cancelMotion();
      return true;
    }
    final current = transform.worldCenter;
    final dx = target.x - current.x;
    final dy = target.y - current.y;
    if (dx == 0 && dy == 0) return true;
    final fraction = dx * dx + dy * dy < 0.25
        ? 1.0
        : 1 - math.pow(0.5, dt / 0.10).toDouble();
    _apply(
      transform.centeredAt((
        x: current.x + dx * fraction,
        y: current.y + dy * fraction,
      )),
    );
    return true;
  }
}
