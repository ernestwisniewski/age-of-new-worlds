part of 'map_screen.dart';

extension _MapScreenGamepad on _MapScreenState {
  void _listenToInput(MapInputSource? source) {
    unawaited(_inputSubscription?.cancel());
    unawaited(_continuousInputSubscription?.cancel());
    _inputSubscription = source?.commands.listen(_handleGamepadCommand);
    _gamepadInput = MapGamepadInput.idle;
    _gamepadFrames.prime(_gamepadInput);
    _continuousInputSubscription = switch (source) {
      ContinuousMapInputSource(:final continuousInputs) =>
        continuousInputs.listen(_handleContinuousInput),
      _ => null,
    };
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadSettings(ClientGamepadSettings settings) {
    if (_gamepadSettings == settings) return;
    _gamepadSettings = settings;
    _gamepadOwnerGeneration += 1;
    _gamepadFrames = MapGamepadFrameController(
      cameraSensitivity: settings.cameraSensitivity,
      deadzone: settings.deadzone,
      invertCameraY: settings.invertCameraY,
    )..prime(_gamepadInput);
    _synchronizeGamepadAvailability();
    _synchronizeGamepadTicker();
  }

  void _handleContinuousInput(MapGamepadInput input) {
    _gamepadInput = input;
    _synchronizeGamepadTicker();
  }

  void _synchronizeGamepadTicker() {
    final available =
        widget.interactionEnabled &&
        _gamepadSettings.enabled &&
        _routeVisible &&
        _lifecycleState == AppLifecycleState.resumed;
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
    return widget.interactionEnabled &&
        _gamepadSettings.enabled &&
        state is GameSessionReady &&
        !widget.controller.networkConnection.blocksGameplay;
  }

  void _tickGamepad(Duration elapsed) {
    final previous = _lastGamepadElapsed;
    _lastGamepadElapsed = elapsed;
    final dt = previous == null
        ? 0.0
        : (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final frame = _gamepadFrames.advance(input: _gamepadInput, dt: dt);
    if (_routeBlockingFrame(frame)) {
      _synchronizeGamepadTicker();
      return;
    }
    if (!frame.isIdle &&
        _acceptsGamepadInput &&
        !_gamepadNavigation.handleFrame(frame)) {
      if (_navigateTurnFrame(frame)) {
        _synchronizeGamepadTicker();
        return;
      }
      _applyMapFrame(frame, dt);
    }
    _synchronizeGamepadTicker();
  }

  bool get _sessionOverlayBlocksInput {
    final state = widget.controller.state;
    return state is GameSessionReady &&
        (state.localHandoff.blocksGameplay ||
            (!widget.controller.readOnly &&
                state.recipient.turnView.outcome.isTerminal));
  }

  bool _routeBlockingFrame(MapGamepadFrame frame) {
    if (!_sessionOverlayBlocksInput) return false;
    if (_acceptsGamepadInput && _gamepadNavigation.hasModal) {
      _gamepadNavigation.handleFrame(frame);
    }
    return true;
  }

  void _applyMapFrame(MapGamepadFrame frame, double dt) {
    _flameGame.applyGamepadCameraFrame(frame, dt);
    final cursorStep = frame.cursorStep;
    if (cursorStep != null) _handleGamepadCommand(cursorStep);
    if (frame.cancelPressed) _handleGamepadCommand(MapInputCommand.cancel);
    if (frame.toggleMoveTargetingPressed) {
      _handleGamepadCommand(MapInputCommand.toggleMoveTargeting);
    }
    if (frame.activatePressed) {
      _handleGamepadCommand(MapInputCommand.activate);
    }
    if (frame.inspectHexPressed) {
      _handleGamepadCommand(MapInputCommand.inspectHex);
    }
  }
}

extension _MapScreenTurnInput on _MapScreenState {
  bool _navigateTurnFrame(MapGamepadFrame frame) {
    if (!_hasTurnIntent(frame)) return false;
    if (frame.focusPreviousPressed &&
        frame.focusNextPressed &&
        !frame.primaryActionPressed) {
      return true;
    }
    final controller = widget.controller;
    final generation = _flameGeneration;
    final ownerGeneration = _gamepadOwnerGeneration;
    bool available() =>
        identical(controller, widget.controller) &&
        generation == _flameGeneration &&
        ownerGeneration == _gamepadOwnerGeneration &&
        _turnInputAvailable;
    unawaited(
      controller.navigateTurnActions(
        step: frame.primaryActionPressed || frame.focusNextPressed ? 1 : -1,
        endWhenEmpty: frame.primaryActionPressed,
        inputAvailable: available,
        onFocus: _flameGame.mapCamera.centerOnHex,
      ),
    );
    return true;
  }

  bool get _turnInputAvailable =>
      !widget.controller.readOnly &&
      mounted &&
      _routeVisible &&
      _lifecycleState == AppLifecycleState.resumed &&
      _acceptsGamepadInput &&
      !_sessionOverlayBlocksInput &&
      !_gamepadNavigation.capturesInput &&
      !_flameGame.hasActiveUnitEffects;

  bool _hasTurnIntent(MapGamepadFrame frame) =>
      !frame.cancelPressed &&
      !frame.activatePressed &&
      !frame.inspectHexPressed &&
      !frame.toggleMoveTargetingPressed &&
      (frame.primaryActionPressed ||
          frame.focusPreviousPressed ||
          frame.focusNextPressed);
}
