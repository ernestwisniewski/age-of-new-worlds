import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import '../application/window_settings.dart';

final class PlatformGameWindow implements GameWindowPort {
  PlatformGameWindow({
    WindowManager? manager,
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
    this.transitionTimeout = const Duration(seconds: 10),
  }) : _manager = manager ?? windowManager,
       _platform = platform ?? defaultTargetPlatform,
       _isWeb = isWeb;

  final WindowManager _manager;
  final TargetPlatform _platform;
  final bool _isWeb;
  final Duration transitionTimeout;
  Future<void>? _initialized;

  @override
  bool get isSupported =>
      !_isWeb &&
      const {
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }.contains(_platform);

  Future<void> _ready() async {
    if (!isSupported) throw UnsupportedError('Window modes are unavailable.');
    try {
      await (_initialized ??= _manager.ensureInitialized()).timeout(
        transitionTimeout,
      );
    } on Object {
      _initialized = null;
      rethrow;
    }
  }

  @override
  Future<WindowMode> readMode() async {
    await _ready();
    return await _manager.isFullScreen().timeout(transitionTimeout)
        ? WindowMode.fullscreen
        : WindowMode.windowed;
  }

  @override
  Future<void> setMode(WindowMode mode) async {
    if (await readMode() == mode) return;
    final transition = _WindowTransition(mode);
    _manager.addListener(transition);
    try {
      await _manager
          .setFullScreen(mode == WindowMode.fullscreen)
          .timeout(transitionTimeout);
      if (_platform == TargetPlatform.macOS) {
        await transition.finished.future.timeout(transitionTimeout);
      } else {
        await _waitForMode(mode);
      }
      if (await readMode() != mode) {
        throw StateError('Native window transition ended in a different mode.');
      }
    } finally {
      _manager.removeListener(transition);
    }
  }

  Future<void> _waitForMode(WindowMode mode) async {
    final timer = Stopwatch()..start();
    while (await readMode() != mode) {
      if (timer.elapsed >= transitionTimeout) {
        throw TimeoutException('Window mode transition timed out.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }
}

final class _WindowTransition with WindowListener {
  _WindowTransition(this.mode);

  final WindowMode mode;
  final finished = Completer<void>();

  void _complete(WindowMode observed) {
    if (mode == observed && !finished.isCompleted) finished.complete();
  }

  @override
  void onWindowEnterFullScreen() => _complete(WindowMode.fullscreen);

  @override
  void onWindowLeaveFullScreen() => _complete(WindowMode.windowed);
}
