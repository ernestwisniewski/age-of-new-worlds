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

  Future<MultiplayerProjectionView> createMatch(
    MultiplayerMatchDocuments documents,
  );

  Future<MultiplayerProjectionView> joinMatch({
    required String matchId,
    required String playerId,
  });

  Future<MultiplayerProjectionView> resync(String matchId);

  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
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
