part of 'serverpod_multiplayer_session.dart';

extension ServerpodMultiplayerReplay on ServerpodMultiplayerSession {
  ServerpodReplayTransport openReplayTransport({
    required String userId,
    required String matchId,
    required String playerId,
    required String mapHash,
    required String rulesetHash,
  }) {
    _ensureAuthenticated();
    final refreshToken = _refreshToken;
    void requireAuthorized() {
      _ensureAuthenticated();
      if (_userId != userId || _refreshToken != refreshToken) {
        throw const MultiplayerSessionException(
          code: 'replay_session_changed',
          message: 'The account changed during replay playback.',
        );
      }
    }

    requireAuthorized();
    final client = server.Client(
      _config.host,
      connectionTimeout: _config.requestTimeout,
    )..authKeyProvider = _FixedAccountAuthProvider(_authProvider.token!);
    return ServerpodReplayTransport(
      matchId: matchId,
      playerId: playerId,
      mapHash: mapHash,
      rulesetHash: rulesetHash,
      frame: (position) =>
          _gameRequest(() => client.game.replayFrame(matchId, position)),
      query: (request, position) =>
          _gameRequest(() => client.game.replayQuery(request, position)),
      requireAuthorized: requireAuthorized,
      release: client.close,
    );
  }
}
