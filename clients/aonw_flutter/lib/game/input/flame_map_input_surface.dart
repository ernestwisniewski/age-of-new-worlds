import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/input/map_viewport_intent.dart';

/// Coalesces raw viewport input without entering Flutter's gesture arena.
final class FlameMapInputSurface extends PositionComponent {
  FlameMapInputSurface({
    required MapViewportIntentSink onIntent,
    required void Function() requestFrame,
  }) : _onIntent = onIntent,
       _requestFrame = requestFrame,
       super(priority: 1000);

  static const dragThreshold = 8.0;
  static const scrollSensitivity = 0.001;

  final MapViewportIntentSink _onIntent;
  final void Function() _requestFrame;
  final Map<int, Vector2> _pointers = {};
  final Vector2 _dragDisplacement = Vector2.zero();
  final Vector2 _pendingDragDelta = Vector2.zero();
  Vector2? _pendingHover;
  var _pendingPanX = 0.0;
  var _pendingPanY = 0.0;
  Vector2? _pendingZoomFocalPoint;
  var _pendingZoomFactor = 1.0;
  Vector2? _lastPinchFocus;
  var _lastPinchDistance = 0.0;
  var _lastPanZoomScale = 1.0;
  var _enabled = false;
  var _frameRequested = false;
  var _isDragging = false;
  var _suppressNextSelect = false;
  var _flushCount = 0;
  var _cameraSensitivity = 1.0;

  @visibleForTesting
  int get debugFlushCount => _flushCount;

  @visibleForTesting
  double get debugCameraSensitivity => _cameraSensitivity;

  @visibleForTesting
  bool get debugIsDragging => _isDragging;

  bool get isEnabled => _enabled;

  void setCameraSensitivity(double sensitivity) {
    if (!sensitivity.isFinite || sensitivity < 0.5 || sensitivity > 2) {
      throw ArgumentError.value(
        sensitivity,
        'sensitivity',
        'must be between 0.5 and 2',
      );
    }
    _cameraSensitivity = sensitivity;
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _clearPending();
      _resetPointers();
    }
  }

  void resize(Vector2 viewport) {
    size.setFrom(viewport);
  }

  void submitHover(Vector2 screenPosition) {
    if (!_enabled) return;
    _pendingHover = screenPosition.clone();
    _ensureFrame();
  }

  void submitHoverExit() {
    if (!_enabled) return;
    _pendingHover = null;
    _onIntent(const MapHoverExitIntent());
  }

  void submitSelect(Vector2 screenPosition) {
    if (!_enabled) return;
    if (_suppressNextSelect) {
      _suppressNextSelect = false;
      return;
    }
    _onIntent(MapSelectIntent((x: screenPosition.x, y: screenPosition.y)));
  }

  void submitPan(Vector2 screenDelta) {
    if (!_enabled) return;
    _pendingPanX += screenDelta.x;
    _pendingPanY += screenDelta.y;
    _ensureFrame();
  }

  void submitZoom({required Vector2 focalPoint, required double factor}) {
    if (!_enabled || !factor.isFinite || factor <= 0) return;
    _pendingZoomFocalPoint = focalPoint.clone();
    _pendingZoomFactor *= factor;
    _ensureFrame();
  }

  void handlePointerDown(int pointerId, Vector2 position) {
    if (!_enabled) return;
    _pointers[pointerId] = position.clone();
    if (_pointers.length == 1) {
      _startDrag();
      _suppressNextSelect = false;
    } else if (_pointers.length == 2) {
      _startPinch();
      _endDrag();
      _suppressNextSelect = true;
    }
  }

  void handlePointerMove(int pointerId, Vector2 position) {
    if (!_enabled) return;
    final previous = _pointers[pointerId];
    if (previous == null) return;
    _pointers[pointerId] = position.clone();
    if (_pointers.length >= 2) {
      _updatePinch();
      _suppressNextSelect = true;
      return;
    }
    _updateDrag(position - previous);
  }

  void handlePointerUp(int pointerId) {
    if (!_enabled) return;
    if (_isDragging || _pointers.length > 1) _suppressNextSelect = true;
    _pointers.remove(pointerId);
    if (_pointers.isEmpty) {
      _endDrag();
      _clearPinch();
    } else if (_pointers.length == 1) {
      _startDrag();
      _clearPinch();
    } else {
      _startPinch();
    }
  }

  void handlePointerCancel(int pointerId) => handlePointerUp(pointerId);

  void handlePanZoomStart(Vector2 focalPoint) {
    if (!_enabled) return;
    _lastPanZoomScale = 1;
    _suppressNextSelect = true;
  }

  void handlePanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) {
    if (!_enabled) return;
    if (panDelta.length2 > 0) submitPan(panDelta);
    if (scale > 0) {
      submitZoom(focalPoint: focalPoint, factor: scale / _lastPanZoomScale);
      _lastPanZoomScale = scale;
    }
  }

  void handlePanZoomEnd() {
    _lastPanZoomScale = 1;
    _endDrag();
  }

  void handleScroll({required Vector2 focalPoint, required double deltaY}) {
    submitZoom(focalPoint: focalPoint, factor: 1 - deltaY * scrollSensitivity);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_enabled) return;
    final hover = _pendingHover;
    final hasPan = _pendingPanX != 0 || _pendingPanY != 0;
    final zoomFocalPoint = _pendingZoomFocalPoint;
    final hasZoom = zoomFocalPoint != null && _pendingZoomFactor != 1;
    if (hover == null && !hasPan && !hasZoom) return;
    _flushCount += 1;
    _onIntent(
      MapViewportFrameIntent(
        screenPanDelta: (x: _pendingPanX, y: _pendingPanY),
        zoomFocalPoint: zoomFocalPoint == null
            ? null
            : (x: zoomFocalPoint.x, y: zoomFocalPoint.y),
        zoomFactor: _pendingZoomFactor,
        hoverScreenPosition: hover == null ? null : (x: hover.x, y: hover.y),
      ),
    );
    _clearPending();
  }

  void _updateDrag(Vector2 delta) {
    _dragDisplacement.add(delta);
    final wasDragging = _isDragging;
    if (_dragDisplacement.length2 >= dragThreshold * dragThreshold) {
      _isDragging = true;
    }
    if (!_isDragging) {
      _pendingDragDelta.add(delta);
      return;
    }
    _suppressNextSelect = true;
    if (wasDragging) {
      submitPan(delta);
      return;
    }
    _pendingDragDelta.add(delta);
    submitPan(_pendingDragDelta);
    _pendingDragDelta.setZero();
  }

  void _startDrag() {
    _dragDisplacement.setZero();
    _pendingDragDelta.setZero();
    _isDragging = false;
  }

  void _endDrag() {
    _dragDisplacement.setZero();
    _pendingDragDelta.setZero();
    _isDragging = false;
  }

  void _startPinch() {
    _lastPinchFocus = _pinchFocus();
    _lastPinchDistance = _pinchDistance();
  }

  void _updatePinch() {
    final focus = _pinchFocus();
    final distance = _pinchDistance();
    final previousFocus = _lastPinchFocus;
    if (focus == null || previousFocus == null || distance < 1) return;
    if (_lastPinchDistance >= 1) {
      submitPan(focus - previousFocus);
      submitZoom(focalPoint: focus, factor: distance / _lastPinchDistance);
    }
    _lastPinchFocus = focus;
    _lastPinchDistance = distance;
  }

  Vector2? _pinchFocus() {
    final positions = _pointers.values.take(2).toList(growable: false);
    if (positions.length < 2) return null;
    return (positions[0] + positions[1]) / 2;
  }

  double _pinchDistance() {
    final positions = _pointers.values.take(2).toList(growable: false);
    if (positions.length < 2) return 0;
    final delta = positions[0] - positions[1];
    return math.sqrt(delta.length2);
  }

  void _clearPinch() {
    _lastPinchFocus = null;
    _lastPinchDistance = 0;
  }

  void _resetPointers() {
    _pointers.clear();
    _endDrag();
    _clearPinch();
    _lastPanZoomScale = 1;
    _suppressNextSelect = false;
  }

  void _clearPending() {
    _pendingHover = null;
    _pendingPanX = 0;
    _pendingPanY = 0;
    _pendingZoomFocalPoint = null;
    _pendingZoomFactor = 1;
    _frameRequested = false;
  }

  void _ensureFrame() {
    if (_frameRequested) return;
    _frameRequested = true;
    _requestFrame();
  }
}
