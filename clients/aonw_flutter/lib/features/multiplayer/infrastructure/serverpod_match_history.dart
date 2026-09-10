part of 'serverpod_multiplayer_session.dart';

extension _ServerpodMatchHistory on ServerpodMultiplayerSession {
  Future<MatchHistoryPageView> _readMatchHistory(int? before) async {
    _ensureAuthenticated();
    final userId = _userId!;
    final refreshToken = _refreshToken;
    final client = server.Client(
      _config.host,
      connectionTimeout: _config.requestTimeout,
    )..authKeyProvider = _FixedAccountAuthProvider(_authProvider.token!);
    try {
      final result = await client.game.matchHistory(
        beforeParticipantId: before,
      );
      _ensureAuthenticated();
      if (_userId != userId || _refreshToken != refreshToken) {
        throw const MultiplayerSessionException(
          code: 'history_session_changed',
          message: 'The account changed during the history request.',
        );
      }
      return const MatchHistoryMapper().decode(result, userId, before);
    } on Object catch (error, stackTrace) {
      throw _translate(error, stackTrace);
    } finally {
      client.close();
    }
  }
}

final class MatchHistoryMapper {
  const MatchHistoryMapper();

  MatchHistoryPageView decode(
    server.GameMatchHistoryPage value,
    String userId,
    int? before,
  ) {
    final next = value.nextBeforeParticipantId;
    if (value.entries.length > 50 ||
        value.entries.map((entry) => entry.match.matchId).toSet().length !=
            value.entries.length ||
        next != null &&
            (value.entries.isEmpty ||
                next < 1 ||
                before != null && next >= before)) {
      throw const FormatException('The history page is inconsistent.');
    }
    return MatchHistoryPageView(
      userId: userId,
      nextBeforeParticipantId: next,
      entries: [for (final entry in value.entries) _decodeHistoryEntry(entry)],
    );
  }
}

MatchHistoryEntryView _decodeHistoryEntry(server.GameMatchHistoryEntry value) {
  final match = _decodeMatch(value.match);
  if (match.phase != MultiplayerMatchPhase.finished ||
      value.turn < 1 ||
      value.playerId.trim().isEmpty) {
    throw const FormatException('The history entry is not a completed match.');
  }
  return MatchHistoryEntryView(
    match: match,
    playerId: value.playerId,
    turn: value.turn,
    endedAt: value.endedAt,
    outcomeCondition: value.outcomeCondition,
    winnerPlayerId: value.winnerPlayerId,
    resignedAt: value.resignedAt,
    kickedAt: value.kickedAt,
    replayAvailable: value.replayAvailable,
  );
}
