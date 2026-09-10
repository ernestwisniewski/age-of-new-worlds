import 'package:aonw_flutter/features/multiplayer/infrastructure/serverpod_multiplayer_session.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as server;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = MatchHistoryMapper();
  test('history maps completed result and own membership metadata', () {
    final result = mapper.decode(_page(), 'account', null);
    expect(result.userId, 'account');
    expect(result.nextBeforeParticipantId, 42);
    final entry = result.entries.single;
    expect(entry.match.phase, MultiplayerMatchPhase.finished);
    expect(entry.playerId, 'player-1');
    expect(entry.turn, 40);
    expect(entry.outcomeCondition, 'resignation');
    expect(entry.winnerPlayerId, 'player-2');
    expect(entry.resignedAt, DateTime.utc(2026, 9, 12));
  });

  test('history rejects inconsistent pages and active matches', () {
    final page = _page();
    expect(() => mapper.decode(page, 'account', 42), throwsFormatException);
    for (final invalid in [
      page.copyWith(entries: []),
      page.copyWith(entries: [page.entries.single, page.entries.single]),
      page.copyWith(entries: [page.entries.single.copyWith(turn: 0)]),
      page.copyWith(entries: [page.entries.single.copyWith(playerId: '')]),
      page.copyWith(
        entries: [
          page.entries.single.copyWith(
            match: page.entries.single.match.copyWith(state: 'running'),
          ),
        ],
      ),
    ]) {
      expect(
        () => mapper.decode(invalid, 'account', null),
        throwsFormatException,
      );
    }
  });
}

server.GameMatchHistoryPage _page() => server.GameMatchHistoryPage(
  nextBeforeParticipantId: 42,
  entries: [
    server.GameMatchHistoryEntry(
      match: server.GameMatchView(
        matchId: 'match',
        mapId: 'map',
        mapHash: 'a' * 64,
        rulesetId: 'rules',
        rulesetHash: 'b' * 64,
        state: 'finished',
        startedAt: DateTime.utc(2026, 9, 1),
        revision: 120,
        eventOffset: 240,
      ),
      playerId: 'player-1',
      turn: 40,
      endedAt: DateTime.utc(2026, 9, 12),
      outcomeCondition: 'resignation',
      winnerPlayerId: 'player-2',
      resignedAt: DateTime.utc(2026, 9, 12),
    ),
  ],
);
