import 'package:serverpod/serverpod.dart';

final class PublicGameStatsOverview {
  const PublicGameStatsOverview({
    required this.activeSessions,
    required this.openLobbies,
    required this.matchesStarted,
    required this.matchesCompleted,
    required this.matchesAbandoned,
    required this.averageCompletedTurns,
    required this.longestCompletedTurns,
    required this.totalPlayedTurns,
    required this.completedTurnDistribution,
  });

  final int activeSessions;
  final int openLobbies;
  final int matchesStarted;
  final int matchesCompleted;
  final int matchesAbandoned;
  final double averageCompletedTurns;
  final int longestCompletedTurns;
  final int totalPlayedTurns;
  final Map<String, int> completedTurnDistribution;
}

final class PublicGameDailyActivity {
  const PublicGameDailyActivity({
    required this.date,
    required this.started,
    required this.completed,
  });

  final DateTime date;
  final int started;
  final int completed;
}

final class PublicGameStoredOutcome {
  const PublicGameStoredOutcome({required this.condition, required this.count});

  final String condition;
  final int count;
}

final class PublicGameStoredSnapshot {
  const PublicGameStoredSnapshot({
    required this.overview,
    required this.activity,
    required this.outcomes,
  });

  final PublicGameStatsOverview overview;
  final List<PublicGameDailyActivity> activity;
  final List<PublicGameStoredOutcome> outcomes;
}

abstract interface class PublicGameStatsStore {
  Future<PublicGameStoredSnapshot> loadSnapshot({
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}

final class ServerpodPublicGameStatsStore implements PublicGameStatsStore {
  const ServerpodPublicGameStatsStore(this._session);

  final Session _session;

  @override
  Future<PublicGameStoredSnapshot> loadSnapshot({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final rows = await _session.db.unsafeQuery(
      _publicGameStatsQuery,
      parameters: QueryParameters.named({
        'startInclusive': startInclusive.toUtc(),
        'endExclusive': endExclusive.toUtc(),
      }),
    );
    return _decodeStoredSnapshot(rows);
  }
}

PublicGameStoredSnapshot _decodeStoredSnapshot(List<DatabaseResultRow> rows) {
  PublicGameStatsOverview? overview;
  final activity = <PublicGameDailyActivity>[];
  final outcomes = <PublicGameStoredOutcome>[];
  for (final row in rows) {
    switch (row[0]) {
      case 'overview':
        if (overview != null) {
          throw StateError('Stats query returned duplicate overview rows.');
        }
        overview = _decodeOverview(row);
      case 'activity':
        activity.add(_decodeActivity(row));
      case 'outcome':
        outcomes.add(_decodeOutcome(row));
      default:
        throw StateError('Stats query returned an unknown row type.');
    }
  }
  if (overview == null) {
    throw StateError('Stats query did not return an overview row.');
  }
  return PublicGameStoredSnapshot(
    overview: overview,
    activity: List.unmodifiable(activity),
    outcomes: List.unmodifiable(outcomes),
  );
}

PublicGameStatsOverview _decodeOverview(DatabaseResultRow row) =>
    PublicGameStatsOverview(
      activeSessions: _asInt(row[3]),
      openLobbies: _asInt(row[4]),
      matchesStarted: _asInt(row[5]),
      matchesCompleted: _asInt(row[6]),
      matchesAbandoned: _asInt(row[7]),
      averageCompletedTurns: _asDouble(row[8]),
      longestCompletedTurns: _asInt(row[9]),
      totalPlayedTurns: _asInt(row[10]),
      completedTurnDistribution: {
        '1–10': _asInt(row[11]),
        '11–25': _asInt(row[12]),
        '26–50': _asInt(row[13]),
        '51–100': _asInt(row[14]),
        '101+': _asInt(row[15]),
      },
    );

PublicGameDailyActivity _decodeActivity(DatabaseResultRow row) =>
    PublicGameDailyActivity(
      date: _asDate(row[1]),
      started: _asInt(row[16]),
      completed: _asInt(row[17]),
    );

PublicGameStoredOutcome _decodeOutcome(DatabaseResultRow row) =>
    PublicGameStoredOutcome(
      condition: row[2] as String,
      count: _asInt(row[18]),
    );

int _asInt(Object? value) => switch (value) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.parse(value),
  _ => throw StateError('Expected an integer database value.'),
};

double _asDouble(Object? value) => switch (value) {
  final double value => value,
  final num value => value.toDouble(),
  final String value => double.parse(value),
  _ => throw StateError('Expected a numeric database value.'),
};

DateTime _asDate(Object? value) => switch (value) {
  final DateTime value => value.toUtc(),
  final String value => DateTime.parse(value).toUtc(),
  _ => throw StateError('Expected a date database value.'),
};

const _publicGameStatsQuery = '''
WITH overview AS (
  SELECT
    COUNT(*) FILTER (WHERE "state" = 'running') AS "activeSessions",
    0::bigint AS "openLobbies",
    COUNT(*) AS "matchesStarted",
    COUNT(*) FILTER (WHERE "state" = 'finished') AS "matchesCompleted",
    COUNT(*) FILTER (WHERE "state" = 'abandoned') AS "matchesAbandoned",
    COALESCE(AVG("turn") FILTER (WHERE "state" = 'finished'), 0)::double precision AS "averageCompletedTurns",
    COALESCE(MAX("turn") FILTER (WHERE "state" = 'finished'), 0)::bigint AS "longestCompletedTurns",
    COALESCE(SUM(GREATEST("turn", 0)), 0)::bigint AS "totalPlayedTurns",
    COUNT(*) FILTER (WHERE "state" = 'finished' AND "turn" BETWEEN 1 AND 10) AS "turns1To10",
    COUNT(*) FILTER (WHERE "state" = 'finished' AND "turn" BETWEEN 11 AND 25) AS "turns11To25",
    COUNT(*) FILTER (WHERE "state" = 'finished' AND "turn" BETWEEN 26 AND 50) AS "turns26To50",
    COUNT(*) FILTER (WHERE "state" = 'finished' AND "turn" BETWEEN 51 AND 100) AS "turns51To100",
    COUNT(*) FILTER (WHERE "state" = 'finished' AND "turn" >= 101) AS "turns101Plus"
  FROM "aonw_game_match"
),
daily_activity AS (
  SELECT "day", SUM("started")::bigint AS "started", SUM("completed")::bigint AS "completed"
  FROM (
    SELECT DATE_TRUNC('day', "startedAt")::date AS "day", COUNT(*) AS "started", 0::bigint AS "completed"
    FROM "aonw_game_match"
    WHERE "startedAt" >= @startInclusive AND "startedAt" < @endExclusive
    GROUP BY "day"
    UNION ALL
    SELECT DATE_TRUNC('day', "endedAt")::date AS "day", 0::bigint AS "started", COUNT(*) AS "completed"
    FROM "aonw_game_match"
    WHERE "state" = 'finished' AND "endedAt" >= @startInclusive AND "endedAt" < @endExclusive
    GROUP BY "day"
  ) AS activity_events
  GROUP BY "day"
),
outcomes AS (
  SELECT COALESCE(NULLIF("outcomeCondition", ''), 'unknown') AS "condition", COUNT(*) AS "count"
  FROM "aonw_game_match"
  WHERE "state" = 'finished'
  GROUP BY COALESCE(NULLIF("outcomeCondition", ''), 'unknown')
)
SELECT
  'overview'::text AS "rowType", NULL::date AS "day", NULL::text AS "condition",
  "activeSessions", "openLobbies", "matchesStarted", "matchesCompleted", "matchesAbandoned",
  "averageCompletedTurns", "longestCompletedTurns", "totalPlayedTurns",
  "turns1To10", "turns11To25", "turns26To50", "turns51To100", "turns101Plus",
  NULL::bigint AS "dailyStarted", NULL::bigint AS "dailyCompleted", NULL::bigint AS "outcomeCount"
FROM overview
UNION ALL
SELECT
  'activity'::text, "day", NULL::text,
  NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint,
  NULL::double precision, NULL::bigint, NULL::bigint,
  NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint,
  "started", "completed", NULL::bigint
FROM daily_activity
UNION ALL
SELECT
  'outcome'::text, NULL::date, "condition",
  NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint,
  NULL::double precision, NULL::bigint, NULL::bigint,
  NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint, NULL::bigint,
  NULL::bigint, NULL::bigint, "count"
FROM outcomes
''';
