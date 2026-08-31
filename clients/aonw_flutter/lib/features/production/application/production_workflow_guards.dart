part of 'production_workflow.dart';

GameSessionReady? _selectedProduction(GameSessionState state, String cityId) =>
    state is GameSessionReady &&
        state.interaction.production?.cityId == cityId &&
        state.interaction.city?.cityId == cityId
    ? state
    : null;

GameSessionReady? _selectedProductionAtRevision(
  GameSessionState state,
  String cityId,
  int revision,
) {
  final ready = _selectedProduction(state, cityId);
  return ready?.recipient.stamp.revision == revision ? ready : null;
}

GameSessionReady? _executableProduction(
  GameSessionState state,
  ProductionActionView action,
) {
  final current = _selectedProduction(state, action.cityId);
  final production = current?.interaction.production;
  if (current == null ||
      current.research.commandPending ||
      current.diplomacy.commandPending ||
      production == null ||
      production.loading ||
      production.commandPending ||
      (current.interaction.city?.loading ?? false) ||
      (current.interaction.city?.commandPending ?? false) ||
      production.options?.stamp.revision != current.recipient.stamp.revision ||
      !_containsProductionAction(production.options, action)) {
    return null;
  }
  return current;
}

bool _containsProductionAction(
  ProductionOptionsView? options,
  ProductionActionView action,
) {
  if (options == null || options.cityId != action.cityId) return false;
  return switch (action) {
    StartBuildingActionView(:final building) => options.buildings.any(
      (value) =>
          value.blocker == null &&
          value.target is BuildingProductionTargetView &&
          (value.target as BuildingProductionTargetView).building == building,
    ),
    StartUnitProductionActionView(:final unit, :final resourceOptionIndex) =>
      options.units.any((value) {
        final target = value.option.target;
        if (value.option.blocker != null ||
            target is! UnitProductionTargetView ||
            target.unit != unit) {
          return false;
        }
        if (value.resourceOptions.isEmpty) return resourceOptionIndex == null;
        return resourceOptionIndex != null &&
            value.affordableResourceOptionIndices.contains(resourceOptionIndex);
      }),
    StartCityProjectActionView(:final project) => options.projects.any(
      (value) =>
          value.blocker == null &&
          value.target is ProjectProductionTargetView &&
          (value.target as ProjectProductionTargetView).project == project,
    ),
    StartWonderActionView(:final wonder) => options.wonders.any(
      (value) =>
          value.blocker == null &&
          value.target is WonderProductionTargetView &&
          (value.target as WonderProductionTargetView).wonder == wonder,
    ),
    SetCitySpecializationActionView(:final specialization) =>
      options.specializations.any(
        (value) =>
            value.blocker == null && value.specialization == specialization,
      ),
    RushProductionActionView() => options.currentTarget != null,
  };
}

GameSessionReady? _correlatedProduction(
  GameSessionState state,
  String cityId,
  int correlationId,
) {
  final ready = _selectedProduction(state, cityId);
  return ready?.interaction.production?.correlationId == correlationId
      ? ready
      : null;
}

ProductionFailureCode _productionFailureCode(String code) => switch (code) {
  'invalid_session_protocol' => ProductionFailureCode.responseIncompatible,
  'session_not_open' => ProductionFailureCode.sessionUnavailable,
  _ => ProductionFailureCode.requestFailed,
};
