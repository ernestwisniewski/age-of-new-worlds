part of 'unit_map_layer.dart';

extension MapUnitIdleAnimations on MapUnitLayerComponent {
  @visibleForTesting
  bool get debugIdleScheduled => _idleClock.scheduled;

  @visibleForTesting
  int get debugIdleTicks => _idleClock.ticks;

  @visibleForTesting
  int get debugIdleUnitCount => _idleClock.participantCount;

  void setIdleAnimations(bool enabled) {
    if (_idleEnabled == enabled) return;
    _idleClock.flush();
    _idleEnabled = enabled;
    _synchronizeIdle();
  }

  void setReducedMotion(bool enabled) {
    if (_reducedMotion == enabled) return;
    _idleClock.flush();
    _reducedMotion = enabled;
    _synchronizeIdle();
  }

  void setViewportActive(bool active) {
    if (_viewportActive == active) return;
    _idleClock.flush();
    _viewportActive = active;
    _synchronizeIdle();
  }

  void applyIdleViewport({required ui.Rect bounds, required double zoom}) {
    if (_idleViewport == bounds && _idleZoom == zoom) return;
    _idleClock.flush();
    _idleViewport = bounds;
    _idleZoom = zoom;
    _synchronizeIdle();
  }

  void _synchronizeIdle() {
    if (_applyingPatch) return;
    _idleClock.synchronize(
      _viewportActive && _idleEnabled && !_reducedMotion && _idleZoom >= 0.85
          ? _unitsById.values.where(
              (unit) =>
                  unit._canAnimateIdle &&
                  _idleViewport.overlaps(unit._worldBounds),
            )
          : const [],
    );
  }
}
