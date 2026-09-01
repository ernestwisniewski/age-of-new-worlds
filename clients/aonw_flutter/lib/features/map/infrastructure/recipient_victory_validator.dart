import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/map_view.dart';

final class RecipientVictoryValidator {
  const RecipientVictoryValidator(this.map);

  final MapView map;

  void validate(
    AonwPlayerVictoryView victory, {
    required int turn,
    required Set<String> participantIds,
  }) {
    _validateRules(victory, turn);
    _validateScores(victory.scoreByPlayerId, participantIds);
    _validateDomination(victory.domination, participantIds);
    _validateObjectives(victory.mapObjectives, participantIds);
  }

  static void _validateRules(AonwPlayerVictoryView victory, int turn) {
    final invalidThresholds =
        victory.dominationRequiredControlPercent > 100 ||
        victory.dominationRequiredHoldTurns == 0 ||
        victory.culturalRequiredArtifacts == 0 ||
        victory.culturalRequiredHoldTurns == 0 ||
        victory.turnLimit == 0;
    if (invalidThresholds) {
      throw const FormatException('Recipient victory rules are invalid.');
    }
    final expectedRemaining = switch ((
      victory.scoreFallbackEnabled,
      victory.turnLimit,
    )) {
      (true, final int limit) => limit > turn ? limit - turn : 0,
      _ => null,
    };
    if (victory.remainingTurns != expectedRemaining) {
      throw const FormatException(
        'Recipient score turn countdown is inconsistent.',
      );
    }
  }

  static void _validateScores(
    Map<String, int> scores,
    Set<String> participantIds,
  ) {
    String? previous;
    for (final entry in scores.entries) {
      final invalid =
          entry.key.isEmpty ||
          !participantIds.contains(entry.key) ||
          entry.value < 0 ||
          (previous != null && previous.compareTo(entry.key) >= 0);
      if (invalid) {
        throw const FormatException('Recipient live score is invalid.');
      }
      previous = entry.key;
    }
  }

  static void _validateDomination(
    List<AonwDominationVictoryProgress> progress,
    Set<String> participantIds,
  ) {
    String? previous;
    for (final value in progress) {
      final invalid =
          value.playerId.isEmpty ||
          !participantIds.contains(value.playerId) ||
          value.controlledPassableHexes > value.totalPassableHexes ||
          (previous != null && previous.compareTo(value.playerId) >= 0);
      if (invalid) {
        throw const FormatException(
          'Recipient domination progress is invalid.',
        );
      }
      previous = value.playerId;
    }
  }

  void _validateObjectives(
    List<AonwMapObjectiveProgress> progress,
    Set<String> participantIds,
  ) {
    if (progress.length != map.objectives.length) {
      throw const FormatException(
        'Recipient map objective progress is incomplete.',
      );
    }
    for (var index = 0; index < progress.length; index++) {
      final value = progress[index];
      final controller = value.controllerPlayerId;
      final invalidDisclosure = controller == null
          ? value.holdTurns != 0
          : value.holdTurns == 0 || !participantIds.contains(controller);
      if (value.objectiveId != map.objectives[index].id || invalidDisclosure) {
        throw const FormatException(
          'Recipient map objective progress is invalid.',
        );
      }
    }
  }
}
