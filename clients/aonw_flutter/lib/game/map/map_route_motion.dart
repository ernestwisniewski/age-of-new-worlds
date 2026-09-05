part of 'map_route_layer.dart';

extension MapRouteMotion on MapRouteLayerComponent {
  void setAnimations(bool enabled) {
    if (_animationsEnabled == enabled) return;
    _animationsEnabled = enabled;
    _applyAnimationPolicy();
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _reducedMotion = enabled;
    _applyAnimationPolicy();
  }

  void setViewportActive(bool active) {
    if (_viewportActive == active) return;
    _viewportActive = active;
    _refreshActivity();
  }

  void applyViewport(ui.Rect bounds) {
    if (_viewport == bounds) return;
    _viewport = bounds;
    _refreshActivity();
  }

  void _applyAnimationPolicy() {
    if (!_animationsEnabled || _reducedMotion) {
      _flowPhase = 0;
      _resetGhost();
    }
    _refreshActivity();
    onFrameRequested?.call();
  }

  void _refreshActivity() {
    final active =
        _viewportActive &&
        _animationsEnabled &&
        !_reducedMotion &&
        _length > 0 &&
        _bounds.overlaps(_viewport);
    if (_active == active) return;
    _active = active;
    onActivityChanged?.call(active);
  }

  void _setGhostKind(VisibleUnitKind? kind) {
    if (_ghostKind == kind) return;
    _ghost?.dispose();
    _ghostKind = kind;
    _ghost = kind == null
        ? null
        : MapUnitSpriteAnimation(
            kind: kind,
            onLoaded: () => onFrameRequested?.call(),
          );
    final ghost = _ghost;
    if (ghost != null) unawaited(ghost.load());
    _advanceGhost(0);
  }

  void _resetGhost() {
    _ghost?.playIdle();
    _advanceGhost(0);
  }

  void _advanceGhost(double dt) {
    final ghost = _ghost;
    final sample = _routeSample();
    if (ghost == null || sample == null) return;
    ghost.playWalkToward(ui.Offset.zero, sample.vector);
    ghost.advance(dt);
  }

  ui.Tangent? _routeSample() {
    if (_length < 8) return null;
    var distance = (_flowPhase * 0.82) % _length;
    for (final segment in _segments) {
      for (final metric in segment.stroke.metrics) {
        if (distance <= metric.length) {
          return metric.getTangentForOffset(distance);
        }
        distance -= metric.length;
      }
    }
    return null;
  }
}
