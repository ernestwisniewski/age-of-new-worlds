part of 'map_screen.dart';

extension _MapScreenLifecycle on _MapScreenState {
  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _subscribedRoute) return;
    widget.routeObserver?.unsubscribe(this);
    _subscribedRoute = route;
    widget.routeObserver?.subscribe(this, route);
    _setRouteVisible(route.isCurrent);
  }

  void _setRouteVisible(bool visible) {
    if (_routeVisible == visible) return;
    _invalidateKeyboardInput();
    _routeVisible = visible;
    _synchronizeFlameLifecycle();
  }

  void _synchronizeFlameLifecycle() {
    final available =
        _routeVisible && _lifecycleState == AppLifecycleState.resumed;
    if (_gamepadAvailable != available) {
      _gamepadAvailable = available;
      _gamepadFrames.prime(_gamepadInput);
    }
    if (!available) {
      widget.controller.silencePendingInteractionSounds();
    }
    _synchronizeGamepadAvailability();
    _flameGame.setViewportActive(
      _routeVisible && _lifecycleState == AppLifecycleState.resumed,
    );
    _synchronizeGamepadTicker();
  }

  void _playInteractionSound(GameSoundCue cue) {
    if (!mounted ||
        !_routeVisible ||
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    context.playGameSound(cue);
  }
}
