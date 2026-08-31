import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import '../../features/map/presentation/input/map_viewport_intent.dart';

final class FlameMapInputSurface extends PositionComponent
    with
        TapCallbacks,
        PointerMoveCallbacks,
        DragCallbacks,
        ScaleCallbacks,
        ScrollCallbacks {
  FlameMapInputSurface({
    required MapViewportIntentSink onIntent,
    required void Function() requestFrame,
  }) : _onIntent = onIntent,
       _requestFrame = requestFrame,
       super(priority: 1000);

  final MapViewportIntentSink _onIntent;
  final void Function() _requestFrame;
  Vector2? _pendingHover;
  var _pendingPanX = 0.0;
  var _pendingPanY = 0.0;
  Vector2? _pendingZoomFocalPoint;
  var _pendingZoomFactor = 1.0;
  var _lastScale = 1.0;
  var _enabled = false;
  var _frameRequested = false;
  var _flushCount = 0;

  @visibleForTesting
  int get debugFlushCount => _flushCount;

  @visibleForTesting
  double get debugCameraSensitivity => _cameraSensitivity;

  bool get isEnabled => _enabled;

  var _cameraSensitivity = 1.0;

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
    if (!enabled) _clearPending();
  }

  void resize(Vector2 viewport) {
    size.setFrom(viewport);
  }

  void submitHover(Vector2 screenPosition) {
    if (!_enabled) return;
    _pendingHover = screenPosition.clone();
    _ensureFrame();
  }

  void submitSelect(Vector2 screenPosition) {
    if (!_enabled) return;
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

  @override
  void onTapUp(TapUpEvent event) {
    submitSelect(event.canvasPosition);
    super.onTapUp(event);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    submitHover(event.canvasPosition);
    super.onPointerMove(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    submitPan(event.canvasDelta);
    super.onDragUpdate(event);
  }

  @override
  void onScaleStart(ScaleStartEvent event) {
    _lastScale = 1;
    super.onScaleStart(event);
  }

  @override
  void onScaleUpdate(ScaleUpdateEvent event) {
    final factor = event.scale / _lastScale;
    _lastScale = event.scale;
    if (event.pointerCount > 1) submitPan(event.focalPointDelta);
    submitZoom(focalPoint: event.canvasEndPosition, factor: factor);
    super.onScaleUpdate(event);
  }

  @override
  void onScaleEnd(ScaleEndEvent event) {
    _lastScale = 1;
    super.onScaleEnd(event);
  }

  @override
  void onScroll(ScrollEvent event) {
    submitZoom(
      focalPoint: event.canvasPosition,
      factor: math.exp(-event.scrollDelta.y * _cameraSensitivity / 500),
    );
    super.onScroll(event);
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
