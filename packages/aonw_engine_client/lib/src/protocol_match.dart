enum AonwGameMode { hotSeat, multiplayer }

enum AonwTurnMode { sequential, simultaneous }

enum AonwPlayerKind { human, ai }

enum AonwPlayerCountry {
  poland,
  ukraine,
  germany,
  france,
  unitedKingdom,
  italy,
  spain,
  netherlands,
  sweden,
  russia,
  unitedStates,
  canada,
  china,
  korea,
  japan,
  portugal,
  india,
  brazil,
  indonesia,
  mexico,
  turkey,
  saudiArabia,
  egypt,
  greece,
}

enum AonwAiStrategyId { random, basic, scripted, utility, mcts }

enum AonwAiDifficulty { easy, normal, hard, veryHard }

enum AonwAiPersona { balanced, aggressive, expansive, economic, scientific }

enum AonwGameLengthKind { unlimited, targetMinutes }

enum AonwPaceProfile { unlimited, standard60, normal90, long120 }

final class AonwAiPlayer {
  AonwAiPlayer({
    required this.strategyId,
    required this.difficulty,
    required this.persona,
    required int seed,
  }) : seed = _requireSigned64(seed, 'seed');

  final AonwAiStrategyId strategyId;
  final AonwAiDifficulty difficulty;
  final AonwAiPersona persona;
  final int seed;

  Map<String, Object?> toJson() => {
    'strategyId': strategyId.name,
    'difficulty': difficulty.name,
    'persona': persona.name,
    'seed': seed,
  };
}

final class AonwParticipant {
  AonwParticipant({
    required String id,
    required String name,
    required int colorValue,
    required this.country,
    required this.kind,
    this.ai,
  }) : id = _requireIdentifier(id, 'participant id'),
       name = _requireDisplayName(name),
       colorValue = _requireColor(colorValue) {
    if (kind == AonwPlayerKind.ai && ai == null) {
      throw ArgumentError.value(ai, 'ai', 'AI participant requires AI config');
    }
    if (kind == AonwPlayerKind.human && ai != null) {
      throw ArgumentError.value(
        ai,
        'ai',
        'human participant forbids AI config',
      );
    }
  }

  final String id;
  final String name;
  final int colorValue;
  final AonwPlayerCountry country;
  final AonwPlayerKind kind;
  final AonwAiPlayer? ai;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
    'country': country.name,
    'kind': kind.name,
    'ai': ai?.toJson(),
  };
}

final class AonwGameLength {
  const AonwGameLength.unlimited()
    : kind = AonwGameLengthKind.unlimited,
      targetMinutes = null,
      turnLimit = null,
      paceProfile = AonwPaceProfile.unlimited,
      scoreFallbackEnabled = false;

  AonwGameLength.targetMinutes({
    required int targetMinutes,
    required int turnLimit,
    required this.paceProfile,
    required this.scoreFallbackEnabled,
  }) : kind = AonwGameLengthKind.targetMinutes,
       targetMinutes = _requirePositive(targetMinutes, 'targetMinutes'),
       turnLimit = _requirePositive(turnLimit, 'turnLimit') {
    if (paceProfile == AonwPaceProfile.unlimited) {
      throw ArgumentError.value(
        paceProfile,
        'paceProfile',
        'timed match requires a finite pace profile',
      );
    }
  }

  final AonwGameLengthKind kind;
  final int? targetMinutes;
  final int? turnLimit;
  final AonwPaceProfile paceProfile;
  final bool scoreFallbackEnabled;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'targetMinutes': targetMinutes,
    'turnLimit': turnLimit,
    'paceProfile': paceProfile.name,
    'scoreFallbackEnabled': scoreFallbackEnabled,
  };
}

final class AonwVictoryRules {
  AonwVictoryRules({
    this.conquestEnabled = true,
    this.dominationEnabled = true,
    int dominationControlPercent = 60,
    int dominationHoldTurns = 5,
    this.scoreFallbackEnabled = false,
    int? turnLimit,
    int? hardTimeLimitMinutes,
    this.culturalEnabled = true,
    int culturalRequiredArtifacts = 6,
    int culturalHoldTurns = 5,
  }) : dominationControlPercent = _requirePercent(
         dominationControlPercent,
         'dominationControlPercent',
       ),
       dominationHoldTurns = _requirePositive(
         dominationHoldTurns,
         'dominationHoldTurns',
       ),
       turnLimit = _requireOptionalPositive(turnLimit, 'turnLimit'),
       hardTimeLimitMinutes = _requireOptionalPositive(
         hardTimeLimitMinutes,
         'hardTimeLimitMinutes',
       ),
       culturalRequiredArtifacts = _requirePositive(
         culturalRequiredArtifacts,
         'culturalRequiredArtifacts',
       ),
       culturalHoldTurns = _requirePositive(
         culturalHoldTurns,
         'culturalHoldTurns',
       );

  final bool conquestEnabled;
  final bool dominationEnabled;
  final int dominationControlPercent;
  final int dominationHoldTurns;
  final bool scoreFallbackEnabled;
  final int? turnLimit;
  final int? hardTimeLimitMinutes;
  final bool culturalEnabled;
  final int culturalRequiredArtifacts;
  final int culturalHoldTurns;

  Map<String, Object?> toJson() => {
    'conquestEnabled': conquestEnabled,
    'dominationEnabled': dominationEnabled,
    'dominationControlPercent': dominationControlPercent,
    'dominationHoldTurns': dominationHoldTurns,
    'scoreFallbackEnabled': scoreFallbackEnabled,
    'turnLimit': turnLimit,
    'hardTimeLimitMinutes': hardTimeLimitMinutes,
    'culturalEnabled': culturalEnabled,
    'culturalRequiredArtifacts': culturalRequiredArtifacts,
    'culturalHoldTurns': culturalHoldTurns,
  };
}

final class AonwMatchRules {
  AonwMatchRules({
    this.gameLength = const AonwGameLength.unlimited(),
    AonwVictoryRules? victory,
  }) : victory = victory ?? AonwVictoryRules();

  final AonwGameLength gameLength;
  final AonwVictoryRules victory;

  Map<String, Object?> toJson() => {
    'gameLength': gameLength.toJson(),
    'victory': victory.toJson(),
    'balance': const <String, Object?>{},
  };
}

final class AonwMatchIdentity {
  AonwMatchIdentity({
    AonwMatchRules? matchRules,
    required Iterable<AonwParticipant> participants,
    required this.gameMode,
    AonwTurnMode? turnMode,
  }) : matchRules = matchRules ?? AonwMatchRules(),
       participants = _validatedParticipants(participants),
       turnMode = turnMode ?? _defaultTurnMode(gameMode);

  final AonwMatchRules matchRules;
  final List<AonwParticipant> participants;
  final AonwGameMode gameMode;
  final AonwTurnMode turnMode;

  Map<String, Object?> toJson() => {
    'matchRules': matchRules.toJson(),
    'participants': [
      for (final participant in participants) participant.toJson(),
    ],
    'gameMode': gameMode.name,
    'turnMode': turnMode.name,
  };
}

AonwTurnMode _defaultTurnMode(AonwGameMode gameMode) => switch (gameMode) {
  AonwGameMode.hotSeat => AonwTurnMode.sequential,
  AonwGameMode.multiplayer => AonwTurnMode.simultaneous,
};

List<AonwParticipant> _validatedParticipants(Iterable<AonwParticipant> values) {
  final participants = List<AonwParticipant>.unmodifiable(values);
  if (participants.isEmpty) {
    throw ArgumentError.value(values, 'participants', 'must not be empty');
  }
  final ids = <String>{};
  for (final participant in participants) {
    if (!ids.add(participant.id)) {
      throw ArgumentError.value(
        participant.id,
        'participants',
        'participant ids must be unique',
      );
    }
  }
  return participants;
}

String _requireIdentifier(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _requireDisplayName(String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, 'name', 'must not be blank');
  }
  return value;
}

int _requireColor(int value) {
  if (value < 0 || value > 0xffffffff) {
    throw ArgumentError.value(value, 'colorValue', 'must fit unsigned 32-bit');
  }
  return value;
}

int _requireSigned64(int value, String name) {
  if (value < -0x8000000000000000 || value > 0x7fffffffffffffff) {
    throw ArgumentError.value(value, name, 'must fit signed 64-bit');
  }
  return value;
}

int _requirePositive(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
  return value;
}

int? _requireOptionalPositive(int? value, String name) =>
    value == null ? null : _requirePositive(value, name);

int _requirePercent(int value, String name) {
  if (value <= 0 || value > 100) {
    throw ArgumentError.value(value, name, 'must be between 1 and 100');
  }
  return value;
}
