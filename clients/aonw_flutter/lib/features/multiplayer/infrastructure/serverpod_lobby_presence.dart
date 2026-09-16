part of 'serverpod_multiplayer_session.dart';

Stream<MultiplayerMatchLobbyView> _watchRemoteLobby(
  ServerpodMultiplayerSession session,
  String matchId,
) async* {
  session._ensureAuthenticated();
  final userId = session._userId;
  try {
    await for (final value in session._client.game.watchLobby(matchId)) {
      session._ensureAuthenticated();
      if (session._userId != userId) {
        throw const MultiplayerSessionException(
          code: 'authentication_identity_changed',
          message: 'The account changed while observing the lobby.',
        );
      }
      final lobby = decodeServerLobby(value);
      if (lobby.match.matchId != matchId) {
        throw const FormatException(
          'The observed lobby changed match identity.',
        );
      }
      yield lobby;
    }
  } on Object catch (error, stackTrace) {
    throw _translate(error, stackTrace);
  }
}
