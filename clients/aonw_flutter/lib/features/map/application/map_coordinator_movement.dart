part of 'map_coordinator.dart';

extension MapCoordinatorMovement on MapCoordinator {
  Future<void> _confirmMove() async {
    final current = _state;
    if (current is! GameSessionReady ||
        !_gameplayActive() ||
        current.research.commandPending ||
        current.diplomacy.commandPending ||
        _interactionBusy(current.interaction)) {
      return;
    }
    final route = current.interaction.route;
    final unitId = current.interaction.selectedUnitId;
    if (route == null || unitId == null) return;
    final generation = ++_interactionGeneration;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    final completion = await _movement.moveUnit(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      target: route.target,
    );
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    _completeMovement(ready, current, completion, unitId, route);
  }

  void _completeMovement(
    GameSessionReady ready,
    GameSessionReady original,
    MovementCommandCompletion<MoveUnitResultView> completion,
    String unitId,
    RoutePlanView route,
  ) {
    if (completion.failure != null) {
      _setState(_movementFailureState(ready, completion));
    } else {
      _setState(
        _moveResultState(ready, completion.result!, unitId, route.destination),
      );
      if (completion.result!.accepted) {
        _refreshUnitOptions(unitId);
        unawaited(
          _loadMovementAvailability(
            unitId,
            retainTargeting: original.interaction.moveTargeting,
          ),
        );
      }
    }
  }

  void _refreshUnitOptions(String unitId) {
    final current = _state;
    if (current is! GameSessionReady ||
        current.recipient.controlledUnitById(unitId) == null) {
      return;
    }
    _logistics.load(
      unitId: unitId,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
    if (current.recipient.controlledUnitById(unitId)?.kind ==
        VisibleUnitKind.worker) {
      _workers.load(
        unitId: unitId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
  }
}

GameSessionReady _moveResultState(
  GameSessionReady current,
  MoveUnitResultView result,
  String unitId,
  MapHexCoordinate routeDestination,
) {
  if (!result.accepted) {
    return current.withInteraction(
      current.interaction.copyWith(
        movementPending: false,
        movementError: MapMovementFailure.rejected(result.rejectionCode!),
      ),
    );
  }
  final player = result.player!;
  final unit = player.controlledUnitById(unitId);
  final movedCoordinate = unit?.coordinate ?? routeDestination;
  return current
      .withRecipient(player)
      .withInteraction(
        current.interaction.copyWith(
          selected: movedCoordinate,
          selectedUnitId: unitId,
          clearSelectedUnit: unit == null,
          moveTargeting: false,
          clearCity: true,
          clearReachable: true,
          clearRoute: true,
          actionDeck: ActionDeckViewState(unitId: unitId),
          clearActionDeck: unit == null,
          unitLogistics: UnitLogisticsState.loading(unitId),
          clearUnitLogistics: unit == null,
          worker: unit?.kind == VisibleUnitKind.worker
              ? WorkerState.loading(unitId)
              : null,
          clearWorker: unit?.kind != VisibleUnitKind.worker,
          clearProduction: true,
          clearArtifact: true,
          clearCombat: true,
          movementPending: false,
          clearMovementError: true,
          lastMovementExecution: result.execution,
        ),
      );
}
