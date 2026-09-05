part of 'map_city_production_layer.dart';

extension _MapCityProductionTiming on MapCityProductionLayerComponent {
  void _changePlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'must be finite and positive');
    }
    _cancelTimer();
    _speed = speed;
    _refreshTiming();
  }

  void _cancelTimer() {
    final started = _idleStarted;
    if (started != null) {
      final elapsed =
          _now().difference(started).inMicroseconds / 1000000 * _speed;
      _time += elapsed.clamp(0.0, _idleDelay);
    }
    _timer?.cancel();
    _timer = null;
    _idleStarted = null;
  }

  void _refreshTiming() {
    if (!_canShow || _time < _cameraReadyAt) {
      _reportActivity(false);
      if (_canShow) _scheduleAt(_cameraReadyAt);
      return;
    }
    for (final hint in _hints.values) {
      hint.advance(_time);
    }
    final active = _hints.values.any((hint) => hint.activeAt(_time));
    _reportActivity(active);
    if (active || _hints.isEmpty || _timer != null) return;
    final next = _hints.values
        .map((hint) => hint.nextEmission)
        .reduce((a, b) => a < b ? a : b);
    _scheduleAt(next);
  }

  void _scheduleAt(double next) {
    if (_timer != null) return;
    _idleDelay = next - _time;
    _idleStarted = _now();
    _timer = async.Timer(
      Duration(microseconds: (_idleDelay / _speed * 1000000).round()),
      () {
        _time = next;
        _timer = null;
        _idleStarted = null;
        _synchronizeHints();
      },
    );
  }

  void _reportActivity(bool active) {
    if (_active == active) return;
    _active = active;
    onActivityChanged?.call(active);
  }
}
