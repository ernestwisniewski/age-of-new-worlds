import '../../combat/application/combat_state.dart';
import '../../map/application/game_session_state.dart';
import '../../map/application/map_interaction_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../read_model/pending_turn_actions_view.dart';

/// Chooses when automatic navigation may use the engine's pending-work list.
/// Input ownership, lifecycle and animation guards remain with the caller.
final class AutomaticTurnPolicy {
  const AutomaticTurnPolicy({
    this.advanceActions = true,
    this.endTurn = false,
    this.primed = false,
    this.manualTargetPaused = false,
    this.researchDismissed = false,
    this.resolvedCityCompleted = false,
  });

  final bool advanceActions;
  final bool endTurn;
  final bool primed;
  final bool manualTargetPaused;
  final bool researchDismissed;
  final bool resolvedCityCompleted;

  bool canAdvance(PendingTurnActionsView work, GameSessionReady state) {
    if (!work.canActivate || _isPaused(state)) return false;
    if (_needsDecision(work, state)) return false;
    if (work.actions.isEmpty) return endTurn;
    if (!advanceActions) return false;
    final cityId = _selectedOwnCity(state);
    if (cityId != null && !resolvedCityCompleted) return false;
    return primed || _hasResolvedSelection(state) || _hasUnitOrCity(work);
  }

  bool _isPaused(GameSessionReady state) =>
      manualTargetPaused ||
      researchDismissed ||
      state.turnAction.failure != null;

  bool _needsDecision(PendingTurnActionsView work, GameSessionReady state) =>
      state.recipient.cityFoundingDraft != null ||
      _hasManualInteraction(state.interaction) ||
      _pendingNeedsDecision(work, state.recipient.pendingAction) ||
      _selectionNeedsDecision(work, state.interaction);

  bool _pendingNeedsDecision(
    PendingTurnActionsView work,
    PendingActionView? pending,
  ) => switch (pending) {
    null || PendingUnitTurnSkipView() => false,
    PendingResearchSelectionView() => !work.actions.any(
      (action) => action is PendingResearchTurnActionView,
    ),
    PendingActionView() => true,
  };

  bool _hasManualInteraction(MapInteractionState interaction) =>
      interaction.moveTargeting ||
      interaction.route != null ||
      _combatNeedsDecision(interaction.combat) ||
      _hasCityOrWorkerDraft(interaction);

  bool _combatNeedsDecision(CombatState? combat) =>
      combat != null &&
      (combat.loading ||
          combat.commandPending ||
          combat.failure != null ||
          combat.lastExecution == null);

  bool _hasCityOrWorkerDraft(MapInteractionState interaction) =>
      interaction.city?.founderUnitId != null ||
      interaction.city?.managementMode != null ||
      interaction.worker?.actionsOpen == true ||
      interaction.worker?.previewedImprovement != null;

  bool _selectionNeedsDecision(
    PendingTurnActionsView work,
    MapInteractionState interaction,
  ) => work.actions.any(
    (action) => switch (action) {
      PendingUnitTurnActionView(:final unitId) =>
        unitId == interaction.selectedUnitId,
      PendingCityProductionTurnActionView(:final cityId) =>
        cityId == interaction.city?.cityId,
      PendingResearchTurnActionView() => interaction.researchFocused,
    },
  );

  bool _hasUnitOrCity(PendingTurnActionsView work) => work.actions.any(
    (action) =>
        action is PendingUnitTurnActionView ||
        action is PendingCityProductionTurnActionView,
  );

  bool _hasResolvedSelection(GameSessionReady state) =>
      state.recipient.controlledUnitById(
            state.interaction.selectedUnitId ?? '',
          ) !=
          null ||
      _selectedOwnCity(state) != null;

  String? _selectedOwnCity(GameSessionReady state) {
    final id = state.interaction.city?.cityId;
    if (id == null) return null;
    return state.recipient.cityById(id)?.ownerPlayerId ==
            state.recipient.actorPlayerId
        ? id
        : null;
  }
}
