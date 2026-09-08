part of 'map_screen.dart';

extension _MapScreenKeyboard on _MapScreenState {
  void _invalidateKeyboardInput() => _keyboardInputGeneration += 1;

  void _handleKeyboardTurnShortcut(MapTurnShortcut shortcut) {
    final controller = widget.controller;
    final generation = _flameGeneration;
    final inputGeneration = _keyboardInputGeneration;
    final ownerGeneration = _gamepadOwnerGeneration;
    bool available() =>
        mounted &&
        identical(controller, widget.controller) &&
        generation == _flameGeneration &&
        inputGeneration == _keyboardInputGeneration &&
        ownerGeneration == _gamepadOwnerGeneration &&
        _keyboardTurnInputAvailable;
    if (!available()) return;
    unawaited(
      controller.navigateTurnActions(
        step: shortcut == MapTurnShortcut.previous ? -1 : 1,
        endWhenEmpty: shortcut == MapTurnShortcut.primary,
        inputAvailable: available,
        onFocus: _flameGame.mapCamera.centerOnHex,
      ),
    );
  }

  bool get _keyboardTurnInputAvailable =>
      _keyboardMapInputAvailable && !_flameGame.hasActiveUnitEffects;

  bool get _keyboardMapInputAvailable {
    final state = widget.controller.state;
    return _routeVisible &&
        _lifecycleState == AppLifecycleState.resumed &&
        _flameFocusNode.hasFocus &&
        state is GameSessionReady &&
        !state.localHandoff.blocksGameplay &&
        !widget.controller.networkConnection.blocksGameplay &&
        !_gamepadNavigation.capturesInput &&
        !_gamepadNavigation.hasOpenPanel;
  }
}
