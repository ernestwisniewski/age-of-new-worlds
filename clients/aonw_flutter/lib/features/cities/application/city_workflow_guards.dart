part of 'city_workflow.dart';

GameSessionReady? _selectedCity(GameSessionState state, String cityId) =>
    state is GameSessionReady && state.interaction.city?.cityId == cityId
    ? state
    : null;

GameSessionReady? _selectedUnit(GameSessionState state, String unitId) =>
    state is GameSessionReady && state.interaction.selectedUnitId == unitId
    ? state
    : null;

GameSessionReady? _selectedCityAtRevision(
  GameSessionState state,
  String cityId,
  int revision,
) {
  final ready = _selectedCity(state, cityId);
  return ready?.recipient.stamp.revision == revision ? ready : null;
}

GameSessionReady? _selectedUnitAtRevision(
  GameSessionState state,
  String unitId,
  int revision,
) {
  final ready = _selectedUnit(state, unitId);
  return ready?.recipient.stamp.revision == revision ? ready : null;
}

GameSessionReady? _executable(GameSessionState state, CityActionView action) {
  if (state is! GameSessionReady) return null;
  final city = state.interaction.city;
  if (city == null ||
      state.research.commandPending ||
      state.diplomacy.commandPending ||
      city.loading ||
      city.commandPending ||
      (state.interaction.production?.loading ?? false) ||
      (state.interaction.production?.commandPending ?? false)) {
    return null;
  }
  final allowed = switch (action) {
    final FoundCityActionView value => _matchesFounding(city, value),
    final ToggleWorkedHexActionView value => _matchesWorkedHex(city, value),
    final SelectCityExpansionActionView value => _matchesExpansion(city, value),
  };
  return allowed ? state : null;
}

bool _matchesFounding(CityState city, FoundCityActionView action) =>
    city.founderUnitId == action.founderUnitId &&
    city.foundingOptions?.requiredControlledHexes ==
        action.controlledHexes.length &&
    action.controlledHexes.every(city.foundingSelection.contains);

bool _matchesWorkedHex(CityState city, ToggleWorkedHexActionView action) =>
    city.cityId == action.cityId &&
    (city.inspection?.workedHexes.availableHexes.contains(action.target) ??
        false);

bool _matchesExpansion(CityState city, SelectCityExpansionActionView action) =>
    city.cityId == action.cityId &&
    (city.inspection?.expansion.candidates.any(
          (candidate) => candidate.coordinate == action.target,
        ) ??
        false);

GameSessionReady? _correlated(GameSessionState state, int correlationId) =>
    state is GameSessionReady &&
        state.interaction.city?.correlationId == correlationId
    ? state
    : null;

GameSessionReady _pending(
  GameSessionReady current,
  CityActionView action,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    city: current.interaction.city!.copyWith(
      correlationId: correlationId,
      inFlightAction: action,
      clearFailure: true,
    ),
  ),
);

GameSessionReady _rejected(
  GameSessionReady current,
  CityRejectionCodeView code,
) => current.withInteraction(
  current.interaction.copyWith(
    city: current.interaction.city!.copyWith(
      clearInFlightAction: true,
      failure: CityFailureView.rejected(code),
    ),
  ),
);

GameSessionReady _accepted(
  GameSessionReady current,
  PlayerMapView player,
  CityActionView action,
) {
  final synchronized = current.withRecipient(player);
  if (action is FoundCityActionView) {
    return synchronized.withInteraction(
      synchronized.interaction.copyWith(
        clearSelected: true,
        clearSelectedUnit: true,
        clearReachable: true,
        clearRoute: true,
        clearActionDeck: true,
        clearUnitLogistics: true,
        clearCity: true,
        clearProduction: true,
      ),
    );
  }
  final cityId = switch (action) {
    ToggleWorkedHexActionView(:final cityId) => cityId,
    SelectCityExpansionActionView(:final cityId) => cityId,
    FoundCityActionView() => throw StateError('Handled above.'),
  };
  final managementMode = current.interaction.city?.managementMode;
  final city = synchronized.recipient.controlledCityById(cityId);
  if (city == null) {
    return synchronized.withInteraction(
      synchronized.interaction.copyWith(clearCity: true, clearProduction: true),
    );
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      selected: city.center,
      city: CityState.loadingCity(cityId, managementMode: managementMode),
      clearProduction: true,
    ),
  );
}

CityFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => CityFailureCode.responseIncompatible,
  'session_not_open' => CityFailureCode.sessionUnavailable,
  _ => CityFailureCode.requestFailed,
};
