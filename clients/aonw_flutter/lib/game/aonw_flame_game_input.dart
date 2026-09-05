part of 'aonw_flame_game.dart';

extension AonwFlameGameViewportInput on AonwFlameGame {
  void setHexSelectionPaletteIntentSink(
    MapHexSelectionPaletteIntentSink? sink,
  ) {
    if (_disposed) return;
    _hexSelectionPaletteIntentSink = sink;
  }

  void openHexSelectionPalette(
    MapHexSelectionPaletteView view, {
    required AonwPoint anchorScreenPosition,
  }) {
    if (_disposed || !_viewportActive) return;
    final cache = world._staticRenderCacheForGame;
    final viewportCenter = mapCamera.viewportCenter;
    if (cache == null || viewportCenter == null) return;
    final towardCenter = (
      x: viewportCenter.x - anchorScreenPosition.x,
      y: viewportCenter.y - anchorScreenPosition.y,
    );
    final directionAngle =
        towardCenter.x * towardCenter.x + towardCenter.y * towardCenter.y < 1
        ? -math.pi / 2
        : math.atan2(towardCenter.y, towardCenter.x);
    world.hexSelectionPaletteLayer.open(
      cache: cache,
      view: view,
      directionAngle: directionAngle,
      screenScale: 1 / mapCamera.zoom,
    );
    _requestInputFrame();
  }

  void clearHexSelectionPalette() {
    world.hexSelectionPaletteLayer.clearLayer();
    _requestInputFrame();
  }

  void handleViewportLongPressStart(Vector2 position) {
    if (_disposed || !_viewportActive || inputSurface.isDragging) return;
    inputSurface.suppressNextSelect();
    final screenPosition = (x: position.x, y: position.y);
    final coordinate = mapCamera.hexAtScreen(screenPosition);
    _longPressedHex = coordinate;
    _emitHover(coordinate);
    _hexIntentSink?.call(
      MapHexLongPressIntent(coordinate, screenPosition: screenPosition),
    );
  }

  void handleViewportLongPressMoveUpdate(Vector2 position) {
    final pressed = _longPressedHex;
    if (pressed == null) return;
    final coordinate = mapCamera.hexAtScreen((x: position.x, y: position.y));
    if (coordinate == pressed) {
      _emitHover(coordinate);
      return;
    }
    _longPressedHex = null;
    clearHexSelectionPalette();
    _emitHover(null);
  }

  void handleViewportLongPressEnd() {
    _longPressedHex = null;
    _emitHover(null);
  }

  void handleViewportLongPressCancel() {
    _longPressedHex = null;
    clearHexSelectionPalette();
    _emitHover(null);
  }

  void _handleViewportIntent(MapViewportIntent intent) {
    if (!_viewportActive) return;
    mapCamera.applyIntent(intent);
    switch (intent) {
      case MapHoverIntent(:final screenPosition):
        _lastHoverScreenPosition = screenPosition;
        _emitHover(mapCamera.hexAtScreen(screenPosition));
      case MapHoverExitIntent():
        _lastHoverScreenPosition = null;
        _emitHover(null);
      case MapSelectIntent(:final screenPosition):
        if (_handleHexSelectionPaletteTap(screenPosition) ||
            _handleActionPaletteTap(screenPosition)) {
          break;
        }
        _hexIntentSink?.call(
          MapHexSelectIntent(mapCamera.hexAtScreen(screenPosition)),
        );
      case MapViewportFrameIntent():
        _handleViewportFrame(intent);
      case MapPanIntent() || MapZoomIntent():
        world.hexSelectionPaletteLayer.clearLayer();
    }
  }

  void _handleViewportFrame(MapViewportFrameIntent intent) {
    if (_frameMovesViewport(intent)) {
      world.hexSelectionPaletteLayer.clearLayer();
    }
    final hoverScreenPosition = intent.hoverScreenPosition;
    if (hoverScreenPosition != null) {
      _lastHoverScreenPosition = hoverScreenPosition;
      _emitHover(mapCamera.hexAtScreen(hoverScreenPosition));
    }
  }

  bool _frameMovesViewport(MapViewportFrameIntent intent) =>
      intent.screenPanDelta.x != 0 ||
      intent.screenPanDelta.y != 0 ||
      (intent.zoomFocalPoint != null && intent.zoomFactor != 1);

  bool _handleHexSelectionPaletteTap(AonwPoint screenPosition) {
    final worldPoint = mapCamera.worldAtScreen(screenPosition);
    if (worldPoint == null) return false;
    final paletteTap = world.hexSelectionPaletteLayer.handleTap(worldPoint);
    if (!paletteTap.consumed) return false;
    final paletteIntent = paletteTap.intent;
    if (paletteIntent != null) {
      _hexSelectionPaletteIntentSink?.call(paletteIntent);
    }
    _requestInputFrame();
    return true;
  }

  bool _handleActionPaletteTap(AonwPoint screenPosition) {
    final worldPoint = mapCamera.worldAtScreen(screenPosition);
    if (worldPoint == null) return false;
    final paletteTap = world.actionPaletteLayer.handleTap(worldPoint);
    if (!paletteTap.consumed) return false;
    final paletteIntent = paletteTap.intent;
    if (paletteIntent != null) _actionPaletteIntentSink?.call(paletteIntent);
    _requestInputFrame();
    return true;
  }

  void _emitHover(MapHexCoordinate? coordinate) {
    if (_hasHoveredHex && coordinate == _lastHoveredHex) return;
    _hasHoveredHex = true;
    _lastHoveredHex = coordinate;
    _hexIntentSink?.call(MapHexHoverIntent(coordinate));
  }
}
