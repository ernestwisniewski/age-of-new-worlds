part of 'serverpod_multiplayer_session.dart';

extension _ServerpodAccountAuthentication on ServerpodMultiplayerSession {
  MultiplayerAccountView _accountView(auth.AuthSuccess value) {
    final userId = value.authUserId.toString();
    if (userId.isEmpty || userId != _userId) {
      throw const MultiplayerSessionException(
        code: 'invalid_authentication_response',
        message: 'The restored account identity is invalid.',
      );
    }
    return MultiplayerAccountView(userId: userId);
  }

  Future<void> _clearCredentials() async {
    _authProvider.token = null;
    _refreshToken = null;
    _userId = null;
    await _tokenStore.clear();
  }
}

extension _SessionReconnection on ServerpodMultiplayerSession {
  Future<void> _reconnectAuthentication() async {
    _ensureOpen();
    final refreshToken = _refreshToken ?? await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const MultiplayerSessionException(
        code: 'authentication_required',
        message: 'The authenticated session is unavailable.',
      );
    }
    try {
      await _rotate(refreshToken);
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    }
  }
}
