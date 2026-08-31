part of 'map_coordinator.dart';

extension MapCoordinatorActions on MapCoordinator {
  void inspectSelectedCity(String cityId) {
    final current = _state;
    if (current is! GameSessionReady ||
        current.recipient.turnView.outcome.isTerminal ||
        current.localHandoff.blocksGameplay) {
      return;
    }
    final city = current.recipient.cityById(cityId);
    if (city == null) return;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          selected: city.center,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          production: city.ownedDetails == null
              ? null
              : ProductionState.loading(cityId),
          clearProduction: city.ownedDetails == null,
          artifact: const ArtifactState(),
          clearCombat: true,
          city: city.ownedDetails == null
              ? CityState(cityId: cityId)
              : CityState.loadingCity(cityId),
        ),
      ),
    );
    if (city.ownedDetails != null) {
      _cities.inspect(
        cityId: cityId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
      _production.load(
        cityId: cityId,
        readState: () => _state,
        publish: _setState,
        isDisposed: () => _disposed,
      );
    }
  }

  void openCityFounding() {
    final state = _state;
    if (state is! GameSessionReady ||
        state.recipient.turnView.outcome.isTerminal ||
        state.localHandoff.blocksGameplay) {
      return;
    }
    final unitId = state.interaction.selectedUnitId;
    if (unitId == null) return;
    _cities.openFounding(
      founderUnitId: unitId,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void toggleCityFoundingHex(MapHexCoordinate coordinate) {
    if (!_gameplayActive()) return;
    _cities.toggleFoundingHex(
      coordinate: coordinate,
      readState: () => _state,
      publish: _setState,
    );
  }

  void confirmCityFounding() {
    if (!_gameplayActive()) return;
    _cities.confirmFounding(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void executeCityAction(CityActionView action) {
    if (!_gameplayActive()) return;
    _cities.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
      onSelectionRetained: (cityId) {
        final state = _state;
        if (state is! GameSessionReady ||
            state.interaction.city?.cityId != cityId) {
          return;
        }
        _setState(
          state.withInteraction(
            state.interaction.copyWith(
              production: ProductionState.loading(cityId),
            ),
          ),
        );
        _production.load(
          cityId: cityId,
          readState: () => _state,
          publish: _setState,
          isDisposed: () => _disposed,
        );
      },
    );
  }

  void executeProductionAction(ProductionActionView action) {
    if (!_gameplayActive()) return;
    _production.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void executeArtifactAction(ArtifactActionView action) {
    if (!_gameplayActive()) return;
    _artifacts.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
      refreshSelection: () {
        final state = _state;
        if (state is GameSessionReady && state.interaction.selected != null) {
          unawaited(_select(state.interaction.selected));
        }
      },
    );
  }

  void selectTechnology(TechnologyIdView technology) {
    if (!_gameplayActive()) return;
    _research.select(
      technology: technology,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void refreshResearch() {
    final state = _state;
    if (state is! GameSessionReady || state.research.loading) return;
    _setState(
      state.withResearch(ResearchState.loading(state.recipient.stamp.revision)),
    );
  }

  void executeDiplomacyAction(DiplomacyActionView action) {
    if (!_gameplayActive()) return;
    _diplomacy.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void executeUnitAction(UnitActionKindView action) {
    if (!_gameplayActive()) return;
    _unitActions.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
      onSelectionRetained: (unitId) {
        _logistics.load(
          unitId: unitId,
          readState: () => _state,
          publish: _setState,
          isDisposed: () => _disposed,
        );
        final state = _state;
        if (state is GameSessionReady &&
            state.recipient.controlledUnitById(unitId)?.kind ==
                VisibleUnitKind.worker) {
          _workers.load(
            unitId: unitId,
            readState: () => _state,
            publish: _setState,
            isDisposed: () => _disposed,
          );
        }
      },
    );
  }

  void executeWorkerAction(WorkerActionView action) {
    if (!_gameplayActive()) return;
    _workers.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void executeUnitLogistics(UnitLogisticsActionView action) {
    if (!_gameplayActive()) return;
    _logistics.execute(
      action: action,
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void confirmCombat() {
    if (!_gameplayActive()) return;
    _combat.attack(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
    );
  }

  void setCityConquestAction(CityConquestActionView action) {
    if (!_gameplayActive()) return;
    _combat.setCityConquestAction(
      action: action,
      readState: () => _state,
      publish: _setState,
    );
  }

  void endTurn() {
    if (!_gameplayActive()) return;
    _turns.endTurn(
      readState: () => _state,
      publish: _setState,
      isDisposed: () => _disposed,
      onAccepted: _advanceLocalTurns,
    );
  }

  void toggleReference() {
    final current = _state;
    if (current is! GameSessionReady) return;
    _setState(_toggleReferenceState(current));
  }

  void completeTurnPresentation() {
    if (_state case final GameSessionReady current) {
      _setState(current.completeTurnPresentation());
    }
  }
}
