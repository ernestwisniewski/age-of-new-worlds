import 'package:aonw_server/src/stats/public_game_stats.dart';
import 'package:aonw_server/src/stats/public_game_stats_store.dart';

const publicGameStatsWindowDays = 30;
const publicGameStatsCacheTtl = Duration(seconds: 30);

final class PublicGameStatsService {
  PublicGameStatsService({
    DateTime Function()? nowUtc,
    this.windowDays = publicGameStatsWindowDays,
    this.cacheTtl = publicGameStatsCacheTtl,
  }) : _nowUtc = nowUtc ?? _systemNowUtc;

  static const _outcomeConditions = [
    'conquest',
    'domination',
    'cultural',
    'score',
    'draw',
    'resignation',
  ];
  static const _turnDistributionLabels = [
    '1–10',
    '11–25',
    '26–50',
    '51–100',
    '101+',
  ];

  final DateTime Function() _nowUtc;
  final int windowDays;
  final Duration cacheTtl;
  Future<PublicGameStats>? _cached;
  DateTime? _cachedAt;

  Future<PublicGameStats> snapshot(PublicGameStatsStore store) {
    final now = _nowUtc().toUtc();
    final cached = _cached;
    final cachedAt = _cachedAt;
    if (cached != null &&
        cachedAt != null &&
        now.difference(cachedAt) < cacheTtl) {
      return cached;
    }
    final next = _loadAndResetOnFailure(store, now);
    _cached = next;
    _cachedAt = now;
    return next;
  }

  Future<PublicGameStats> _loadAndResetOnFailure(
    PublicGameStatsStore store,
    DateTime generatedAt,
  ) async {
    try {
      return await _load(store, generatedAt);
    } catch (_) {
      if (_cachedAt == generatedAt) {
        _cached = null;
        _cachedAt = null;
      }
      rethrow;
    }
  }

  Future<PublicGameStats> _load(
    PublicGameStatsStore store,
    DateTime generatedAt,
  ) async {
    final end = DateTime.utc(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    ).add(const Duration(days: 1));
    final start = end.subtract(Duration(days: windowDays));
    final stored = await store.loadSnapshot(
      startInclusive: start,
      endExclusive: end,
    );
    return _buildStats(stored, generatedAt, start);
  }

  PublicGameStats _buildStats(
    PublicGameStoredSnapshot stored,
    DateTime generatedAt,
    DateTime start,
  ) {
    final activityByDate = {
      for (final point in stored.activity) _dateKey(point.date): point,
    };
    final outcomeCounts = _outcomeCounts(stored.outcomes);
    final overview = stored.overview;
    return PublicGameStats(
      generatedAt: generatedAt,
      windowDays: windowDays,
      totals: PublicGameTotals(
        activeSessions: overview.activeSessions,
        openLobbies: overview.openLobbies,
        matchesStarted: overview.matchesStarted,
        matchesCompleted: overview.matchesCompleted,
        matchesAbandoned: overview.matchesAbandoned,
      ),
      activity: [
        for (var offset = 0; offset < windowDays; offset += 1)
          _activityPoint(start.add(Duration(days: offset)), activityByDate),
      ],
      outcomes: _publicOutcomes(outcomeCounts),
      turns: _turnStats(overview),
    );
  }

  Map<String, int> _outcomeCounts(List<PublicGameStoredOutcome> outcomes) {
    final counts = <String, int>{};
    for (final outcome in outcomes) {
      final condition = _outcomeConditions.contains(outcome.condition)
          ? outcome.condition
          : 'unknown';
      counts.update(
        condition,
        (count) => count + outcome.count,
        ifAbsent: () => outcome.count,
      );
    }
    return counts;
  }

  List<PublicGameOutcomeCount> _publicOutcomes(Map<String, int> counts) => [
    for (final condition in [
      ..._outcomeConditions,
      if ((counts['unknown'] ?? 0) > 0) 'unknown',
    ])
      PublicGameOutcomeCount(
        condition: condition,
        count: counts[condition] ?? 0,
      ),
  ];

  PublicGameTurnStats _turnStats(PublicGameStatsOverview overview) =>
      PublicGameTurnStats(
        averageCompleted: overview.averageCompletedTurns,
        longestCompleted: overview.longestCompletedTurns,
        totalPlayed: overview.totalPlayedTurns,
        distribution: [
          for (final label in _turnDistributionLabels)
            PublicGameTurnDistributionPoint(
              label: label,
              count: overview.completedTurnDistribution[label] ?? 0,
            ),
        ],
      );

  PublicGameActivityPoint _activityPoint(
    DateTime date,
    Map<String, PublicGameDailyActivity> activityByDate,
  ) {
    final key = _dateKey(date);
    final stored = activityByDate[key];
    return PublicGameActivityPoint(
      date: key,
      started: stored?.started ?? 0,
      completed: stored?.completed ?? 0,
    );
  }

  static DateTime _systemNowUtc() => DateTime.now().toUtc();

  String _dateKey(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }
}
