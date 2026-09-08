part of 'map_screen.dart';

extension _MapScreenCursor on _MapScreenState {
  GameSessionReady? _mapInputReady(MapInputCommand command) {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) {
      return null;
    }
    final state = widget.controller.state;
    if (state is! GameSessionReady) return null;
    if (widget.controller.networkConnection.blocksGameplay) return null;
    if (state.localHandoff.blocksGameplay) return null;
    if (_gamepadNavigation.handleCommand(command)) return null;
    return state;
  }

  void _handleGamepadCommand(MapInputCommand command) {
    if (!_gamepadSettings.enabled) return;
    final state = _mapInputReady(command);
    if (state == null) return;
    switch (command) {
      case MapInputCommand.activate:
        final coordinate = _gamepadCursor.current(
          state,
          viewportCenter: _viewportCenterHex,
        );
        if (coordinate != null) widget.controller.select(coordinate);
      case MapInputCommand.cursorUp:
      case MapInputCommand.cursorDown:
      case MapInputCommand.cursorLeft:
      case MapInputCommand.cursorRight:
        final coordinate = _gamepadCursor.move(
          state,
          command,
          viewportCenter: _viewportCenterHex,
        );
        if (coordinate != null) widget.controller.moveMapCursor(coordinate);
      default:
        _handleReadyInput(state, command);
    }
  }

  void _inspectCursor(GameSessionReady state) {
    final coordinate = _gamepadCursor.current(
      state,
      viewportCenter: _viewportCenterHex,
    );
    if (coordinate != null) widget.controller.inspectHex(coordinate);
  }

  MapHexCoordinate? get _viewportCenterHex {
    final center = _flameGame.mapCamera.viewportCenter;
    return center == null ? null : _flameGame.mapCamera.hexAtScreen(center);
  }
}
