import 'package:flutter/material.dart';

import '../../../../design_system/aonw_tokens.dart';
import '../../../../design_system/widgets/aonw_hud_surface.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../l10n/l10n.dart';
import '../../../artifacts/presentation/artifact_panel.dart';
import '../../../artifacts/read_model/artifact_view.dart';
import '../../../audio/presentation/game_audio_actions.dart';
import '../../../cities/application/city_state.dart';
import '../../../cities/presentation/city_copy.dart';
import '../../../cities/presentation/city_panel.dart';
import '../../../cities/read_model/city_view.dart';
import '../../../combat/presentation/combat_panel.dart';
import '../../../combat/read_model/combat_view.dart';
import '../../../logistics/read_model/unit_logistics_view.dart';
import '../../../production/presentation/production_copy.dart';
import '../../../unit_actions/presentation/unit_action_deck.dart';
import '../../../unit_actions/read_model/unit_action_view.dart';
import '../../../workers/presentation/worker_panel.dart';
import '../../../workers/read_model/worker_view.dart';
import '../../application/map_interaction_state.dart';
import '../../read_model/map_scene.dart';
import '../../read_model/map_view.dart';
import '../../read_model/pending_action_view.dart';
import '../../read_model/player_map_view.dart';
import '../input/map_gamepad_navigation.dart';
import '../map_presentation_controller.dart';
import 'map_failure_messages.dart';
import 'map_gamepad_region.dart';

part 'map_selection_feature_controls.dart';
part 'map_selection_movement_controls.dart';

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
      child: MapGamepadRegion(
        section: MapHudSection.selectionActions,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(10, 0, 10, 66),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _MapSelectionPanel(
              readOnly: controller.readOnly,
              coordinate: selected,
              interaction: interaction,
              unit: selectedUnitId == null
                  ? null
                  : scene.player.controlledUnitById(selectedUnitId),
              city: interaction.city?.cityId == null
                  ? scene.player.cityAt(selected)
                  : scene.player.cityById(interaction.city!.cityId!),
              player: scene.player,
              onConfirmMove: controller.confirmMove,
              onToggleMoveTargeting: controller.canToggleMoveTargeting
                  ? controller.toggleMoveTargeting
                  : null,
              onUnitAction: controller.executeUnitAction,
              onUnitLogistics: controller.executeUnitLogistics,
              onWorkerAction: controller.executeWorkerAction,
              onWorkerOpenChanged: controller.setWorkerActionsOpen,
              onWorkerPreview: (kind) => controller.previewWorkerImprovement(
                interaction.worker!.unitId,
                kind,
              ),
              onConfirmCombat: controller.confirmCombat,
              onCityConquestAction: controller.setCityConquestAction,
              onOpenCityFounding: controller.openCityFounding,
              onToggleCityFoundingHex: controller.toggleCityFoundingHex,
              onConfirmCityFounding: controller.confirmCityFounding,
              onCancelCityFounding: controller.cancelCityFounding,
              onStartCityManagement: controller.startCityManagement,
              onCancelCityManagement: controller.cancelCityManagement,
              onOpenProduction: () {
                context.playGameSound(GameSoundCue.uiPanelOpen);
                controller.setProductionCatalogOpen(true);
              },
              onArtifactAction: controller.executeArtifactAction,
            ),
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
    required this.readOnly,
    required this.unit,
    required this.city,
    required this.player,
    required this.onConfirmMove,
    required this.onToggleMoveTargeting,
    required this.onUnitAction,
    required this.onUnitLogistics,
    required this.onWorkerAction,
    required this.onWorkerOpenChanged,
    required this.onWorkerPreview,
    required this.onConfirmCombat,
    required this.onCityConquestAction,
    required this.onOpenCityFounding,
    required this.onToggleCityFoundingHex,
    required this.onConfirmCityFounding,
    required this.onCancelCityFounding,
    required this.onStartCityManagement,
    required this.onCancelCityManagement,
    required this.onOpenProduction,
    required this.onArtifactAction,
  });

  final MapHexCoordinate coordinate;
  final bool readOnly;
  final MapInteractionState interaction;
  final VisibleUnitView? unit;
  final CityView? city;
  final PlayerMapView player;
  final VoidCallback onConfirmMove;
  final VoidCallback? onToggleMoveTargeting;
  final ValueChanged<UnitActionKindView> onUnitAction;
  final ValueChanged<UnitLogisticsActionView> onUnitLogistics;
  final ValueChanged<WorkerActionView> onWorkerAction;
  final ValueChanged<bool> onWorkerOpenChanged;
  final ValueChanged<FieldImprovementKind> onWorkerPreview;
  final VoidCallback onConfirmCombat;
  final ValueChanged<CityConquestActionView> onCityConquestAction;
  final VoidCallback onOpenCityFounding;
  final ValueChanged<MapHexCoordinate> onToggleCityFoundingHex;
  final VoidCallback onConfirmCityFounding;
  final VoidCallback onCancelCityFounding;
  final ValueChanged<CityManagementMode> onStartCityManagement;
  final VoidCallback onCancelCityManagement;
  final VoidCallback onOpenProduction;
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
              if (interaction.selectedUnitId case final unitId?)
                _SelectedUnitControls(
                  readOnly: readOnly,
                  unitId: unitId,
                  interaction: interaction,
                  unit: unit,
                  onConfirmMove: onConfirmMove,
                  onToggleMoveTargeting: onToggleMoveTargeting,
                  onUnitAction: onUnitAction,
                  onUnitLogistics: onUnitLogistics,
                  onWorkerAction: onWorkerAction,
                  onWorkerOpenChanged: onWorkerOpenChanged,
                  onWorkerPreview: onWorkerPreview,
                  onOpenCityFounding: onOpenCityFounding,
                ),
              _SelectionFeatureControls(
                readOnly: readOnly,
                coordinate: coordinate,
                interaction: interaction,
                unit: unit,
                city: city,
                player: player,
                onConfirmCombat: onConfirmCombat,
                onCityConquestAction: onCityConquestAction,
                onToggleCityFoundingHex: onToggleCityFoundingHex,
                onConfirmCityFounding: onConfirmCityFounding,
                onCancelCityFounding: onCancelCityFounding,
                onStartCityManagement: onStartCityManagement,
                onCancelCityManagement: onCancelCityManagement,
                onOpenProduction: onOpenProduction,
                onArtifactAction: onArtifactAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SelectedUnitControls extends StatelessWidget {
  const _SelectedUnitControls({
    required this.unitId,
    required this.interaction,
    required this.readOnly,
    required this.unit,
    required this.onConfirmMove,
    required this.onToggleMoveTargeting,
    required this.onUnitAction,
    required this.onUnitLogistics,
    required this.onWorkerAction,
    required this.onWorkerOpenChanged,
    required this.onWorkerPreview,
    required this.onOpenCityFounding,
  });

  final String unitId;
  final bool readOnly;
  final MapInteractionState interaction;
  final VisibleUnitView? unit;
  final VoidCallback onConfirmMove;
  final VoidCallback? onToggleMoveTargeting;
  final ValueChanged<UnitActionKindView> onUnitAction;
  final ValueChanged<UnitLogisticsActionView> onUnitLogistics;
  final ValueChanged<WorkerActionView> onWorkerAction;
  final ValueChanged<bool> onWorkerOpenChanged;
  final ValueChanged<FieldImprovementKind> onWorkerPreview;
  final VoidCallback onOpenCityFounding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final foundingActive = interaction.city?.founderUnitId != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AonwSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.unitLabel(unitId)),
                  if (unit case final unit?)
                    Text(l10n.presentationName(unit.kind.name)),
                ],
              ),
            ),
            if (!foundingActive && interaction.worker?.actionsOpen != true)
              _MoveTargetingToggle(
                active: interaction.moveTargeting,
                onToggle: onToggleMoveTargeting,
              ),
          ],
        ),
        _SelectedUnitMovement(
          interaction: interaction,
          foundingActive: foundingActive,
          onConfirmMove: onConfirmMove,
        ),
        _SelectedUnitActionDeck(
          readOnly: readOnly,
          interaction: interaction,
          foundingActive: foundingActive,
          onAction: onUnitAction,
          onLogisticsAction: onUnitLogistics,
        ),
        _SelectedWorkerControls(
          readOnly: readOnly,
          interaction: interaction,
          unit: unit,
          foundingActive: foundingActive,
          onAction: onWorkerAction,
          onOpenChanged: onWorkerOpenChanged,
          onPreview: onWorkerPreview,
        ),
        if (!readOnly && !foundingActive && _canOfferCityFounding(unit))
          TextButton.icon(
            key: const ValueKey('open-city-founding'),
            onPressed: onOpenCityFounding,
            icon: const Icon(Icons.add_location_alt),
            label: Text(CityCopy.of(context).text(CityText.foundingOpen)),
          ),
      ],
    );
  }
}

final class _SelectedUnitActionDeck extends StatelessWidget {
  const _SelectedUnitActionDeck({
    required this.interaction,
    required this.readOnly,
    required this.foundingActive,
    required this.onAction,
    required this.onLogisticsAction,
  });

  final bool readOnly;
  final MapInteractionState interaction;
  final bool foundingActive;
  final ValueChanged<UnitActionKindView> onAction;
  final ValueChanged<UnitLogisticsActionView> onLogisticsAction;

  @override
  Widget build(BuildContext context) {
    final actionDeck = interaction.actionDeck;
    if (foundingActive || actionDeck == null) return const SizedBox.shrink();
    return UnitActionDeck(
      state: actionDeck,
      logistics: interaction.unitLogistics,
      enabled:
          !readOnly &&
          !interaction.movementPending &&
          !(interaction.worker?.commandPending ?? false) &&
          !(interaction.production?.commandPending ?? false) &&
          !(interaction.artifact?.commandPending ?? false),
      onAction: onAction,
      onLogisticsAction: onLogisticsAction,
    );
  }
}

final class _SelectedWorkerControls extends StatelessWidget {
  const _SelectedWorkerControls({
    required this.interaction,
    required this.readOnly,
    required this.unit,
    required this.onOpenChanged,
    required this.onPreview,
    required this.foundingActive,
    required this.onAction,
  });

  final bool readOnly;
  final MapInteractionState interaction;
  final VisibleUnitView? unit;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<FieldImprovementKind> onPreview;
  final bool foundingActive;
  final ValueChanged<WorkerActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final worker = interaction.worker;
    final selectedUnit = unit;
    if (foundingActive || worker == null || selectedUnit == null) {
      return const SizedBox.shrink();
    }
    return WorkerPanel(
      readOnly: readOnly,
      state: worker,
      unit: selectedUnit,
      onOpenChanged: onOpenChanged,
      onPreview: onPreview,
      enabled:
          !interaction.movementPending &&
          !(interaction.actionDeck?.commandPending ?? false) &&
          !(interaction.unitLogistics?.commandPending ?? false) &&
          !(interaction.production?.commandPending ?? false) &&
          !(interaction.artifact?.commandPending ?? false),
      onAction: onAction,
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

bool _canOfferCityFounding(VisibleUnitView? unit) {
  if (unit == null) return false;
  if (unit.kind == VisibleUnitKind.settler) return true;
  return unit.kind == VisibleUnitKind.commander &&
      unit.army.any((troop) => troop.kind == 'settler' && troop.count > 0);
}
