import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/player_victory_view.dart';

PlayerVictoryView mapPlayerVictoryView(AonwPlayerVictoryView value) =>
    PlayerVictoryView(
      conquestEnabled: value.conquestEnabled,
      dominationEnabled: value.dominationEnabled,
      dominationRequiredControlPercent: value.dominationRequiredControlPercent,
      dominationRequiredHoldTurns: value.dominationRequiredHoldTurns,
      culturalEnabled: value.culturalEnabled,
      culturalRequiredArtifacts: value.culturalRequiredArtifacts,
      culturalRequiredHoldTurns: value.culturalRequiredHoldTurns,
      scoreFallbackEnabled: value.scoreFallbackEnabled,
      turnLimit: value.turnLimit,
      remainingTurns: value.remainingTurns,
      scoreByPlayerId: value.scoreByPlayerId,
      domination: [
        for (final progress in value.domination)
          DominationVictoryProgressView(
            playerId: progress.playerId,
            controlledPassableHexes: progress.controlledPassableHexes,
            totalPassableHexes: progress.totalPassableHexes,
            holdTurns: progress.holdTurns,
          ),
      ],
      ownCultural: CulturalVictoryProgressView(
        uniqueStoredArtifacts: value.ownCultural.uniqueStoredArtifacts,
        holdTurns: value.ownCultural.holdTurns,
      ),
      mapObjectives: [
        for (final progress in value.mapObjectives)
          MapObjectiveProgressView(
            objectiveId: progress.objectiveId,
            controllerPlayerId: progress.controllerPlayerId,
            holdTurns: progress.holdTurns,
          ),
      ],
    );
