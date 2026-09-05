part of 'flame_map_camera.dart';

extension FlameMapCameraMotion on FlameMapCameraController {
  bool get hasMotion => _motion != null;

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

  void smoothCenterOnWorld(AonwPoint point, {double duration = 0.42}) {
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
    _motion = _MapCameraMotion(start: start, target: point, duration: duration);
    if (!wasActive) _onActivityChanged?.call(true);
  }

  void cancelMotion() {
    if (_motion == null) return;
    _motion = null;
    _onActivityChanged?.call(false);
  }

  void skipMotion() {
    final target = _motion?.target;
    if (target != null) centerOnWorld(target);
  }

  void update(double dt) {
    final motion = _motion;
    final transform = _transform;
    if (motion == null || transform == null || !dt.isFinite || dt <= 0) return;
    motion.elapsed += dt;
    final progress = (motion.elapsed / motion.duration).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(progress);
    _apply(
      transform.centeredAt((
        x: motion.start.x + (motion.target.x - motion.start.x) * eased,
        y: motion.start.y + (motion.target.y - motion.start.y) * eased,
      )),
    );
    if (progress >= 1) cancelMotion();
  }
}

final class _MapCameraMotion {
  _MapCameraMotion({
    required this.start,
    required this.target,
    required this.duration,
  });

  final AonwPoint start;
  final AonwPoint target;
  final double duration;
  double elapsed = 0;
}
