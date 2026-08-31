import 'dart:async';

import 'package:aonw_flutter/features/settings/application/client_settings.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_coordinator.dart';
import 'package:aonw_flutter/features/settings/application/client_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, updates and resets client-only preferences', () async {
    final stored = ClientSettings.defaults.copyWith(
      cameraSensitivity: 1.5,
      reducedMotion: true,
    );
    final store = _MemorySettingsStore(stored);
    final coordinator = ClientSettingsCoordinator(store: store);
    addTearDown(coordinator.dispose);

    await coordinator.load();
    expect(coordinator.settings, stored);

    final changed = stored.copyWith(masterVolume: 0.25, highContrast: true);
    await coordinator.update(changed);
    expect(coordinator.settings, changed);
    expect(store.settings, changed);

    await coordinator.reset();
    expect(coordinator.settings, ClientSettings.defaults);
    expect(store.settings, ClientSettings.defaults);
  });

  test('a late load never overwrites a newer user edit', () async {
    final load = Completer<ClientSettings>();
    final store = _DelayedSettingsStore(load.future);
    final coordinator = ClientSettingsCoordinator(store: store);
    addTearDown(coordinator.dispose);

    final pendingLoad = coordinator.load();
    final changed = ClientSettings.defaults.copyWith(masterVolume: 0.4);
    await coordinator.update(changed);
    load.complete(ClientSettings.defaults.copyWith(masterVolume: 0.9));
    await pendingLoad;

    expect(coordinator.settings, changed);
  });

  test('serializes concurrent writes and preserves their order', () async {
    final store = _ControlledSettingsStore();
    final coordinator = ClientSettingsCoordinator(store: store);
    addTearDown(coordinator.dispose);
    final first = ClientSettings.defaults.copyWith(masterVolume: 0.4);
    final second = ClientSettings.defaults.copyWith(masterVolume: 0.8);

    final firstWrite = coordinator.update(first);
    await store.firstStarted.future;
    final secondWrite = coordinator.update(second);
    await pumpEventQueue();

    expect(store.started, [first]);
    expect(coordinator.settings, second);

    store.firstCompleted.complete();
    await firstWrite;
    await store.secondStarted.future;
    expect(store.started, [first, second]);

    store.secondCompleted.complete();
    await secondWrite;
    expect(store.persisted, [first, second]);
  });
}

final class _MemorySettingsStore implements ClientSettingsStore {
  _MemorySettingsStore(this.settings);

  ClientSettings settings;

  @override
  Future<ClientSettings> load() async => settings;

  @override
  Future<void> save(ClientSettings settings) async {
    this.settings = settings;
  }
}

final class _DelayedSettingsStore implements ClientSettingsStore {
  _DelayedSettingsStore(this.loaded);

  final Future<ClientSettings> loaded;

  @override
  Future<ClientSettings> load() => loaded;

  @override
  Future<void> save(ClientSettings settings) async {}
}

final class _ControlledSettingsStore implements ClientSettingsStore {
  final firstStarted = Completer<void>();
  final firstCompleted = Completer<void>();
  final secondStarted = Completer<void>();
  final secondCompleted = Completer<void>();
  final started = <ClientSettings>[];
  final persisted = <ClientSettings>[];

  @override
  Future<ClientSettings> load() async => ClientSettings.defaults;

  @override
  Future<void> save(ClientSettings settings) async {
    started.add(settings);
    final index = started.length;
    if (index == 1) {
      firstStarted.complete();
      await firstCompleted.future;
    } else {
      secondStarted.complete();
      await secondCompleted.future;
    }
    persisted.add(settings);
  }
}
