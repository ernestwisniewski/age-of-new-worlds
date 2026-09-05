part of 'unit_map_layer.dart';

extension MapUnitAnimations on MapUnitLayerComponent {
  @visibleForTesting
  bool get debugAnimationScheduled => _frameClock.scheduled;

  @visibleForTesting
  int get debugAnimationTicks => _frameClock.ticks;

  @visibleForTesting
  int get debugAnimationUnitCount => _frameClock.participantCount;

  void setIdleAnimations(bool enabled) {
    if (_idleEnabled == enabled) return;
    _frameClock.flush();
    _idleEnabled = enabled;
    _synchronizeAnimations();
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _frameClock.flush();
    _reducedMotion = enabled;
    _synchronizeAnimations();
  }

  void setViewportActive(bool active) {
    if (_viewportActive == active) return;
    _frameClock.flush();
    _viewportActive = active;
    _synchronizeAnimations();
  }

  void applyAnimationViewport({required ui.Rect bounds, required double zoom}) {
    if (_animationViewport == bounds && _animationZoom == zoom) return;
    _frameClock.flush();
    _animationViewport = bounds;
    _animationZoom = zoom;
    _synchronizeAnimations();
  }

  void _synchronizeAnimations() {
    if (_applyingPatch) return;
    _frameClock.synchronize(
      _viewportActive && !_reducedMotion
          ? _unitsById.values.where(
              (unit) =>
                  unit._canAnimateStationary &&
                  (unit._sprite.action == MapUnitSpriteAction.work ||
                      (_idleEnabled && _animationZoom >= 0.85)) &&
                  _animationViewport.overlaps(unit._worldBounds),
            )
          : const [],
    );
  }
}
