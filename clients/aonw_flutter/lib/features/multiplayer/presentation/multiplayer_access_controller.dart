import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/multiplayer_access_port.dart';

enum MultiplayerAccessPhase { checking, current, updateRequired, unavailable }

final class MultiplayerAccessController extends ChangeNotifier {
  MultiplayerAccessController({
    required MultiplayerAccessPort access,
    Duration timeout = const Duration(seconds: 15),
  }) : _access = access,
       _timeout = timeout {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
  }

  final MultiplayerAccessPort _access;
  final Duration _timeout;
  var _phase = MultiplayerAccessPhase.checking;
  var _generation = 0;
  var _disposed = false;
  Future<void>? _initialization;

  MultiplayerAccessPhase get phase => _phase;

  bool get allowsConnection => _phase == MultiplayerAccessPhase.current;

  bool get updateRequired => _phase == MultiplayerAccessPhase.updateRequired;

  Future<void> initialize() => _initialization ??= _check();

  Future<void> retry() {
    _initialization = null;
    return initialize();
  }

  Future<void> _check() async {
    final generation = ++_generation;
    _setPhase(MultiplayerAccessPhase.checking);
    try {
      final status = await _access.check().timeout(_timeout);
      if (!_accepts(generation)) return;
      _setPhase(switch (status) {
        MultiplayerAccessStatus.current => MultiplayerAccessPhase.current,
        MultiplayerAccessStatus.updateRequired =>
          MultiplayerAccessPhase.updateRequired,
      });
    } on Object {
      if (_accepts(generation)) {
        _setPhase(MultiplayerAccessPhase.unavailable);
      }
    }
  }

  bool _accepts(int generation) => !_disposed && generation == _generation;

  void _setPhase(MultiplayerAccessPhase phase) {
    if (_disposed || phase == _phase) return;
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
