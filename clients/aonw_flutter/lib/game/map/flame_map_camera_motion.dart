part of 'flame_map_camera.dart';

extension FlameMapCameraMotion on FlameMapCameraController {
  bool get hasMotion => _motion != null || _trackedPoint != null;
  int get motionGeneration => _motionGeneration;

  void setMotionEnabled(bool enabled) {
    if (_motionEnabled == enabled) return;
    _motionEnabled = enabled;
    if (!enabled) cancelMotion();
  }

  void centerOnWorld(AonwPoint point) {
    cancelMotion();
    final transform = _transform;
    if (transform == null) {
      _pendingWorldCenter = point;
      return;
    }
    _pendingWorldCenter = null;
    _apply(transform.centeredAt(point));
  }

  void smoothCenterOnWorld(
    AonwPoint point, {
    double duration = 0.42,
    Curve curve = Curves.easeInOutCubic,
  }) {
    final transform = _transform;
    if (!_motionEnabled || transform == null || duration <= 0) {
      centerOnWorld(point);
      return;
    }
    final start = transform.worldCenter;
    final dx = start.x - point.x;
    final dy = start.y - point.y;
    if (dx * dx + dy * dy < 0.000001) {
      cancelMotion();
      return;
    }
    final wasActive = hasMotion;
    _motionGeneration++;
    _trackedPoint = null;
    _motion = _MapCameraMotion(
      start: start,
      target: point,
      duration: duration,
      curve: curve,
    );
    if (!wasActive) _onActivityChanged?.call(true);
  }

  void cancelMotion() {
    final wasActive = hasMotion;
    _motionGeneration++;
    _motion = null;
    _trackedPoint = null;
    if (wasActive) _onActivityChanged?.call(false);
  }

  void skipMotion() {
    final target = _motion?.target ?? _trackedPoint?.call();
    if (target != null) centerOnWorld(target);
    if (target == null) cancelMotion();
  }

  void update(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    if (_updateTrackedPoint(dt)) return;
    final motion = _motion;
    final transform = _transform;
    if (motion == null || transform == null) return;
    motion.elapsed += dt;
    final progress = (motion.elapsed / motion.duration).clamp(0.0, 1.0);
    final eased = motion.curve.transform(progress);
    _apply(
      transform.centeredAt((
        x: motion.start.x + (motion.target.x - motion.start.x) * eased,
        y: motion.start.y + (motion.target.y - motion.start.y) * eased,
      )),
    );
    if (progress >= 1) {
      _motion = null;
      _onActivityChanged?.call(false);
    }
  }
}

final class _MapCameraMotion {
  _MapCameraMotion({
    required this.start,
    required this.target,
    required this.duration,
    required this.curve,
  });

  final AonwPoint start;
  final AonwPoint target;
  final double duration;
  final Curve curve;
  double elapsed = 0;
}
