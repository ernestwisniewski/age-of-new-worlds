import 'package:aonw_engine_client/src/protocol_json.dart';

final class AonwDominationVictoryProgress {
  const AonwDominationVictoryProgress({
    required this.playerId,
    required this.controlledPassableHexes,
    required this.totalPassableHexes,
    required this.holdTurns,
  });

  factory AonwDominationVictoryProgress.fromJson(Object? source) {
    final value = readObject(source, 'domination victory progress');
    requireKeys(value, const {
      'playerId',
      'controlledPassableHexes',
      'totalPassableHexes',
      'holdTurns',
    }, 'domination victory progress');
    return AonwDominationVictoryProgress(
      playerId: readString(value['playerId'], 'domination player id'),
      controlledPassableHexes: readUnsigned(
        value['controlledPassableHexes'],
        'controlled passable hexes',
      ),
      totalPassableHexes: readUnsigned(
        value['totalPassableHexes'],
        'total passable hexes',
      ),
      holdTurns: readUnsigned(value['holdTurns'], 'domination hold turns'),
    );
  }

  final String playerId;
  final int controlledPassableHexes;
  final int totalPassableHexes;
  final int holdTurns;
}

final class AonwCulturalVictoryProgress {
  const AonwCulturalVictoryProgress({
    required this.uniqueStoredArtifacts,
    required this.holdTurns,
  });

  factory AonwCulturalVictoryProgress.fromJson(Object? source) {
    final value = readObject(source, 'cultural victory progress');
    requireKeys(value, const {
      'uniqueStoredArtifacts',
      'holdTurns',
    }, 'cultural victory progress');
    return AonwCulturalVictoryProgress(
      uniqueStoredArtifacts: readUnsigned(
        value['uniqueStoredArtifacts'],
        'unique stored artifacts',
      ),
      holdTurns: readUnsigned(value['holdTurns'], 'cultural hold turns'),
    );
  }

  final int uniqueStoredArtifacts;
  final int holdTurns;
}

final class AonwMapObjectiveProgress {
  const AonwMapObjectiveProgress({
    required this.objectiveId,
    required this.controllerPlayerId,
    required this.holdTurns,
  });

  factory AonwMapObjectiveProgress.fromJson(Object? source) {
    final value = readObject(source, 'map objective progress');
    requireKeys(value, const {
      'objectiveId',
      'controllerPlayerId',
      'holdTurns',
    }, 'map objective progress');
    return AonwMapObjectiveProgress(
      objectiveId: readString(value['objectiveId'], 'map objective id'),
      controllerPlayerId: readNullableString(
        value['controllerPlayerId'],
        'map objective controller',
      ),
      holdTurns: readUnsigned(value['holdTurns'], 'map objective hold turns'),
    );
  }

  final String objectiveId;
  final String? controllerPlayerId;
  final int holdTurns;
}

final class AonwPlayerVictoryView {
  const AonwPlayerVictoryView({
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
    required this.scoreByPlayerId,
    required this.domination,
    required this.ownCultural,
    required this.mapObjectives,
  });

  factory AonwPlayerVictoryView.empty() => const AonwPlayerVictoryView(
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
    scoreByPlayerId: {},
    domination: [],
    ownCultural: AonwCulturalVictoryProgress(
      uniqueStoredArtifacts: 0,
      holdTurns: 0,
    ),
    mapObjectives: [],
  );

  factory AonwPlayerVictoryView.fromJson(Object? source) =>
      _playerVictoryView(source);

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
  final List<AonwDominationVictoryProgress> domination;
  final AonwCulturalVictoryProgress ownCultural;
  final List<AonwMapObjectiveProgress> mapObjectives;
}

AonwPlayerVictoryView _playerVictoryView(Object? source) {
  final value = readObject(source, 'player victory view');
  requireKeys(value, _playerVictoryKeys, 'player victory view');
  final rules = _victoryRules(value);
  final progress = _victoryProgress(value);
  return AonwPlayerVictoryView(
    conquestEnabled: rules.conquest,
    dominationEnabled: rules.domination,
    dominationRequiredControlPercent: rules.dominationPercent,
    dominationRequiredHoldTurns: rules.dominationTurns,
    culturalEnabled: rules.cultural,
    culturalRequiredArtifacts: rules.culturalArtifacts,
    culturalRequiredHoldTurns: rules.culturalTurns,
    scoreFallbackEnabled: rules.scoreFallback,
    turnLimit: progress.turnLimit,
    remainingTurns: progress.remainingTurns,
    scoreByPlayerId: progress.scoreByPlayerId,
    domination: progress.domination,
    ownCultural: progress.ownCultural,
    mapObjectives: progress.mapObjectives,
  );
}

_VictoryRules _victoryRules(Map<String, Object?> value) => (
  conquest: readBool(value['conquestEnabled'], 'conquest enabled'),
  domination: readBool(value['dominationEnabled'], 'domination enabled'),
  dominationPercent: readFinitePositiveDouble(
    value['dominationRequiredControlPercent'],
    'domination required control percent',
  ),
  dominationTurns: readUnsigned(
    value['dominationRequiredHoldTurns'],
    'domination required hold turns',
  ),
  cultural: readBool(value['culturalEnabled'], 'cultural enabled'),
  culturalArtifacts: readUnsigned(
    value['culturalRequiredArtifacts'],
    'cultural required artifacts',
  ),
  culturalTurns: readUnsigned(
    value['culturalRequiredHoldTurns'],
    'cultural required hold turns',
  ),
  scoreFallback: readBool(
    value['scoreFallbackEnabled'],
    'score fallback enabled',
  ),
);

_VictoryProgress _victoryProgress(Map<String, Object?> value) => (
  turnLimit: _nullableUnsigned(value['turnLimit'], 'score turn limit'),
  remainingTurns: _nullableUnsigned(
    value['remainingTurns'],
    'remaining score turns',
  ),
  scoreByPlayerId: readStringIntMap(
    value['scoreByPlayerId'],
    'victory score by player id',
  ),
  domination: readList(
    value['domination'],
    'domination victory progress',
    (item, _) => AonwDominationVictoryProgress.fromJson(item),
  ),
  ownCultural: AonwCulturalVictoryProgress.fromJson(value['ownCultural']),
  mapObjectives: readList(
    value['mapObjectives'],
    'map objective progress',
    (item, _) => AonwMapObjectiveProgress.fromJson(item),
  ),
);

typedef _VictoryRules = ({
  bool conquest,
  bool domination,
  double dominationPercent,
  int dominationTurns,
  bool cultural,
  int culturalArtifacts,
  int culturalTurns,
  bool scoreFallback,
});

typedef _VictoryProgress = ({
  int? turnLimit,
  int? remainingTurns,
  Map<String, int> scoreByPlayerId,
  List<AonwDominationVictoryProgress> domination,
  AonwCulturalVictoryProgress ownCultural,
  List<AonwMapObjectiveProgress> mapObjectives,
});

const _playerVictoryKeys = {
  'conquestEnabled',
  'dominationEnabled',
  'dominationRequiredControlPercent',
  'dominationRequiredHoldTurns',
  'culturalEnabled',
  'culturalRequiredArtifacts',
  'culturalRequiredHoldTurns',
  'scoreFallbackEnabled',
  'turnLimit',
  'remainingTurns',
  'scoreByPlayerId',
  'domination',
  'ownCultural',
  'mapObjectives',
};

int? _nullableUnsigned(Object? value, String label) =>
    value == null ? null : readUnsigned(value, label);
