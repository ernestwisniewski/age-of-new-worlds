import '../read_model/multiplayer_view.dart';

final class MatchHistoryEntryView {
  const MatchHistoryEntryView({
    required this.match,
    required this.playerId,
    required this.turn,
    this.endedAt,
    this.outcomeCondition,
    this.winnerPlayerId,
    this.resignedAt,
    this.kickedAt,
    this.replayAvailable = false,
  });

  final MultiplayerMatchView match;
  final String playerId;
  final int turn;
  final DateTime? endedAt;
  final String? outcomeCondition;
  final String? winnerPlayerId;
  final DateTime? resignedAt;
  final DateTime? kickedAt;
  final bool replayAvailable;
}

final class MatchHistoryPageView {
  MatchHistoryPageView({
    required this.userId,
    required List<MatchHistoryEntryView> entries,
    this.nextBeforeParticipantId,
  }) : entries = List.unmodifiable(entries);

  final String userId;
  final List<MatchHistoryEntryView> entries;
  final int? nextBeforeParticipantId;
}

abstract interface class MatchHistoryPort {
  Future<MatchHistoryPageView> readMatchHistory({int? beforeParticipantId});
}
