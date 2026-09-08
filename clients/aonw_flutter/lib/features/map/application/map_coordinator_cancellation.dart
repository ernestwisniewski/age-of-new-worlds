part of 'map_coordinator.dart';

extension MapCoordinatorCancellation on MapCoordinator {
  void cancelInteraction() {
    final current = _state;
    if (current is! GameSessionReady || !_gameplayActive()) return;
    if (_cancellationBlocked(current)) return;
    final interaction = current.interaction;
    if (interaction.city?.founderUnitId != null) {
      cancelCityFounding();
      return;
    }
    if (interaction.city?.managementMode != null) {
      cancelCityManagement();
      return;
    }
    if (interaction.worker?.actionsOpen == true) {
      setWorkerActionsOpen(false);
      return;
    }
    if (_hasUnitPreview(interaction)) {
      _cancelUnitPreview(current);
      return;
    }
    if (_availableSelectionState() == null) return;
    _interactionGeneration += 1;
    hover(null);
    _clearSelection(current);
  }

  void _cancelUnitPreview(GameSessionReady current) {
    _interactionGeneration += 1;
    final unitId = current.interaction.selectedUnitId;
    final unit = unitId == null
        ? null
        : current.recipient.controlledUnitById(unitId);
    if (unit == null) {
      _clearSelection(current);
      return;
    }
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: unit.coordinate,
          clearRoute: true,
          clearCombat: true,
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
    if (current.interaction.combat != null) {
      unawaited(_selectUnitById(unit.id));
    }
  }
}

bool _hasUnitPreview(MapInteractionState interaction) =>
    interaction.combat != null ||
    interaction.route != null ||
    (interaction.movementPending && interaction.reachable != null);

bool _cancellationBlocked(GameSessionReady current) =>
    current.research.commandPending ||
    current.diplomacy.commandPending ||
    _unitCommandPending(current.interaction) ||
    _cityCommandPending(current.interaction);

bool _unitCommandPending(MapInteractionState interaction) =>
    (interaction.movementPending && interaction.route != null) ||
    (interaction.combat?.commandPending ?? false) ||
    (interaction.actionDeck?.commandPending ?? false) ||
    (interaction.unitLogistics?.commandPending ?? false) ||
    (interaction.worker?.commandPending ?? false) ||
    (interaction.artifact?.commandPending ?? false);

bool _cityCommandPending(MapInteractionState interaction) =>
    (interaction.city?.commandPending ?? false) ||
    (interaction.production?.commandPending ?? false);
