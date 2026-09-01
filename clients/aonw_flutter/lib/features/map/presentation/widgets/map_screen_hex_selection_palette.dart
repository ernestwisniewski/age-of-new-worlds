part of 'map_screen.dart';

extension _MapScreenHexSelectionPalette on _MapScreenState {
  void _openHexSelectionPalette(
    MapHexCoordinate? coordinate,
    AonwPoint screenPosition,
  ) {
    final state = widget.controller.state;
    final l10n = _localizations;
    if (coordinate == null || state is! GameSessionReady || l10n == null) {
      _flameGame.clearHexSelectionPalette();
      return;
    }
    final view = buildMapHexSelectionPaletteView(
      coordinate: coordinate,
      map: state.scene.map,
      player: state.scene.player,
      l10n: l10n,
    );
    if (view == null) {
      _flameGame.clearHexSelectionPalette();
      return;
    }
    _flameGame.openHexSelectionPalette(
      view,
      anchorScreenPosition: screenPosition,
    );
  }

  void _handleHexSelectionPaletteIntent(MapHexSelectionPaletteIntent intent) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) return;
    if (widget.controller.networkConnection.blocksGameplay) return;
    final state = widget.controller.state;
    if (state is! GameSessionReady || state.localHandoff.blocksGameplay) return;
    switch (intent) {
      case SelectUnitHexPaletteIntent(:final unitId):
        widget.controller.selectUnit(unitId);
      case SelectCityHexPaletteIntent(:final cityId):
        widget.controller.selectCity(cityId);
      case MapHexSelectionPaletteIntent(:final coordinate):
        widget.controller.select(coordinate);
    }
  }
}
