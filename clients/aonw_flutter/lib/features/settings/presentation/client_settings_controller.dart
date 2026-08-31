import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/client_settings.dart';
import '../application/client_settings_coordinator.dart';
import '../application/client_settings_store.dart';

final class ClientSettingsController extends ChangeNotifier {
  ClientSettingsController({required ClientSettingsStore store})
    : this.fromCoordinator(ClientSettingsCoordinator(store: store));

  ClientSettingsController.fromCoordinator(this._coordinator) {
    _subscription = _coordinator.changes.listen((_) => notifyListeners());
  }

  factory ClientSettingsController.ephemeral() =>
      ClientSettingsController.fromCoordinator(
        ClientSettingsCoordinator.ephemeral(),
      );

  final ClientSettingsCoordinator _coordinator;
  late final StreamSubscription<ClientSettings> _subscription;
  var _disposed = false;

  ClientSettings get settings => _coordinator.settings;

  Future<void> load() => _coordinator.load();

  Future<void> update(ClientSettings settings) => _coordinator.update(settings);

  Future<void> reset() => _coordinator.reset();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    _coordinator.dispose();
    super.dispose();
  }
}
