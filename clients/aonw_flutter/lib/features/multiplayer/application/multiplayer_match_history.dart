part of 'multiplayer_coordinator.dart';

extension MultiplayerMatchHistory on MultiplayerCoordinator {
  Future<MatchHistoryPageView> readMatchHistory({
    int? beforeParticipantId,
  }) async {
    if (_state is MultiplayerStarting) await initialize();
    final id = _profileUserId;
    final session = _session;
    if (_closed || id == null) {
      throw const MultiplayerSessionException(
        code: 'authentication_required',
        message: 'Authentication is required to access match history.',
      );
    }
    if (session is! MatchHistoryPort) {
      throw const MultiplayerSessionException(
        code: 'history_unavailable',
        message: 'Match history is unavailable.',
      );
    }
    final generation = _generation;
    final page = await (session as MatchHistoryPort).readMatchHistory(
      beforeParticipantId: beforeParticipantId,
    );
    if (!_isCurrent(generation) || _profileUserId != id || page.userId != id) {
      throw const MultiplayerSessionException(
        code: 'history_session_changed',
        message: 'The account changed during the history request.',
      );
    }
    return page;
  }
}
