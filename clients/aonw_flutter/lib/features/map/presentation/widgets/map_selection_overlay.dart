import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../l10n/l10n.dart';
import '../../../artifacts/presentation/artifact_panel.dart';
import '../../../artifacts/read_model/artifact_view.dart';
import '../../../cities/presentation/city_copy.dart';
import '../../../cities/presentation/city_panel.dart';
import '../../../cities/read_model/city_view.dart';
import '../../../combat/presentation/combat_panel.dart';
import '../../../combat/read_model/combat_view.dart';
import '../../../logistics/read_model/unit_logistics_view.dart';
import '../../../production/presentation/production_panel.dart';
import '../../../production/read_model/production_view.dart';
import '../../../unit_actions/presentation/unit_action_deck.dart';
import '../../../unit_actions/read_model/unit_action_view.dart';
import '../../../workers/presentation/worker_panel.dart';
import '../../../workers/read_model/worker_view.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../../read_model/pending_action_view.dart';
import '../../read_model/player_map_view.dart';
import '../map_presentation_controller.dart';
import 'map_failure_messages.dart';

final class MapSelectionOverlay extends StatelessWidget {
  const MapSelectionOverlay({
    required this.scene,
    required this.interaction,
    required this.controller,
    super.key,
  });

  final MapScene scene;
  final MapInteractionState interaction;
  final MapPresentationController controller;

  @override
  Widget build(BuildContext context) {
    final selected = interaction.selected;
    if (selected == null) return const SizedBox.shrink();
    final selectedUnitId = interaction.selectedUnitId;
    return Positioned.fill(
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 66),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: _MapSelectionPanel(
            coordinate: selected,
            interaction: interaction,
            unit: selectedUnitId == null
                ? null
                : scene.player.controlledUnitById(selectedUnitId),
            city: interaction.city?.cityId == null
                ? scene.player.cityAt(selected)
                : scene.player.cityById(interaction.city!.cityId!),
            player: scene.player,
            pendingWorkerAction:
                scene.player.pendingAction is PendingWorkerActionSelectionView
                ? scene.player.pendingAction!
                      as PendingWorkerActionSelectionView
                : null,
            onConfirmMove: controller.confirmMove,
            onUnitAction: controller.executeUnitAction,
            onUnitLogistics: controller.executeUnitLogistics,
            onWorkerAction: controller.executeWorkerAction,
            onConfirmCombat: controller.confirmCombat,
            onCityConquestAction: controller.setCityConquestAction,
            onOpenCityFounding: controller.openCityFounding,
            onToggleCityFoundingHex: controller.toggleCityFoundingHex,
            onConfirmCityFounding: controller.confirmCityFounding,
            onCityAction: controller.executeCityAction,
            onProductionAction: controller.executeProductionAction,
            onArtifactAction: controller.executeArtifactAction,
          ),
        ),
      ),
    );
  }
}

final class _MapSelectionPanel extends StatelessWidget {
  const _MapSelectionPanel({
    required this.coordinate,
    required this.interaction,
    required this.unit,
    required this.city,
    required this.player,
    required this.pendingWorkerAction,
    required this.onConfirmMove,
    required this.onUnitAction,
    required this.onUnitLogistics,
    required this.onWorkerAction,
    required this.onConfirmCombat,
    required this.onCityConquestAction,
    required this.onOpenCityFounding,
    required this.onToggleCityFoundingHex,
    required this.onConfirmCityFounding,
    required this.onCityAction,
    required this.onProductionAction,
    required this.onArtifactAction,
  });

  final MapHexCoordinate coordinate;
  final MapInteractionState interaction;
  final VisibleUnitView? unit;
  final CityView? city;
  final PlayerMapView player;
  final PendingWorkerActionSelectionView? pendingWorkerAction;
  final VoidCallback onConfirmMove;
  final ValueChanged<UnitActionKindView> onUnitAction;
  final ValueChanged<UnitLogisticsActionView> onUnitLogistics;
  final ValueChanged<WorkerActionView> onWorkerAction;
  final VoidCallback onConfirmCombat;
  final ValueChanged<CityConquestActionView> onCityConquestAction;
  final VoidCallback onOpenCityFounding;
  final ValueChanged<MapHexCoordinate> onToggleCityFoundingHex;
  final VoidCallback onConfirmCityFounding;
  final ValueChanged<CityActionView> onCityAction;
  final ValueChanged<ProductionActionView> onProductionAction;
  final ValueChanged<ArtifactActionView> onArtifactAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return AonwHudSurface(
      key: const ValueKey('map-selection-panel'),
      liveRegion: true,
      elevation: AonwHudElevation.flat,
      maxWidth: 840,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: BorderRadius.circular(AonwRadii.button),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.52,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.hexLabel(coordinate.col, coordinate.row)),
              if (interaction.selectedUnitId case final unitId?) ...[
                const SizedBox(height: AonwSpacing.xs),
                Text(l10n.unitLabel(unitId)),
                if (unit case final unit?)
                  Text(l10n.presentationName(unit.kind.name)),
                if (interaction.combat == null)
                  _MovementControls(
                    interaction: interaction,
                    onConfirmMove: onConfirmMove,
                  ),
                if (interaction.actionDeck case final actionDeck?)
                  UnitActionDeck(
                    state: actionDeck,
                    logistics: interaction.unitLogistics,
                    enabled:
                        !interaction.movementPending &&
                        !(interaction.worker?.commandPending ?? false) &&
                        !(interaction.production?.commandPending ?? false) &&
                        !(interaction.artifact?.commandPending ?? false),
                    onAction: onUnitAction,
                    onLogisticsAction: onUnitLogistics,
                  ),
                if (interaction.worker case final workerState?)
                  if (unit case final unit?)
                    WorkerPanel(
                      state: workerState,
                      unit: unit,
                      pendingAction: pendingWorkerAction?.unitId == unit.id
                          ? pendingWorkerAction
                          : null,
                      enabled:
                          !interaction.movementPending &&
                          !(interaction.actionDeck?.commandPending ?? false) &&
                          !(interaction.unitLogistics?.commandPending ??
                              false) &&
                          !(interaction.production?.commandPending ?? false) &&
                          !(interaction.artifact?.commandPending ?? false),
                      onAction: onWorkerAction,
                    ),
                if (interaction.city?.founderUnitId == null)
                  TextButton.icon(
                    key: const ValueKey('open-city-founding'),
                    onPressed: onOpenCityFounding,
                    icon: const Icon(Icons.add_location_alt),
                    label: Text(
                      CityCopy.of(context).text(CityText.foundingOpen),
                    ),
                  ),
              ],
              if (interaction.combat case final combat?)
                CombatPanel(
                  state: combat,
                  onConfirm: onConfirmCombat,
                  onCityConquestAction: onCityConquestAction,
                ),
              if (interaction.city case final cityState?)
                CityPanel(
                  state: cityState,
                  city: city,
                  onToggleFoundingHex: onToggleCityFoundingHex,
                  onConfirmFounding: onConfirmCityFounding,
                  onAction: onCityAction,
                  enabled:
                      !(interaction.production?.commandPending ?? false) &&
                      !(interaction.artifact?.commandPending ?? false),
                ),
              if (interaction.production case final productionState?)
                ProductionPanel(
                  state: productionState,
                  enabled:
                      !(interaction.city?.commandPending ?? false) &&
                      !interaction.movementPending &&
                      !(interaction.artifact?.commandPending ?? false),
                  onAction: onProductionAction,
                ),
              if (interaction.artifact case final artifactState?)
                ArtifactPanel(
                  state: artifactState,
                  player: player,
                  coordinate: coordinate,
                  unit: unit,
                  city: city,
                  enabled:
                      !interaction.movementPending &&
                      !(interaction.city?.commandPending ?? false) &&
                      !(interaction.production?.commandPending ?? false) &&
                      !(interaction.worker?.commandPending ?? false) &&
                      !(interaction.actionDeck?.commandPending ?? false) &&
                      !(interaction.unitLogistics?.commandPending ?? false),
                  onAction: onArtifactAction,
                ),
              _MovementFeedback(interaction: interaction),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MovementControls extends StatelessWidget {
  const _MovementControls({
    required this.interaction,
    required this.onConfirmMove,
  });

  final MapInteractionState interaction;
  final VoidCallback onConfirmMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final route = interaction.route;
    if (route == null) {
      return interaction.movementPending
          ? const SizedBox.shrink()
          : Text(l10n.chooseHighlightedDestination);
    }
    final commandPending =
        interaction.movementPending ||
        (interaction.actionDeck?.commandPending ?? false) ||
        (interaction.unitLogistics?.commandPending ?? false) ||
        (interaction.worker?.commandPending ?? false) ||
        (interaction.production?.commandPending ?? false) ||
        (interaction.artifact?.commandPending ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.routeSummary(route.totalCostUnits, route.remainingMovementUnits),
        ),
        const SizedBox(height: AonwSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('confirm-move'),
          onPressed: commandPending ? null : onConfirmMove,
          icon: const Icon(Icons.directions_walk),
          label: Text(l10n.confirmMove),
        ),
      ],
    );
  }
}

final class _MovementFeedback extends StatelessWidget {
  const _MovementFeedback({required this.interaction});

  final MapInteractionState interaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interaction.movementPending) ...[
          const SizedBox(height: AonwSpacing.sm),
          AonwProgressIndicator(semanticLabel: l10n.movingUnit, compact: true),
        ],
        if (interaction.movementError case final message?) ...[
          const SizedBox(height: AonwSpacing.sm),
          Text(
            movementFailureMessage(l10n, message),
            key: const ValueKey('movement-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
