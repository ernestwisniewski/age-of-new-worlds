part of 'serverpod_multiplayer_session.dart';

extension _ServerpodAccountProfile on ServerpodMultiplayerSession {
  Future<AccountProfileView> _profileRequest(
    Future<String> Function(server.Client) request,
  ) async {
    _ensureAuthenticated();
    final userId = _userId!;
    final refreshToken = _refreshToken;
    final client = server.Client(
      _config.host,
      connectionTimeout: _config.requestTimeout,
    )..authKeyProvider = _FixedAccountAuthProvider(_authProvider.token!);
    try {
      final name = await request(client);
      _ensureAuthenticated();
      if (_userId != userId || _refreshToken != refreshToken) {
        throw const MultiplayerSessionException(
          code: 'profile_session_changed',
          message: 'The account changed during the profile request.',
        );
      }
      if (name.trim().isEmpty) {
        throw const MultiplayerSessionException(
          code: 'invalid_profile_response',
          message: 'The profile response has no display name.',
        );
      }
      return AccountProfileView(userId: userId, displayName: name);
    } on Object catch (error, stackTrace) {
      if (error is server.AccountAuthException) {
        throw MultiplayerSessionException(
          code: error.code,
          message: error.message ?? 'The profile request was rejected.',
          diagnosticCause: error,
          diagnosticStackTrace: stackTrace,
        );
      }
      throw _translate(error, stackTrace);
    } finally {
      client.close();
    }
  }
}

final class _FixedAccountAuthProvider implements server.ClientAuthKeyProvider {
  _FixedAccountAuthProvider(String token)
    : _header = server.wrapAsBearerAuthHeaderValue(token);
  final String _header;
  @override
  Future<String?> get authHeaderValue async => _header;
}
