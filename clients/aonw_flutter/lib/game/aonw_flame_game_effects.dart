part of 'aonw_flame_game.dart';

extension AonwFlameGameEffects on AonwFlameGame {
  Future<void> waitForCommandEffects() {
    if (_disposed || !_hasCommandEffects) return Future.value();
    return (_commandEffectsCompletion ??= Completer<void>()).future;
  }

  bool get _hasAmbientAnimation =>
      _cloudsActive || _productionActive || _routeActive;

  bool get _hasCommandEffects =>
      _effectsActive || _eventFeedbackActive || _eraTintActive || _cameraActive;

  void _completeCommandEffectsIfIdle() {
    if (!_hasCommandEffects) _completeCommandEffects();
  }

  void _completeCommandEffects() {
    _commandEffectsCompletion?.complete();
    _commandEffectsCompletion = null;
  }

  void setReducedMotion(bool enabled) {
    if (_disposed || _reducedMotion == enabled) return;
    _reducedMotion = enabled;
    mapCamera.setMotionEnabled(_smoothCameraMovement && !enabled);
    world.effectHost.setReducedMotion(enabled);
    world.unitLayer.setReducedMotion(enabled);
    world.routeLayer.setReducedMotion(enabled);
    world.cloudLayer.setReducedMotion(enabled);
    world.eraTintLayer.setReducedMotion(enabled);
    world.eventFeedbackLayer.setReducedMotion(enabled);
    world.cityProductionLayer.setReducedMotion(enabled);
    _requestInputFrame();
  }

  void setUnitMovementAnimations(bool enabled) {
    if (_disposed || world.effectHost.movementAnimationsEnabled == enabled) {
      return;
    }
    world.effectHost.setMovementAnimations(enabled);
    _requestInputFrame();
  }

  void setUnitIdleAnimations(bool enabled) {
    if (_disposed) return;
    world.unitLayer.setIdleAnimations(enabled);
  }

  void setRouteAnimations(bool enabled) {
    if (_disposed) return;
    world.routeLayer.setAnimations(enabled);
  }

  void _handleRouteActivity(bool active) {
    if (_disposed || _routeActive == active) return;
    _routeActive = active;
    _synchronizeGameLoop();
  }

  void setCombatAnimations(bool enabled) {
    if (_disposed || world.effectHost.combatAnimationsEnabled == enabled) {
      return;
    }
    world.effectHost.setCombatAnimations(enabled);
    _requestInputFrame();
  }

  void setEffectPlaybackSpeed(double speed) {
    if (_disposed) return;
    world.effectHost.setPlaybackSpeed(speed);
    world.eraTintLayer.setPlaybackSpeed(speed);
    world.eventFeedbackLayer.setPlaybackSpeed(speed);
    world.cityProductionLayer.setPlaybackSpeed(speed);
  }

  void skipEffects() {
    if (_disposed) return;
    mapCamera.skipMotion();
    world.effectHost.skipAll();
    world.eraTintLayer.skip();
    world.eventFeedbackLayer.skip();
    world.cityProductionLayer.skip();
    _requestInputFrame();
  }

  void _handleEffectActivity(bool active) {
    if (_disposed || _effectsActive == active) return;
    _effectsActive = active;
    _completeCommandEffectsIfIdle();
    _synchronizeGameLoop();
  }

  void _handleCloudActivity(bool active) {
    if (_disposed || _cloudsActive == active) return;
    _cloudsActive = active;
    _synchronizeGameLoop();
  }

  void _handleEraTintActivity(bool active) {
    if (_disposed || _eraTintActive == active) return;
    _eraTintActive = active;
    _completeCommandEffectsIfIdle();
    _synchronizeGameLoop();
  }

  void _handleEventFeedbackActivity(bool active) {
    if (_disposed || _eventFeedbackActive == active) return;
    _eventFeedbackActive = active;
    _completeCommandEffectsIfIdle();
    _synchronizeGameLoop();
  }

  void _handleProductionActivity(bool active) {
    if (_disposed || _productionActive == active) return;
    _productionActive = active;
    _synchronizeGameLoop();
  }
}
