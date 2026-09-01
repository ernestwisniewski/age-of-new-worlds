part of 'aonw_flame_game.dart';

extension _AonwFlameGameViewportInput on AonwFlameGame {
  void _handleViewportIntent(MapViewportIntent intent) {
    if (!_viewportActive) return;
    mapCamera.applyIntent(intent);
    switch (intent) {
      case MapHoverIntent(:final screenPosition):
        _emitHover(mapCamera.hexAtScreen(screenPosition));
      case MapHoverExitIntent():
        _emitHover(null);
      case MapSelectIntent(:final screenPosition):
        if (_handleActionPaletteTap(screenPosition)) break;
        _hexIntentSink?.call(
          MapHexSelectIntent(mapCamera.hexAtScreen(screenPosition)),
        );
      case MapViewportFrameIntent(:final hoverScreenPosition):
        if (hoverScreenPosition != null) {
          _emitHover(mapCamera.hexAtScreen(hoverScreenPosition));
        }
      case MapPanIntent() || MapZoomIntent():
        break;
    }
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
