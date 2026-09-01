part of 'map_selection_overlay.dart';

final class _SelectionFeatureControls extends StatelessWidget {
  const _SelectionFeatureControls({
    required this.coordinate,
    required this.interaction,
    required this.unit,
    required this.city,
    required this.player,
    required this.onConfirmCombat,
    required this.onCityConquestAction,
    required this.onToggleCityFoundingHex,
    required this.onConfirmCityFounding,
    required this.onCancelCityFounding,
    required this.onCityAction,
    required this.onProductionAction,
    required this.onArtifactAction,
  });

  final MapHexCoordinate coordinate;
  final MapInteractionState interaction;
  final VisibleUnitView? unit;
  final CityView? city;
  final PlayerMapView player;
  final VoidCallback onConfirmCombat;
  final ValueChanged<CityConquestActionView> onCityConquestAction;
  final ValueChanged<MapHexCoordinate> onToggleCityFoundingHex;
  final VoidCallback onConfirmCityFounding;
  final VoidCallback onCancelCityFounding;
  final ValueChanged<CityActionView> onCityAction;
  final ValueChanged<ProductionActionView> onProductionAction;
  final ValueChanged<ArtifactActionView> onArtifactAction;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _combatPanel(),
      _cityPanel(),
      _productionPanel(),
      _artifactPanel(),
      _MovementFeedback(interaction: interaction),
    ],
  );

  Widget _combatPanel() {
    final combat = interaction.combat;
    if (combat == null) return const SizedBox.shrink();
    return CombatPanel(
      state: combat,
      onConfirm: onConfirmCombat,
      onCityConquestAction: onCityConquestAction,
    );
  }

  Widget _cityPanel() {
    final state = interaction.city;
    if (state == null) return const SizedBox.shrink();
    return CityPanel(
      state: state,
      city: city,
      onToggleFoundingHex: onToggleCityFoundingHex,
      onConfirmFounding: onConfirmCityFounding,
      onCancelFounding: onCancelCityFounding,
      onAction: onCityAction,
      enabled:
          !(interaction.production?.commandPending ?? false) &&
          !(interaction.artifact?.commandPending ?? false),
    );
  }

  Widget _productionPanel() {
    final production = interaction.production;
    if (production == null) return const SizedBox.shrink();
    return ProductionPanel(
      state: production,
      enabled:
          !(interaction.city?.commandPending ?? false) &&
          !interaction.movementPending &&
          !(interaction.artifact?.commandPending ?? false),
      onAction: onProductionAction,
    );
  }

  Widget _artifactPanel() {
    final artifact = interaction.artifact;
    if (artifact == null) return const SizedBox.shrink();
    return ArtifactPanel(
      state: artifact,
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
    );
  }
}
