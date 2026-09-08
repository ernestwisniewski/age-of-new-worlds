part of 'map_selection_overlay.dart';

final class _SelectedUnitMovement extends StatelessWidget {
  const _SelectedUnitMovement({
    required this.interaction,
    required this.foundingActive,
    required this.onConfirmMove,
  });

  final MapInteractionState interaction;
  final bool foundingActive;
  final VoidCallback onConfirmMove;

  @override
  Widget build(BuildContext context) =>
      foundingActive || interaction.combat != null
      ? const SizedBox.shrink()
      : _MovementControls(
          interaction: interaction,
          onConfirmMove: onConfirmMove,
        );
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
      return interaction.moveTargeting && !interaction.movementPending
          ? Text(l10n.chooseHighlightedDestination)
          : const SizedBox.shrink();
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

final class _MoveTargetingToggle extends StatelessWidget {
  const _MoveTargetingToggle({required this.active, required this.onToggle});
  final bool active;
  final VoidCallback? onToggle;
  @override
  Widget build(BuildContext context) => FilterChip(
    key: const ValueKey('unit-move-targeting'),
    selected: active,
    label: Text(context.aonwL10n.moveTargeting),
    avatar: const Icon(Icons.directions_walk),
    onSelected: onToggle == null ? null : (_) => onToggle!(),
  );
}
