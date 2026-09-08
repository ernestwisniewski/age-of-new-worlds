import '../../map/application/game_session_state.dart';
import '../../map/read_model/pending_action_view.dart';
import '../read_model/pending_turn_actions_view.dart';

final class AutomaticTurnTarget {
  const AutomaticTurnTarget.unit(String id) : unitId = id, cityId = null;
  const AutomaticTurnTarget.city(String id) : cityId = id, unitId = null;

  final String? unitId;
  final String? cityId;

  static AutomaticTurnTarget? resolve(GameSessionReady state) {
    final interaction = state.interaction;
    final founder =
        state.recipient.cityFoundingDraft?.founderUnitId ??
        interaction.city?.founderUnitId;
    if (founder != null) return AutomaticTurnTarget.unit(founder);
    final pending = _pending(state.recipient.pendingAction);
    if (pending != null) return pending;
    final unit = interaction.selectedUnitId;
    if (unit != null && state.recipient.controlledUnitById(unit) != null) {
      return AutomaticTurnTarget.unit(unit);
    }
    final city = interaction.city?.cityId;
    if (city != null &&
        state.recipient.cityById(city)?.ownerPlayerId ==
            state.recipient.actorPlayerId) {
      return AutomaticTurnTarget.city(city);
    }
    return null;
  }

  static bool hasManualDraft(GameSessionReady state) =>
      state.recipient.cityFoundingDraft != null ||
      _pending(state.recipient.pendingAction) != null ||
      state.interaction.route != null ||
      state.interaction.city?.founderUnitId != null ||
      state.interaction.city?.managementMode != null ||
      state.interaction.worker?.actionsOpen == true ||
      state.interaction.worker?.previewedImprovement != null;

  bool needsOrder(PendingTurnActionsView work) => work.actions.any(
    (action) => switch (action) {
      PendingUnitTurnActionView(:final unitId) => unitId == this.unitId,
      PendingCityProductionTurnActionView(:final cityId) =>
        cityId == this.cityId,
      PendingResearchTurnActionView() => false,
    },
  );

  @override
  bool operator ==(Object other) =>
      other is AutomaticTurnTarget &&
      other.unitId == unitId &&
      other.cityId == cityId;

  @override
  int get hashCode => Object.hash(unitId, cityId);
}

AutomaticTurnTarget? _pending(PendingActionView? action) => switch (action) {
  PendingCityWorkedHexSelectionView(:final cityId) ||
  PendingCityExpansionSelectionView(
    :final cityId,
  ) => AutomaticTurnTarget.city(cityId),
  _ => _pendingUnit(action),
};

AutomaticTurnTarget? _pendingUnit(PendingActionView? action) =>
    switch (action) {
      PendingWorkerActionSelectionView(:final unitId) ||
      PendingMerchantTradeRouteSelectionView(:final unitId) ||
      PendingMerchantMoveToCitySelectionView(:final unitId) ||
      PendingAttackTargetingView(:final unitId) ||
      PendingCommanderMergeSelectionView(
        :final unitId,
      ) => AutomaticTurnTarget.unit(unitId),
      _ => null,
    };
