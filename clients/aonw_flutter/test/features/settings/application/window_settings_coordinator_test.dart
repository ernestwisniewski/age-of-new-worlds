import 'dart:async';

import 'package:aonw_flutter/features/settings/application/window_settings.dart';
import 'package:aonw_flutter/features/settings/application/window_settings_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup applies the saved mode without writing preferences', () async {
    final h = _Harness();
    await h.coordinator.load();
    expect(h.window.mode, WindowMode.fullscreen);
    expect(h.window.applied, [WindowMode.fullscreen]);
    expect(h.store.saved, isEmpty);
    h.store.mode = WindowMode.windowed;
    await h.coordinator.load();
    expect(h.window.mode, WindowMode.windowed);
    expect(h.coordinator.settings.mode, WindowMode.windowed);
    expect(h.coordinator.settings.isBusy, isFalse);
  });

  test(
    'an explicit default selection supersedes a delayed stored choice',
    () async {
      final h = _Harness();
      final loaded = Completer<WindowMode>();
      h.store.onLoad = () => loaded.future;
      final loading = h.coordinator.load();
      await pumpEventQueue();
      expect(h.store.loads, 1);
      await h.coordinator.setMode(WindowMode.fullscreen);
      loaded.complete(WindowMode.windowed);
      await loading;
      expect(h.window.applied, [WindowMode.fullscreen]);
      expect(h.store.saved, [WindowMode.fullscreen]);
      expect(h.coordinator.settings.mode, WindowMode.fullscreen);
    },
  );

  test(
    'a reload waits for a pending save before reading preferences',
    () async {
      final h = _Harness();
      final entered = Completer<void>();
      final release = Completer<void>();
      h.store.onSave = (_) async {
        entered.complete();
        await release.future;
      };
      final changing = h.coordinator.setMode(WindowMode.windowed);
      await entered.future;
      final loading = h.coordinator.load();
      expect(h.store.loads, 0);
      release.complete();
      await Future.wait([changing, loading]);
      expect(h.window.mode, WindowMode.windowed);
      expect(h.coordinator.settings.mode, WindowMode.windowed);
      expect(h.window.applied, isEmpty);
    },
  );

  test('only the latest startup load may apply its result', () async {
    final h = _Harness();
    final first = Completer<WindowMode>();
    h.store.onLoad = () => first.future;
    final loading = h.coordinator.load();
    await pumpEventQueue();
    expect(h.store.loads, 1);
    h.store.onLoad = null;
    h.store.mode = WindowMode.windowed;
    await h.coordinator.load();
    first.complete(WindowMode.fullscreen);
    await loading;
    expect(h.window.mode, WindowMode.windowed);
    expect(h.window.applied, isEmpty);
  });

  test(
    'serializes transitions and saves only after native confirmation',
    () async {
      final h = _Harness();
      final entered = Completer<void>();
      final release = Completer<void>();
      h.window.onSet = (mode) async {
        if (!entered.isCompleted) {
          entered.complete();
          await release.future;
        }
        h.window.mode = mode;
      };
      final first = h.coordinator.setMode(WindowMode.fullscreen);
      await entered.future;
      final second = h.coordinator.setMode(WindowMode.windowed);
      expect(h.coordinator.settings.isBusy, isTrue);
      expect(h.coordinator.settings.mode, WindowMode.windowed);
      expect(h.window.applied, [WindowMode.fullscreen]);
      expect(h.store.saved, isEmpty);
      release.complete();
      await Future.wait([first, second]);
      expect(h.window.applied, [WindowMode.fullscreen, WindowMode.windowed]);
      expect(h.store.saved, [WindowMode.fullscreen, WindowMode.windowed]);
      expect(h.coordinator.settings.mode, WindowMode.windowed);
      expect(h.coordinator.settings.isBusy, isFalse);
    },
  );

  test(
    'a failed native transition restores the actual prior window mode',
    () async {
      final h = _Harness();
      h.window.onSet = (mode) async {
        h.window.mode = mode;
        if (mode == WindowMode.fullscreen) throw StateError('native failure');
      };
      await h.coordinator.setMode(WindowMode.fullscreen);
      expect(h.window.mode, WindowMode.windowed);
      expect(h.window.applied, [WindowMode.fullscreen, WindowMode.windowed]);
      expect(h.store.saved, isEmpty);
      expect(h.coordinator.settings.mode, WindowMode.windowed);
      expect(h.coordinator.settings.failure, WindowSettingsFailure.apply);
    },
  );

  test(
    'a write failure rolls back and does not poison the next edit',
    () async {
      final h = _Harness();
      h.store.onSave = (_) async => throw StateError('write failure');
      await h.coordinator.setMode(WindowMode.fullscreen);
      expect(h.window.mode, WindowMode.windowed);
      expect(h.coordinator.settings.failure, WindowSettingsFailure.save);
      h.store.onSave = null;
      await h.coordinator.setMode(WindowMode.fullscreen);
      expect(h.window.mode, WindowMode.fullscreen);
      expect(h.store.mode, WindowMode.fullscreen);
      expect(h.coordinator.settings.failure, isNull);
    },
  );

  test(
    'failed rollback reports restoration failure and the actual mode',
    () async {
      final h = _Harness();
      h.store.onSave = (_) async => throw StateError('write failure');
      h.window.onSet = (mode) async {
        if (mode == WindowMode.windowed) throw StateError('rollback failure');
        h.window.mode = mode;
      };
      await h.coordinator.setMode(WindowMode.fullscreen);
      expect(h.window.mode, WindowMode.fullscreen);
      expect(h.coordinator.settings.mode, WindowMode.fullscreen);
      expect(h.coordinator.settings.failure, WindowSettingsFailure.restore);
      expect(h.coordinator.settings.isBusy, isFalse);
    },
  );

  test('an unconfirmed native change is rejected and never saved', () async {
    final h = _Harness();
    h.window.onSet = (_) async {};
    await h.coordinator.setMode(WindowMode.fullscreen);
    expect(h.store.saved, isEmpty);
    expect(h.coordinator.settings.mode, WindowMode.windowed);
    expect(h.coordinator.settings.failure, WindowSettingsFailure.apply);
  });

  test(
    'a failed initial native read does not mutate the window or store',
    () async {
      final h = _Harness();
      h.window.failRead = true;
      await h.coordinator.setMode(WindowMode.windowed);
      expect(h.window.applied, isEmpty);
      expect(h.store.saved, isEmpty);
      expect(h.coordinator.settings.failure, WindowSettingsFailure.apply);
    },
  );

  test(
    'load failure applies the default and remains visible until retry',
    () async {
      final h = _Harness();
      h.store.onLoad = () async => throw StateError('read failure');
      await h.coordinator.load();
      expect(h.window.mode, WindowMode.fullscreen);
      expect(h.store.saved, isEmpty);
      expect(h.coordinator.settings.failure, WindowSettingsFailure.load);
      h.store.onLoad = null;
      await h.coordinator.load();
      expect(h.coordinator.settings.failure, isNull);
    },
  );

  test(
    'unsupported platforms perform no preference or native operations',
    () async {
      final h = _Harness();
      h.window.isSupported = false;
      await h.coordinator.load();
      await h.coordinator.setMode(WindowMode.windowed);
      await h.coordinator.reset();
      expect(h.store.loads, 0);
      expect(h.store.saved, isEmpty);
      expect(h.window.reads, 0);
      expect(h.window.applied, isEmpty);
      expect(h.coordinator.settings.isBusy, isFalse);
    },
  );

  test(
    'reset waits for the pending choice and then restores fullscreen',
    () async {
      final h = _Harness();
      final entered = Completer<void>();
      final release = Completer<void>();
      h.store.onSave = (_) async {
        if (!entered.isCompleted) {
          entered.complete();
          await release.future;
        }
      };
      final change = h.coordinator.setMode(WindowMode.windowed);
      await entered.future;
      final reset = h.coordinator.reset();
      release.complete();
      await Future.wait([change, reset]);
      expect(h.store.saved, [WindowMode.windowed, WindowMode.fullscreen]);
      expect(h.window.mode, WindowMode.fullscreen);
      expect(h.coordinator.settings.mode, WindowMode.fullscreen);
    },
  );

  test(
    'dispose suppresses late saves, notifications and queued transitions',
    () async {
      final h = _Harness();
      final entered = Completer<void>();
      final release = Completer<void>();
      h.window.onSet = (mode) async {
        entered.complete();
        await release.future;
        h.window.mode = mode;
      };
      final states = <WindowSettings>[];
      h.coordinator.changes.listen(states.add);
      final applying = h.coordinator.setMode(WindowMode.fullscreen);
      await entered.future;
      final queued = h.coordinator.setMode(WindowMode.windowed);
      h.coordinator.dispose();
      final count = states.length;
      release.complete();
      await Future.wait([applying, queued]);
      expect(h.store.saved, isEmpty);
      expect(h.window.applied, [WindowMode.fullscreen]);
      expect(states, hasLength(count));
    },
  );
}

final class _Harness {
  _Harness() {
    coordinator = WindowSettingsCoordinator(window: window, store: store);
    addTearDown(coordinator.dispose);
  }

  final window = _Window();
  final store = _Store();
  late final WindowSettingsCoordinator coordinator;
}

final class _Window implements GameWindowPort {
  @override
  bool isSupported = true;
  var mode = WindowMode.windowed;
  var reads = 0;
  var failRead = false;
  final applied = <WindowMode>[];
  Future<void> Function(WindowMode)? onSet;

  @override
  Future<WindowMode> readMode() async {
    reads += 1;
    if (failRead) throw StateError('read failure');
    return mode;
  }

  @override
  Future<void> setMode(WindowMode value) async {
    applied.add(value);
    if (onSet case final apply?) {
      await apply(value);
    } else {
      mode = value;
    }
  }
}

final class _Store implements WindowSettingsStore {
  var mode = WindowMode.fullscreen;
  var loads = 0;
  final saved = <WindowMode>[];
  Future<WindowMode> Function()? onLoad;
  Future<void> Function(WindowMode)? onSave;

  @override
  Future<WindowMode> load() async {
    loads += 1;
    return onLoad == null ? mode : await onLoad!();
  }

  @override
  Future<void> save(WindowMode value) async {
    await onSave?.call(value);
    saved.add(value);
    mode = value;
  }
}
