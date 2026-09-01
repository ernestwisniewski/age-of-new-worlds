final class DominationVictoryProgressView {
  const DominationVictoryProgressView({
    required this.playerId,
    required this.controlledPassableHexes,
    required this.totalPassableHexes,
    required this.holdTurns,
  });

  final String playerId;
  final int controlledPassableHexes;
  final int totalPassableHexes;
  final int holdTurns;
}

final class CulturalVictoryProgressView {
  const CulturalVictoryProgressView({
    required this.uniqueStoredArtifacts,
    required this.holdTurns,
  });

  final int uniqueStoredArtifacts;
  final int holdTurns;
}

final class MapObjectiveProgressView {
  const MapObjectiveProgressView({
    required this.objectiveId,
    required this.controllerPlayerId,
    required this.holdTurns,
  });

  final String objectiveId;
  final String? controllerPlayerId;
  final int holdTurns;
}

final class PlayerVictoryView {
  PlayerVictoryView({
    required this.conquestEnabled,
    required this.dominationEnabled,
    required this.dominationRequiredControlPercent,
    required this.dominationRequiredHoldTurns,
    required this.culturalEnabled,
    required this.culturalRequiredArtifacts,
    required this.culturalRequiredHoldTurns,
    required this.scoreFallbackEnabled,
    required this.turnLimit,
    required this.remainingTurns,
    required Map<String, int> scoreByPlayerId,
    required List<DominationVictoryProgressView> domination,
    required this.ownCultural,
    required List<MapObjectiveProgressView> mapObjectives,
  }) : scoreByPlayerId = Map.unmodifiable(scoreByPlayerId),
       domination = List.unmodifiable(domination),
       mapObjectives = List.unmodifiable(mapObjectives);

  factory PlayerVictoryView.empty() => PlayerVictoryView(
    conquestEnabled: false,
    dominationEnabled: false,
    dominationRequiredControlPercent: 60,
    dominationRequiredHoldTurns: 5,
    culturalEnabled: false,
    culturalRequiredArtifacts: 6,
    culturalRequiredHoldTurns: 5,
    scoreFallbackEnabled: false,
    turnLimit: null,
    remainingTurns: null,
    scoreByPlayerId: const {},
    domination: const [],
    ownCultural: const CulturalVictoryProgressView(
      uniqueStoredArtifacts: 0,
      holdTurns: 0,
    ),
    mapObjectives: const [],
  );

  final bool conquestEnabled;
  final bool dominationEnabled;
  final double dominationRequiredControlPercent;
  final int dominationRequiredHoldTurns;
  final bool culturalEnabled;
  final int culturalRequiredArtifacts;
  final int culturalRequiredHoldTurns;
  final bool scoreFallbackEnabled;
  final int? turnLimit;
  final int? remainingTurns;
  final Map<String, int> scoreByPlayerId;
  final List<DominationVictoryProgressView> domination;
  final CulturalVictoryProgressView ownCultural;
  final List<MapObjectiveProgressView> mapObjectives;
}
