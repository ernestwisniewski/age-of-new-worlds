import '../read_model/pending_action_view.dart';
import 'map_render_snapshot.dart';

bool showMapProductionHints(MapRenderSnapshot snapshot) {
  final interaction = snapshot.interaction;
  if (interaction.city?.founderUnitId != null ||
      interaction.city?.managementMode != null ||
      interaction.reachable != null ||
      interaction.route != null ||
      interaction.movementPending) {
    return false;
  }
  return snapshot.player.cityFoundingDraft == null &&
      !_isMapDecisionPending(snapshot.player.pendingAction);
}

bool _isMapDecisionPending(PendingActionView? pending) => switch (pending) {
  PendingCityWorkedHexSelectionView() ||
  PendingCityExpansionSelectionView() ||
  PendingWorkerActionSelectionView() ||
  PendingMerchantTradeRouteSelectionView() ||
  PendingMerchantMoveToCitySelectionView() ||
  PendingAttackTargetingView() => true,
  _ => false,
};
