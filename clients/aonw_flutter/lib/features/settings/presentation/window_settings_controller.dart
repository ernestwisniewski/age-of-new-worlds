import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/window_settings.dart';
import '../application/window_settings_coordinator.dart';

final class WindowSettingsController extends ChangeNotifier {
  WindowSettingsController(this._coordinator) {
    _subscription = _coordinator.changes.listen((_) => notifyListeners());
  }

  final WindowSettingsCoordinator _coordinator;
  late final StreamSubscription<WindowSettings> _subscription;
  var _disposed = false;

  bool get isSupported => _coordinator.isSupported;
  WindowSettings get settings => _coordinator.settings;
  Future<void> load() => _coordinator.load();
  Future<void> setMode(WindowMode mode) => _coordinator.setMode(mode);
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
