part of 'map_screen.dart';

extension _MapScreenGamepad on _MapScreenState {
  void _listenToInput(MapInputSource? source) {
    unawaited(_inputSubscription?.cancel());
    unawaited(_continuousInputSubscription?.cancel());
    _inputSubscription = source?.commands.listen(_handleInput);
    _gamepadInput = MapGamepadInput.idle;
    _gamepadFrames.prime(_gamepadInput);
    _continuousInputSubscription = switch (source) {
      ContinuousMapInputSource(:final continuousInputs) =>
        continuousInputs.listen(_handleContinuousInput),
      _ => null,
    };
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadSettings(double cameraSensitivity) {
    if (_gamepadFrames.cameraSensitivity == cameraSensitivity) return;
    _gamepadFrames = MapGamepadFrameController(
      cameraSensitivity: cameraSensitivity,
    )..prime(_gamepadInput);
    _synchronizeGamepadTicker();
  }

  void _handleContinuousInput(MapGamepadInput input) {
    _gamepadInput = input;
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadTicker() {
    final available =
        _routeVisible && _lifecycleState == AppLifecycleState.resumed;
    if (!available || (_gamepadInput.isIdle && _gamepadFrames.isIdle)) {
      _lastGamepadElapsed = null;
      _gamepadTicker.stop();
      return;
    }
    if (!_gamepadTicker.isActive) _gamepadTicker.start();
  }

  void _synchronizeGamepadAvailability() => _gamepadNavigation.setAvailable(
    _routeVisible &&
        _lifecycleState == AppLifecycleState.resumed &&
        _acceptsGamepadInput,
  );

  bool get _acceptsGamepadInput {
    final state = widget.controller.state;
    return state is GameSessionReady &&
        !state.localHandoff.blocksGameplay &&
        !widget.controller.networkConnection.blocksGameplay;
  }

  void _tickGamepad(Duration elapsed) {
    final previous = _lastGamepadElapsed;
    _lastGamepadElapsed = elapsed;
    final dt = previous == null
        ? 0.0
        : (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final frame = _gamepadFrames.advance(input: _gamepadInput, dt: dt);
    if (!frame.isIdle &&
        _acceptsGamepadInput &&
        !_gamepadNavigation.handleFrame(frame)) {
      _flameGame.applyGamepadCameraFrame(frame, dt);
      final cursorStep = frame.cursorStep;
      if (cursorStep != null) _handleInput(cursorStep);
      if (frame.cancelPressed) _handleInput(MapInputCommand.cancel);
      if (frame.toggleMoveTargetingPressed) {
        _handleInput(MapInputCommand.toggleMoveTargeting);
      }
      if (frame.activatePressed) _handleInput(MapInputCommand.activate);
      if (frame.toggleMapViewModePressed) {
        _handleInput(MapInputCommand.toggleMapViewMode);
      }
    }
    _synchronizeGamepadTicker();
  }
}
