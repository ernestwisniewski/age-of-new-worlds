part of 'aonw_flame_game.dart';

extension AonwFlameGameEffects on AonwFlameGame {
  void setReducedMotion(bool enabled) {
    if (_disposed || _reducedMotion == enabled) return;
    _reducedMotion = enabled;
    world.effectHost.setReducedMotion(enabled);
    world.cloudLayer.setReducedMotion(enabled);
    world.eraTintLayer.setReducedMotion(enabled);
    world.eventFeedbackLayer.setReducedMotion(enabled);
    _requestInputFrame();
  }

  void setEffectPlaybackSpeed(double speed) {
    if (_disposed) return;
    world.effectHost.setPlaybackSpeed(speed);
    world.eraTintLayer.setPlaybackSpeed(speed);
    world.eventFeedbackLayer.setPlaybackSpeed(speed);
  }

  void skipEffects() {
    if (_disposed) return;
    world.effectHost.skipAll();
    world.eraTintLayer.skip();
    world.eventFeedbackLayer.skip();
    _requestInputFrame();
  }

  void _handleEffectActivity(bool active) {
    if (_disposed || _effectsActive == active) return;
    _effectsActive = active;
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
    _synchronizeGameLoop();
  }

  void _handleEventFeedbackActivity(bool active) {
    if (_disposed || _eventFeedbackActive == active) return;
    _eventFeedbackActive = active;
    _synchronizeGameLoop();
  }
}
