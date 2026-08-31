final class PublicGameTotals {
  const PublicGameTotals({
    required this.activeSessions,
    required this.openLobbies,
    required this.matchesStarted,
    required this.matchesCompleted,
    required this.matchesAbandoned,
  });

  final int activeSessions;
  final int openLobbies;
  final int matchesStarted;
  final int matchesCompleted;
  final int matchesAbandoned;

  Map<String, Object> toJson() => {
    'activeSessions': activeSessions,
    'openLobbies': openLobbies,
    'matchesStarted': matchesStarted,
    'matchesCompleted': matchesCompleted,
    'matchesAbandoned': matchesAbandoned,
  };
}

final class PublicGameActivityPoint {
  const PublicGameActivityPoint({
    required this.date,
    required this.started,
    required this.completed,
  });

  final String date;
  final int started;
  final int completed;

  Map<String, Object> toJson() => {
    'date': date,
    'started': started,
    'completed': completed,
  };
}

final class PublicGameOutcomeCount {
  const PublicGameOutcomeCount({required this.condition, required this.count});

  final String condition;
  final int count;

  Map<String, Object> toJson() => {'condition': condition, 'count': count};
}

final class PublicGameTurnDistributionPoint {
  const PublicGameTurnDistributionPoint({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  Map<String, Object> toJson() => {'label': label, 'count': count};
}

final class PublicGameTurnStats {
  const PublicGameTurnStats({
    required this.averageCompleted,
    required this.longestCompleted,
    required this.totalPlayed,
    required this.distribution,
  });

  final double averageCompleted;
  final int longestCompleted;
  final int totalPlayed;
  final List<PublicGameTurnDistributionPoint> distribution;

  Map<String, Object> toJson() => {
    'averageCompleted': averageCompleted,
    'longestCompleted': longestCompleted,
    'totalPlayed': totalPlayed,
    'distribution': [for (final point in distribution) point.toJson()],
  };
}

final class PublicGameStats {
  const PublicGameStats({
    required this.generatedAt,
    required this.windowDays,
    required this.totals,
    required this.activity,
    required this.outcomes,
    required this.turns,
  });

  static const schemaVersion = 1;

  final DateTime generatedAt;
  final int windowDays;
  final PublicGameTotals totals;
  final List<PublicGameActivityPoint> activity;
  final List<PublicGameOutcomeCount> outcomes;
  final PublicGameTurnStats turns;

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'windowDays': windowDays,
    'totals': totals.toJson(),
    'activity': [for (final point in activity) point.toJson()],
    'outcomes': [for (final outcome in outcomes) outcome.toJson()],
    'turns': turns.toJson(),
  };
}
