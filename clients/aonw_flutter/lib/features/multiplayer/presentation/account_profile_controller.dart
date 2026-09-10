import 'package:flutter/foundation.dart';

import '../application/account_profile_port.dart';
import '../application/multiplayer_session_port.dart';

final class AccountProfileController extends ChangeNotifier {
  AccountProfileController(this._port);

  final AccountProfilePort _port;
  AccountProfileView? profile;
  String? failureCode;
  bool busy = false;
  bool saved = false;
  int _generation = 0;
  bool _disposed = false;

  Future<void> load() => _request(_port.readProfile, saving: false);

  Future<void> save(String name) {
    if (profile == null) return Future.value();
    return _request(() => _port.updateDisplayName(name), saving: true);
  }

  void invalidate() {
    _generation++;
    profile = null;
    failureCode = null;
    busy = false;
    saved = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> _request(
    Future<AccountProfileView> Function() operation, {
    required bool saving,
  }) async {
    if (_disposed || busy) return;
    final generation = ++_generation;
    final before = profile;
    busy = true;
    saved = false;
    failureCode = null;
    notifyListeners();
    try {
      final result = await operation();
      if (!_isCurrent(generation)) return;
      if (saving && result.userId != before?.userId) {
        throw const MultiplayerSessionException(
          code: 'profile_session_changed',
          message: 'The profile account changed.',
        );
      }
      profile = result;
      saved = saving;
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      failureCode = _failureCode(error);
    } finally {
      if (_isCurrent(generation)) {
        busy = false;
        notifyListeners();
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

String _failureCode(Object error) =>
    error is MultiplayerSessionException ? error.code : 'profile_unavailable';
