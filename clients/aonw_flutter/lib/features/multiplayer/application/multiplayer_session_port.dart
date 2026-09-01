import '../read_model/multiplayer_view.dart';

abstract interface class MultiplayerSessionPort {
  Future<MultiplayerAccountView?> restoreAccount();

  Future<MultiplayerAccountView> signIn({
    required String email,
    required String password,
  });

  Future<MultiplayerAccountView> createAccount({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<void> reconnect();

  Future<List<MultiplayerMatchView>> listMatches();

  Future<MultiplayerMatchLobbyView> createMatch(
    MultiplayerMatchDocuments documents,
  );

  Future<MultiplayerMatchLobbyView> joinMatch({
    required String matchId,
    required String playerId,
  });

  Future<MultiplayerMatchLobbyView> lobby(String matchId);

  Future<MultiplayerMatchLobbyView> setReady({
    required String matchId,
    required bool ready,
  });

  Future<MultiplayerMatchLobbyView> startMatch(String matchId);

  Future<MultiplayerMatchView> leaveLobby(String matchId);

  Future<MultiplayerProjectionView> resync(String matchId);

  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  });

  Future<MultiplayerCommandView> kickParticipant({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  });

  Future<void> close();
}

final class MultiplayerSessionException implements Exception {
  const MultiplayerSessionException({
    required this.code,
    required this.message,
    this.retryable = false,
    this.diagnosticCause,
    this.diagnosticStackTrace,
  });

  final String code;
  final String message;
  final bool retryable;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;

  @override
  String toString() => 'MultiplayerSessionException($code): $message';
}

abstract interface class MultiplayerMatchDocumentSource {
  Future<MultiplayerMatchDocuments> load();
}
