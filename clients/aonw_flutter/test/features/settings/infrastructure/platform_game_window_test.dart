import 'dart:async';

import 'package:aonw_flutter/features/settings/application/window_settings.dart';
import 'package:aonw_flutter/features/settings/infrastructure/platform_game_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  test(
    'macOS waits for completion rather than the method acknowledgement',
    () async {
      final manager = _Manager();
      final window = PlatformGameWindow(
        manager: manager,
        platform: TargetPlatform.macOS,
      );
      var completed = false;
      final changing = window
          .setMode(WindowMode.fullscreen)
          .then((_) => completed = true);
      await pumpEventQueue();
      expect(manager.fullscreen, isTrue);
      expect(completed, isFalse);
      manager.leave();
      await pumpEventQueue();
      expect(completed, isFalse);
      manager.enter();
      await changing;
      expect(completed, isTrue);
      expect(manager.listeners, isEmpty);
      expect(manager.initializations, 1);
    },
  );

  test(
    'synchronous native events are not lost and both directions work',
    () async {
      final manager = _Manager()..emitOnSet = true;
      final window = PlatformGameWindow(
        manager: manager,
        platform: TargetPlatform.macOS,
      );
      await window.setMode(WindowMode.fullscreen);
      expect(await window.readMode(), WindowMode.fullscreen);
      await window.setMode(WindowMode.windowed);
      expect(await window.readMode(), WindowMode.windowed);
      expect(manager.listeners, isEmpty);
      expect(manager.initializations, 1);
    },
  );

  test('missing completion times out and releases the listener', () async {
    final manager = _Manager();
    final window = PlatformGameWindow(
      manager: manager,
      platform: TargetPlatform.macOS,
      transitionTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      window.setMode(WindowMode.fullscreen),
      throwsA(isA<TimeoutException>()),
    );
    expect(manager.listeners, isEmpty);
  });

  test(
    'a rejected transition releases the listener and can be retried',
    () async {
      final manager = _Manager()..failSet = true;
      final window = PlatformGameWindow(
        manager: manager,
        platform: TargetPlatform.macOS,
      );
      await expectLater(
        window.setMode(WindowMode.fullscreen),
        throwsStateError,
      );
      expect(manager.listeners, isEmpty);
      manager.failSet = false;
      manager.emitOnSet = true;
      await window.setMode(WindowMode.fullscreen);
      expect(await window.readMode(), WindowMode.fullscreen);
    },
  );

  test(
    'an event cannot substitute for confirmation of the actual mode',
    () async {
      final manager = _Manager()
        ..emitOnSet = true
        ..ignoreSet = true;
      final window = PlatformGameWindow(
        manager: manager,
        platform: TargetPlatform.macOS,
      );
      await expectLater(
        window.setMode(WindowMode.fullscreen),
        throwsStateError,
      );
      expect(manager.listeners, isEmpty);
    },
  );

  test(
    'failed initialization is retried and a matching mode is left alone',
    () async {
      final manager = _Manager()..failInitialize = true;
      final window = PlatformGameWindow(
        manager: manager,
        platform: TargetPlatform.macOS,
      );
      await expectLater(window.readMode(), throwsStateError);
      manager.failInitialize = false;
      await window.setMode(WindowMode.windowed);
      expect(manager.setCalls, 0);
      expect(manager.initializations, 2);
    },
  );

  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    test('$platform confirms native state even without an event', () async {
      final manager = _Manager();
      final window = PlatformGameWindow(manager: manager, platform: platform);
      await window.setMode(WindowMode.fullscreen);
      expect(await window.readMode(), WindowMode.fullscreen);
      expect(manager.listeners, isEmpty);
    });
  }

  test('mobile and web do not call native window APIs', () async {
    for (final (platform, web) in [
      (TargetPlatform.android, false),
      (TargetPlatform.iOS, false),
      (TargetPlatform.macOS, true),
    ]) {
      final manager = _Manager();
      final window = PlatformGameWindow(
        manager: manager,
        platform: platform,
        isWeb: web,
      );
      expect(window.isSupported, isFalse);
      await expectLater(window.readMode(), throwsUnsupportedError);
      expect(manager.initializations, 0);
    }
  });
}

final class _Manager extends Fake implements WindowManager {
  var fullscreen = false;
  var emitOnSet = false;
  var ignoreSet = false;
  var failSet = false;
  var failInitialize = false;
  var initializations = 0;
  var setCalls = 0;
  @override
  final listeners = <WindowListener>[];

  @override
  Future<void> ensureInitialized() async {
    initializations += 1;
    if (failInitialize) throw StateError('initialization failure');
  }

  @override
  Future<bool> isFullScreen() async => fullscreen;

  @override
  Future<void> setFullScreen(bool value) async {
    setCalls += 1;
    if (failSet) throw StateError('transition failure');
    if (!ignoreSet) fullscreen = value;
    if (emitOnSet) value ? enter() : leave();
  }

  @override
  void addListener(WindowListener listener) => listeners.add(listener);

  @override
  void removeListener(WindowListener listener) => listeners.remove(listener);

  void enter() {
    for (final listener in List.of(listeners)) {
      listener.onWindowEnterFullScreen();
    }
  }

  void leave() {
    for (final listener in List.of(listeners)) {
      listener.onWindowLeaveFullScreen();
    }
  }
}
