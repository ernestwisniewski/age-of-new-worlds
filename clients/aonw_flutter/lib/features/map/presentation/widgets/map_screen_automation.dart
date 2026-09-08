part of 'map_screen.dart';

extension _MapScreenAutomation on _MapScreenState {
  void _observeAutomaticTurn() {
    final state = widget.controller.state;
    _automaticFlow.observe(state, session: widget.controller);
    final signature = (
      widget.controller,
      widget.controller.networkConnection,
      _automaticStateKey(state),
    );
    if (_automaticObserved == signature) return;
    _automaticObserved = signature;
    _requestAutomaticTurn();
  }

  void _requestAutomaticTurn() {
    if (_automaticDisposed || !mounted) return;
    _automaticDirty = true;
    if (_automaticQueued || _automaticOperation != null) return;
    _automaticQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _automaticQueued = false;
      if (_automaticDisposed || !mounted) return;
      unawaited(_runAutomaticTurn());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _runAutomaticTurn() async {
    _automaticDirty = false;
    if (!_automaticMapAvailable) return;
    final operation = Object();
    _automaticOperation = operation;
    final controller = widget.controller;
    final game = _flameGame;
    final generation = _automaticGeneration;
    bool available() =>
        generation == _automaticGeneration &&
        identical(controller, widget.controller) &&
        identical(game, _flameGame) &&
        _automaticMapAvailable;
    try {
      if (game.hasActiveUnitEffects) await game.waitForCommandEffects();
      if (!available()) return;
      await controller.navigateTurnActions(
        step: 1,
        automatic: _automaticFlow.policyFor,
        inputAvailable: () => available() && !game.hasActiveUnitEffects,
        onFocus: game.mapCamera.centerOnHex,
      );
    } finally {
      if (identical(_automaticOperation, operation)) {
        _automaticOperation = null;
        if (_automaticDirty) _requestAutomaticTurn();
      }
    }
  }

  bool get _automaticUiAvailable =>
      !_automaticDisposed &&
      mounted &&
      _automaticSettingsReady &&
      _automaticFlow.enabled &&
      _automaticFlow.settings ==
          ClientSettingsScope.currentSettingsOf(context).automation &&
      _routeVisible &&
      _lifecycleState == AppLifecycleState.resumed &&
      !_gamepadNavigation.hasOpenPanel &&
      !_gamepadNavigation.capturesInput;

  bool get _automaticMapAvailable {
    if (!_automaticUiAvailable ||
        widget.controller.networkConnection.blocksGameplay) {
      return false;
    }
    final state = widget.controller.state;
    return state is GameSessionReady &&
        state.inspection == null &&
        !state.turnAction.inFlight &&
        state.turnAction.failure == null &&
        !state.localAiTurn.blocksGameplay &&
        !state.localHandoff.blocksGameplay &&
        !state.localSave.inFlight;
  }
}

Object _automaticStateKey(GameSessionState state) => switch (state) {
  GameSessionReady() => (
    state.recipient,
    state.interaction,
    state.turnAction,
    state.inspection,
    state.research.commandPending,
    state.diplomacy.commandPending,
    state.localAiTurn,
    state.localHandoff,
    state.localSave.inFlight,
  ),
  _ => state,
};
