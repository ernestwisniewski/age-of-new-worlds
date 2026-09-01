part of 'map_coordinator.dart';

extension MapCoordinatorSelection on MapCoordinator {
  Future<void> _selectUnitById(String unitId) async {
    final current = _availableSelectionState();
    if (current == null) return;
    final unit = current.recipient.visibleUnitById(unitId);
    if (unit == null) return;
    final controlled = current.recipient.controlledUnitById(unitId);
    if (controlled == null) {
      _interactionGeneration += 1;
      _selectPlainHex(current, unit.coordinate);
      return;
    }
    final generation = ++_interactionGeneration;
    await _selectControlledUnit(
      current,
      controlled.coordinate,
      controlled,
      current.recipient.cityAt(controlled.coordinate),
      generation,
    );
  }

  void _selectCityById(String cityId) {
    final current = _availableSelectionState();
    if (current == null) return;
    final city = current.recipient.cityById(cityId);
    if (city == null) return;
    _interactionGeneration += 1;
    _selectCity(current, city.center, city);
  }

  GameSessionReady? _availableSelectionState() {
    final current = _state;
    if (current is! GameSessionReady ||
        !_gameplayActive() ||
        current.research.commandPending ||
        current.diplomacy.commandPending ||
        _interactionBusy(current.interaction)) {
      return null;
    }
    return current;
  }

  Future<void> _select(MapHexCoordinate? coordinate) async {
    final current = _availableSelectionState();
    if (current == null) return;
    final next = _selectableCoordinate(current, coordinate);
    final generation = ++_interactionGeneration;
    if (next == null) {
      _clearSelection(current);
      return;
    }

    final unit = current.recipient.controlledUnitAt(next);
    if (unit != null) {
      await _selectControlledUnit(
        current,
        next,
        unit,
        current.recipient.cityAt(next),
        generation,
      );
      return;
    }

    final selectedUnitId = current.interaction.selectedUnitId;
    if (selectedUnitId != null) {
      if (_hasVisibleForeignTarget(current.recipient, next)) {
        _combat.preview(
          attackerUnitId: selectedUnitId,
          defender: next,
          readState: () => _state,
          publish: _setState,
          isDisposed: () => _disposed,
        );
        return;
      }
      await _previewRoute(current, next, selectedUnitId, generation);
      return;
    }

    final city = current.recipient.cityAt(next);
    if (city != null) {
      _selectCity(current, next, city);
      return;
    }

    _selectPlainHex(current, next);
  }

  void _clearSelection(GameSessionReady current) {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          clearSelected: true,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          clearProduction: true,
          clearArtifact: true,
          clearCombat: true,
          clearCity: true,
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
  }

  void _selectPlainHex(GameSessionReady current, MapHexCoordinate coordinate) {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: coordinate,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          clearProduction: true,
          artifact: const ArtifactState(),
          clearCombat: true,
          clearCity: true,
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
  }

  void _selectCity(
    GameSessionReady current,
    MapHexCoordinate coordinate,
    CityView city,
  ) {
    final owned = city.ownedDetails != null;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: coordinate,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          production: owned ? ProductionState.loading(city.id) : null,
          clearProduction: !owned,
          artifact: const ArtifactState(),
          clearCombat: true,
          city: owned
              ? CityState.loadingCity(city.id)
              : CityState(cityId: city.id),
          movementPending: false,
          clearMovementError: true,
        ),
      ),
    );
    if (owned) {
      _cities.inspect(
        cityId: city.id,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
      _production.load(
        cityId: city.id,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
  }

  Future<void> _selectControlledUnit(
    GameSessionReady current,
    MapHexCoordinate coordinate,
    VisibleUnitView unit,
    CityView? city,
    int generation,
  ) async {
    final unitId = unit.id;
    final isWorker = unit.kind == VisibleUnitKind.worker;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: coordinate,
          selectedUnitId: unitId,
          actionDeck: ActionDeckViewState(unitId: unitId),
          unitLogistics: UnitLogisticsState.loading(unitId),
          worker: isWorker ? WorkerState.loading(unitId) : null,
          clearWorker: !isWorker,
          production: city?.ownedDetails == null
              ? null
              : ProductionState.loading(city!.id),
          clearProduction: city?.ownedDetails == null,
          artifact: const ArtifactState(),
          clearReachable: true,
          clearRoute: true,
          movementPending: true,
          clearMovementError: true,
          clearCombat: true,
          city: city == null
              ? null
              : city.ownedDetails == null
              ? CityState(cityId: city.id)
              : CityState.loadingCity(city.id),
          clearCity: city == null,
        ),
      ),
    );
    final reachable = _movement.reachable(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
    );
    final completion = await reachable;
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    final failure = completion.failure;
    _setState(
      failure == null
          ? ready.withInteraction(
              ready.interaction.copyWith(
                reachable: completion.result!,
                movementPending: false,
              ),
            )
          : _movementFailureState(ready, completion),
    );

    if (_currentInteraction(generation) == null) return;
    _logistics.load(
      unitId: unitId,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
    if (isWorker) {
      _workers.load(
        unitId: unitId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
    if (city?.ownedDetails != null) {
      _cities.inspect(
        cityId: city!.id,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
      _production.load(
        cityId: city.id,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
  }

  Future<void> _previewRoute(
    GameSessionReady current,
    MapHexCoordinate target,
    String unitId,
    int generation,
  ) async {
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: target,
          clearRoute: true,
          movementPending: true,
          clearMovementError: true,
        ),
      ),
    );
    final completion = await _movement.routePlan(
      expectedRevision: current.recipient.stamp.revision,
      unitId: unitId,
      target: target,
    );
    final ready = _currentInteraction(generation);
    if (ready == null) return;
    final failure = completion.failure;
    _setState(
      failure == null
          ? ready.withInteraction(
              ready.interaction.copyWith(
                route: completion.result!,
                movementPending: false,
              ),
            )
          : _movementFailureState(ready, completion),
    );
  }
}

MapHexCoordinate? _selectableCoordinate(
  GameSessionReady current,
  MapHexCoordinate? coordinate,
) => coordinate != null && current.scene.map.contains(coordinate)
    ? coordinate
    : null;

bool _hasVisibleForeignTarget(
  PlayerMapView player,
  MapHexCoordinate coordinate,
) {
  if (player
      .unitsAt(coordinate)
      .any((unit) => unit.ownerPlayerId != player.actorPlayerId)) {
    return true;
  }
  final city = player.cityAt(coordinate);
  return city != null && city.ownerPlayerId != player.actorPlayerId;
}
