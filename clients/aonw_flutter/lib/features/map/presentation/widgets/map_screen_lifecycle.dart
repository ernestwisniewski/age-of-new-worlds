part of 'map_screen.dart';

extension _MapScreenLifecycle on _MapScreenState {
  void _subscribeToRoute() {
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _subscribedRoute) return;
    widget.routeObserver?.unsubscribe(this);
    _subscribedRoute = route;
    widget.routeObserver?.subscribe(this, route);
  }

  void _setRouteVisible(bool visible) {
    if (_routeVisible == visible) return;
    _routeVisible = visible;
    _synchronizeFlameLifecycle();
  }

  void _synchronizeFlameLifecycle() {
    if (!_routeVisible || _lifecycleState != AppLifecycleState.resumed) {
      widget.controller.silencePendingInteractionSounds();
    }
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
