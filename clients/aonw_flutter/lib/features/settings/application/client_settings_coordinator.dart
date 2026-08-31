import 'dart:async';

import 'client_settings.dart';
import 'client_settings_store.dart';

final class ClientSettingsCoordinator {
  ClientSettingsCoordinator({required ClientSettingsStore store})
    : _store = store;

  factory ClientSettingsCoordinator.ephemeral() =>
      ClientSettingsCoordinator(store: _EphemeralClientSettingsStore());

  final ClientSettingsStore _store;
  final StreamController<ClientSettings> _changes =
      StreamController<ClientSettings>.broadcast(sync: true);
  ClientSettings _settings = ClientSettings.defaults;
  Future<void> _writeTail = Future<void>.value();
  var _generation = 0;
  var _disposed = false;

  ClientSettings get settings => _settings;

  Stream<ClientSettings> get changes => _changes.stream;

  Future<void> load() async {
    final generation = _generation;
    final loaded = await _store.load();
    if (_disposed || generation != _generation || loaded == _settings) return;
    _settings = loaded;
    _changes.add(loaded);
  }

  Future<void> update(ClientSettings settings) async {
    if (_disposed || settings == _settings) return;
    _generation += 1;
    _settings = settings;
    _changes.add(settings);
    final write = _writeTail.then((_) => _store.save(settings));
    _writeTail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await write;
  }

  Future<void> reset() => update(ClientSettings.defaults);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_changes.close());
  }
}

final class _EphemeralClientSettingsStore implements ClientSettingsStore {
  var _settings = ClientSettings.defaults;

  @override
  Future<ClientSettings> load() async => _settings;

  @override
  Future<void> save(ClientSettings settings) async {
    _settings = settings;
  }
}
