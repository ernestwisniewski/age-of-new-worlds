import 'dart:async';

import 'package:aonw_flutter/features/multiplayer/application/match_history_port.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';

final class HistoryPort implements MatchHistoryPort {
  Object? failure;
  String userId = 'account';
  bool replayAvailable = false;
  Completer<MatchHistoryPageView>? pending;
  final cursors = <int?>[];

  @override
  Future<MatchHistoryPageView> readMatchHistory({
    int? beforeParticipantId,
  }) async {
    cursors.add(beforeParticipantId);
    if (failure case final error?) throw error;
    return pending?.future ??
        historyPage(
          userId: userId,
          second: beforeParticipantId != null,
          replayAvailable: replayAvailable,
        );
  }
}

MatchHistoryPageView historyPage({
  String userId = 'account',
  bool second = false,
  bool replayAvailable = false,
}) => MatchHistoryPageView(
  userId: userId,
  nextBeforeParticipantId: second ? null : 42,
  entries: [
    MatchHistoryEntryView(
      match: MultiplayerMatchView(
        matchId: second ? 'match-second' : 'match-first',
        mapId: 'Dravonia',
        mapHash: 'a' * 64,
        rulesetId: 'rules',
        rulesetHash: 'b' * 64,
        phase: MultiplayerMatchPhase.finished,
        hostPlayerId: 'player-1',
        startedAt: DateTime.utc(2026, 9, 1),
        revision: 120,
        eventOffset: 240,
      ),
      playerId: 'player-1',
      turn: 40,
      replayAvailable: replayAvailable,
      endedAt: DateTime(2026, 9, 12),
      outcomeCondition: 'resignation',
      winnerPlayerId: second ? 'player-1' : 'player-2',
      resignedAt: second ? null : DateTime(2026, 9, 12),
    ),
  ],
);
