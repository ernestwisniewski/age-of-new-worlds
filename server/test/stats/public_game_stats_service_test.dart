import 'dart:convert';

import 'package:aonw_server/src/stats/public_game_stats_service.dart';
import 'package:aonw_server/src/stats/public_game_stats_store.dart';
import 'package:test/test.dart';

void main() {
  test('builds the stable public contract and caches one UTC window', () async {
    var now = DateTime.utc(2026, 7, 12, 14, 30);
    final store = _FakeStatsStore(
      overview: const PublicGameStatsOverview(
        activeSessions: 3,
        openLobbies: 0,
        matchesStarted: 11,
        matchesCompleted: 7,
        matchesAbandoned: 1,
        averageCompletedTurns: 42.5,
        longestCompletedTurns: 121,
        totalPlayedTurns: 378,
        completedTurnDistribution: {
          '1–10': 1,
          '11–25': 2,
          '26–50': 3,
          '51–100': 0,
          '101+': 1,
        },
      ),
      activity: [
        PublicGameDailyActivity(
          date: DateTime.utc(2026, 6, 13),
          started: 2,
          completed: 1,
        ),
        PublicGameDailyActivity(
          date: DateTime.utc(2026, 7, 12),
          started: 1,
          completed: 0,
        ),
      ],
      outcomes: const [
        PublicGameStoredOutcome(condition: 'conquest', count: 4),
        PublicGameStoredOutcome(condition: 'internal-alpha', count: 2),
        PublicGameStoredOutcome(condition: 'internal-beta', count: 3),
      ],
    );
    final service = PublicGameStatsService(nowUtc: () => now);

    final stats = await service.snapshot(store);
    final json = stats.toJson();
    final activity = json['activity']! as List<Object?>;
    final outcomes = json['outcomes']! as List<Object?>;

    expect(json['schemaVersion'], 1);
    expect(json['generatedAt'], '2026-07-12T14:30:00.000Z');
    expect(activity, hasLength(30));
    expect(activity.first, {
      'date': '2026-06-13',
      'started': 2,
      'completed': 1,
    });
    expect(activity[1], {'date': '2026-06-14', 'started': 0, 'completed': 0});
    expect(activity.last, {'date': '2026-07-12', 'started': 1, 'completed': 0});
    expect(outcomes, [
      {'condition': 'conquest', 'count': 4},
      {'condition': 'domination', 'count': 0},
      {'condition': 'cultural', 'count': 0},
      {'condition': 'score', 'count': 0},
      {'condition': 'draw', 'count': 0},
      {'condition': 'resignation', 'count': 0},
      {'condition': 'unknown', 'count': 5},
    ]);
    expect(jsonEncode(json), isNot(contains('internal-')));

    final cached = await service.snapshot(store);
    expect(identical(stats, cached), isTrue);
    expect(store.snapshotLoads, 1);

    now = now.add(const Duration(seconds: 31));
    await service.snapshot(store);
    expect(store.snapshotLoads, 2);
  });

  test('empty storage still returns every chart category', () async {
    final store = _FakeStatsStore(
      overview: const PublicGameStatsOverview(
        activeSessions: 0,
        openLobbies: 0,
        matchesStarted: 0,
        matchesCompleted: 0,
        matchesAbandoned: 0,
        averageCompletedTurns: 0,
        longestCompletedTurns: 0,
        totalPlayedTurns: 0,
        completedTurnDistribution: {},
      ),
      activity: const [],
      outcomes: const [],
    );

    final stats = await PublicGameStatsService(
      nowUtc: () => DateTime.utc(2026, 7, 12),
    ).snapshot(store);

    expect(stats.activity, hasLength(30));
    expect(stats.activity.every((point) => point.started == 0), isTrue);
    expect(stats.activity.every((point) => point.completed == 0), isTrue);
    expect(stats.outcomes.map((outcome) => outcome.condition), [
      'conquest',
      'domination',
      'cultural',
      'score',
      'draw',
      'resignation',
    ]);
  });
}

final class _FakeStatsStore implements PublicGameStatsStore {
  _FakeStatsStore({
    required this.overview,
    required this.activity,
    required this.outcomes,
  });

  final PublicGameStatsOverview overview;
  final List<PublicGameDailyActivity> activity;
  final List<PublicGameStoredOutcome> outcomes;
  int snapshotLoads = 0;

  @override
  Future<PublicGameStoredSnapshot> loadSnapshot({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    snapshotLoads += 1;
    expect(startInclusive, DateTime.utc(2026, 6, 13));
    expect(endExclusive, DateTime.utc(2026, 7, 13));
    return PublicGameStoredSnapshot(
      overview: overview,
      activity: activity,
      outcomes: outcomes,
    );
  }
}
