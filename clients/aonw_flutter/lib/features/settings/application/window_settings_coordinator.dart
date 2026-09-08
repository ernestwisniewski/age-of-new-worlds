import 'dart:async';

import 'window_settings.dart';

final class WindowSettingsCoordinator {
  WindowSettingsCoordinator({
    required GameWindowPort window,
    required WindowSettingsStore store,
  }) : _window = window,
       _store = store;

  final GameWindowPort _window;
  final WindowSettingsStore _store;
  final _changes = StreamController<WindowSettings>.broadcast(sync: true);
  var _settings = const WindowSettings();
  var _tail = Future<void>.value();
  var _generation = 0;
  var _pending = 0;
  var _disposed = false;

  bool get isSupported => _window.isSupported;
  WindowSettings get settings => _settings;
  Stream<WindowSettings> get changes => _changes.stream;

  Future<void> load() async {
    if (_disposed || !isSupported) return;
    final generation = ++_generation;
    await _tail;
    if (_disposed || generation != _generation) return;
    var mode = WindowMode.fullscreen;
    WindowSettingsFailure? failure;
    try {
      mode = await _store.load();
    } on Object {
      failure = WindowSettingsFailure.load;
    }
    if (_disposed || generation != _generation) return;
    await _enqueue(() async {
      if (generation != _generation) return;
      await _apply(mode, persist: false, loadFailure: failure);
    });
  }

  Future<void> setMode(WindowMode mode) {
    if (_disposed || !isSupported) return Future<void>.value();
    _generation += 1;
    return _enqueue(() => _apply(mode, persist: true));
  }

  Future<void> reset() => setMode(WindowMode.fullscreen);

  Future<void> _enqueue(Future<void> Function() operation) {
    _pending += 1;
    _publish(_settings.mode, _settings.failure);
    final result = _tail.then((_) async {
      try {
        if (!_disposed) await operation();
      } finally {
        _pending -= 1;
        _publish(_settings.mode, _settings.failure);
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _apply(
    WindowMode requested, {
    required bool persist,
    WindowSettingsFailure? loadFailure,
  }) async {
    WindowMode? previous;
    var failure = WindowSettingsFailure.apply;
    try {
      previous = await _window.readMode();
      if (_disposed) return;
      _publish(previous, null);
      await _setNativeMode(requested, previous);
      if (_disposed) return;
      if (persist) {
        failure = WindowSettingsFailure.save;
        await _store.save(requested);
      }
      _publish(requested, loadFailure);
    } on Object {
      if (_disposed) return;
      await _recover(previous, failure);
    }
  }

  Future<void> _setNativeMode(WindowMode requested, WindowMode current) async {
    if (requested == current) return;
    await _window.setMode(requested);
    if (!_disposed && await _window.readMode() != requested) {
      throw StateError('The native window did not reach the requested mode.');
    }
  }

  Future<void> _recover(
    WindowMode? previous,
    WindowSettingsFailure failure,
  ) async {
    var actual = previous ?? _settings.mode;
    if (previous != null) {
      try {
        await _window.setMode(previous);
        actual = await _window.readMode();
        if (actual != previous) failure = WindowSettingsFailure.restore;
      } on Object {
        failure = WindowSettingsFailure.restore;
        try {
          actual = await _window.readMode();
        } on Object {
          // Keep the last known mode with an explicit restoration failure.
        }
      }
    }
    _publish(actual, failure);
  }

  void _publish(WindowMode mode, WindowSettingsFailure? failure) {
    if (_disposed) return;
    _settings = WindowSettings(
      mode: mode,
      isBusy: _pending > 0,
      failure: failure,
    );
    _changes.add(_settings);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    unawaited(_changes.close());
  }
}
