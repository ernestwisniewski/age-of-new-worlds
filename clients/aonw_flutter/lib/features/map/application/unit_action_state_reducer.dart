import '../../unit_actions/application/action_deck_state.dart';
import '../../unit_actions/application/unit_action_command_runner.dart';
import '../read_model/player_map_view.dart';
import 'game_session_state.dart';

GameSessionReady reduceUnitActionCompletion(
  GameSessionReady current,
  UnitActionCommandCompletion completion,
) {
  final failure = completion.failure;
  if (failure == null) return _successfulCompletion(current, completion);

  return _failedCompletion(current, completion, failure);
}

GameSessionReady _successfulCompletion(
  GameSessionReady current,
  UnitActionCommandCompletion completion,
) {
  final result = completion.result!;
  if (!result.accepted) {
    return current.withInteraction(
      current.interaction.copyWith(
        actionDeck: current.interaction.actionDeck?.copyWith(
          clearInFlightAction: true,
          failure: UnitActionFailure.rejected(result.rejectionCode!),
        ),
      ),
    );
  }
  final player = result.player!;
  final selectedUnit = _unit(player, result.unitId);
  final interaction = selectedUnit == null
      ? current.interaction.copyWith(
          clearSelected: true,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          clearProduction: true,
          clearCombat: true,
        )
      : current.interaction.copyWith(
          selected: selectedUnit.coordinate,
          selectedUnitId: selectedUnit.id,
          clearReachable: true,
          clearRoute: true,
          actionDeck: current.interaction.actionDeck?.copyWith(
            clearInFlightAction: true,
            clearFailure: true,
          ),
        );
  return current.withRecipient(player).withInteraction(interaction);
}

GameSessionReady _failedCompletion(
  GameSessionReady current,
  UnitActionCommandCompletion completion,
  UnitActionFailure failure,
) {
  final player = completion.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  final actionDeck = synchronized.interaction.actionDeck;
  if (player != null &&
      actionDeck != null &&
      _unit(player, actionDeck.unitId) == null) {
    return synchronized.withInteraction(
      synchronized.interaction.copyWith(
        clearSelected: true,
        clearSelectedUnit: true,
        clearReachable: true,
        clearRoute: true,
        clearActionDeck: true,
        clearUnitLogistics: true,
        clearWorker: true,
        clearProduction: true,
        clearCombat: true,
      ),
    );
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      actionDeck: actionDeck?.copyWith(
        clearInFlightAction: true,
        failure: failure,
      ),
    ),
  );
}

VisibleUnitView? _unit(PlayerMapView player, String unitId) {
  for (final unit in player.units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}
