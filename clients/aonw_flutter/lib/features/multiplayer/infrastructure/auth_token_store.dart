import 'package:flutter/services.dart';

abstract interface class AuthTokenStore {
  Future<String?> readRefreshToken();

  Future<void> writeRefreshToken(String value);

  Future<void> clear();
}

final class SecureAuthTokenStore implements AuthTokenStore {
  const SecureAuthTokenStore({
    MethodChannel channel = const MethodChannel('aonw/keychain'),
    String refreshTokenKey = 'aonw.auth.refresh-token',
  }) : _channel = channel,
       _refreshTokenKey = refreshTokenKey,
       assert(refreshTokenKey != '');

  final MethodChannel _channel;
  final String _refreshTokenKey;

  @override
  Future<String?> readRefreshToken() =>
      _channel.invokeMethod<String>('read', {'key': _refreshTokenKey});

  @override
  Future<void> writeRefreshToken(String value) {
    if (value.isEmpty || value.length > 16 * 1024) {
      throw ArgumentError.value(value.length, 'value.length');
    }
    return _channel.invokeMethod<void>('write', {
      'key': _refreshTokenKey,
      'value': value,
    });
  }

  @override
  Future<void> clear() =>
      _channel.invokeMethod<void>('delete', {'key': _refreshTokenKey});
}
