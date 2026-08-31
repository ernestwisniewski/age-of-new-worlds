import 'dart:async';

import '../../logistics/application/unit_logistics_state.dart';
import '../../unit_actions/application/unit_action_command_runner.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import 'game_session_state.dart';
import 'unit_action_state_reducer.dart';

typedef UnitActionStateReader = GameSessionState Function();
typedef UnitActionStatePublisher = void Function(GameSessionReady value);
typedef UnitActionDisposed = bool Function();
typedef UnitActionSelectionRetained = void Function(String unitId);

final class UnitActionWorkflow {
  UnitActionWorkflow({required UnitActionCommandRunner runner})
    : _runner = runner;

  final UnitActionCommandRunner _runner;
  var _correlationId = 0;

  void execute({
    required UnitActionKindView action,
    required UnitActionStateReader readState,
    required UnitActionStatePublisher publish,
    required UnitActionDisposed isDisposed,
    required UnitActionSelectionRetained onSelectionRetained,
  }) {
    unawaited(
      _execute(
        action: action,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
        onSelectionRetained: onSelectionRetained,
      ),
    );
  }

  Future<void> _execute({
    required UnitActionKindView action,
    required UnitActionStateReader readState,
    required UnitActionStatePublisher publish,
    required UnitActionDisposed isDisposed,
    required UnitActionSelectionRetained onSelectionRetained,
  }) async {
    final current = _actionable(readState());
    if (current == null) return;
    final unitId = current.interaction.selectedUnitId!;
    final correlationId = ++_correlationId;
    publish(_pending(current, action, correlationId));
    final completion = await _runner.execute(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      action: action,
    );
    if (isDisposed()) return;
    final ready = _correlated(readState(), correlationId);
    if (ready == null) return;
    final reduced = reduceUnitActionCompletion(ready, completion);
    final selectedUnitId = reduced.interaction.selectedUnitId;
    if (selectedUnitId == null) {
      publish(reduced);
      return;
    }
    publish(
      reduced.withInteraction(
        reduced.interaction.copyWith(
          unitLogistics: UnitLogisticsState.loading(selectedUnitId),
        ),
      ),
    );
    onSelectionRetained(selectedUnitId);
  }
}

GameSessionReady? _actionable(GameSessionState state) {
  if (state is! GameSessionReady) return null;
  final interaction = state.interaction;
  final deck = interaction.actionDeck;
  final unitId = interaction.selectedUnitId;
  if (interaction.movementPending ||
      state.research.commandPending ||
      state.diplomacy.commandPending ||
      (interaction.combat?.commandPending ?? false) ||
      (interaction.combat?.loading ?? false) ||
      (interaction.unitLogistics?.commandPending ?? false) ||
      (interaction.worker?.commandPending ?? false) ||
      deck == null ||
      deck.commandPending ||
      unitId == null ||
      deck.unitId != unitId) {
    return null;
  }
  return state;
}

GameSessionReady _pending(
  GameSessionReady current,
  UnitActionKindView action,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    clearReachable: true,
    clearRoute: true,
    clearMovementError: true,
    clearCombat: true,
    actionDeck: current.interaction.actionDeck!.copyWith(
      correlationId: correlationId,
      inFlightAction: action,
      clearFailure: true,
    ),
  ),
);

GameSessionReady? _correlated(GameSessionState state, int correlationId) =>
    state is GameSessionReady &&
        state.interaction.actionDeck?.correlationId == correlationId
    ? state
    : null;
