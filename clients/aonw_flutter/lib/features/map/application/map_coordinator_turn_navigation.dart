part of 'map_coordinator.dart';

extension MapCoordinatorTurnNavigation on MapCoordinator {
  Future<void> navigateTurnActions({
    required int step,
    bool endWhenEmpty = false,
    AutomaticTurnPolicyBuilder? automatic,
    required bool Function() inputAvailable,
    void Function(PendingTurnActionView)? onFocused,
  }) => _turnNavigation.navigate(
    step: step,
    endWhenEmpty: endWhenEmpty,
    automatic: automatic,
    inputAvailable: inputAvailable,
    onFocused: onFocused,
  );

  void closeTurnResearch() {
    final current = _state;
    if (current is! GameSessionReady || !current.interaction.researchFocused) {
      return;
    }
    _interactionGeneration += 1;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(researchFocused: false),
      ),
    );
  }

  GameSessionReady? _turnNavigationState() {
    final current = _availableSelectionState();
    if (_disposed ||
        readOnly ||
        current == null ||
        current.turnAction.inFlight ||
        current.inspection != null ||
        current.recipient.turnView.ownSubmitted ||
        current.recipient.turnView.ownState != RecipientTurnStateView.active) {
      return null;
    }
    return current;
  }

  Object? _turnNavigationScope() {
    final current = _state;
    if (_disposed || current is! GameSessionReady) return null;
    final stamp = current.recipient.stamp;
    return (
      _loadGeneration,
      _interactionGeneration,
      current.scene.map.mapId,
      current.scene.map.contentHash,
      current.recipient.actorPlayerId,
      stamp.revision,
      stamp.stateDigest,
      stamp.mapHash,
      stamp.rulesetHash,
    );
  }

  Future<bool> _focusTurnAction(PendingTurnActionView action) async {
    final initial = _turnNavigationState();
    if (initial == null) return false;
    final current = initial.withTurnAction(
      initial.turnAction.copyWith(clearFailure: true),
    );
    _setState(current);
    final load = _loadGeneration;
    final stamp = current.recipient.stamp;
    Future<void>? selection;
    switch (action) {
      case PendingUnitTurnActionView(:final unitId, :final coordinate):
        if (current.recipient.controlledUnitById(unitId)?.coordinate !=
            coordinate) {
          return false;
        }
        selection = _selectUnitById(unitId);
      case PendingCityProductionTurnActionView(
        :final cityId,
        :final coordinate,
      ):
        final city = current.recipient.cityById(cityId);
        if (city?.ownerPlayerId != current.recipient.actorPlayerId ||
            city?.center != coordinate) {
          return false;
        }
        _selectCityById(cityId);
      case PendingResearchTurnActionView():
        _focusTurnResearch(current);
    }
    return _waitForTurnFocus(
      load,
      stamp.revision,
      _turnNavigationScope(),
      selection,
    );
  }

  void _focusTurnResearch(GameSessionReady current) {
    _interactionGeneration += 1;
    _setState(
      current.withInteraction(
        current.interaction.copyWith(
          researchFocused: true,
          moveTargeting: false,
          clearRoute: true,
          clearCombat: true,
          clearCity: current.interaction.city?.founderUnitId != null,
          city: current.interaction.city?.copyWith(clearManagementMode: true),
          worker: current.interaction.worker?.copyWith(
            actionsOpen: false,
            clearPreview: true,
          ),
        ),
      ),
    );
  }

  Future<bool> _waitForTurnFocus(
    int load,
    int revision,
    Object? scope,
    Future<void>? selection,
  ) async {
    if (selection != null) await selection;
    while (_isCurrent(load) && scope == _turnNavigationScope()) {
      final ready = _state;
      if (ready is! GameSessionReady ||
          ready.recipient.stamp.revision != revision) {
        return false;
      }
      if (!_interactionBusy(ready.interaction)) return true;
      await _changes.stream.first;
    }
    return false;
  }

  void _turnNavigationFailure(TurnSessionException error) {
    final current = _turnNavigationState();
    if (current == null) return;
    if (error.diagnosticCause case final cause?) {
      _diagnosticReporter(
        error.code,
        cause,
        error.diagnosticStackTrace ?? StackTrace.current,
      );
    }
    var ready = current;
    var code = error.code == 'invalid_session_protocol'
        ? TurnFailureViewCode.responseIncompatible
        : TurnFailureViewCode.requestFailed;
    if (error.resyncedPlayer case final player?) {
      if ((
            player.actorPlayerId,
            player.stamp.mapHash,
            player.stamp.rulesetHash,
          ) ==
          (
            current.recipient.actorPlayerId,
            current.recipient.stamp.mapHash,
            current.recipient.stamp.rulesetHash,
          )) {
        ready = current.withRecipient(player);
      } else {
        code = TurnFailureViewCode.responseIncompatible;
      }
    }
    _setState(
      ready.withTurnAction(
        ready.turnAction.copyWith(
          failure: TurnActionFailureView.transport(code),
        ),
      ),
    );
  }
}
