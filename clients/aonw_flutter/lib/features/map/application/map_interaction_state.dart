import '../../artifacts/application/artifact_state.dart';
import '../../cities/application/city_state.dart';
import '../../combat/application/combat_state.dart';
import '../../logistics/application/unit_logistics_state.dart';
import '../../production/application/production_state.dart';
import '../../unit_actions/application/action_deck_state.dart';
import '../../workers/application/worker_state.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';

enum MapMovementFailureViewCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  moveRejected,
}

final class MapMovementFailure {
  const MapMovementFailure(this.code) : rejectionCode = null;

  const MapMovementFailure.rejected(this.rejectionCode)
    : code = MapMovementFailureViewCode.moveRejected;

  final MapMovementFailureViewCode code;
  final CommandRejectionCodeView? rejectionCode;
}

final class MapInteractionState {
  const MapInteractionState({
    this.selected,
    this.selectedUnitId,
    this.reachable,
    this.route,
    this.movementPending = false,
    this.movementError,
    this.lastMovementExecution,
    this.actionDeck,
    this.unitLogistics,
    this.combat,
    this.city,
    this.worker,
    this.production,
    this.artifact,
    this.referenceVisible = true,
  });

  final MapHexCoordinate? selected;
  final String? selectedUnitId;
  final ReachableView? reachable;
  final RoutePlanView? route;
  final bool movementPending;
  final MapMovementFailure? movementError;
  final MoveUnitExecutionView? lastMovementExecution;
  final ActionDeckViewState? actionDeck;
  final UnitLogisticsState? unitLogistics;
  final CombatState? combat;
  final CityState? city;
  final WorkerState? worker;
  final ProductionState? production;
  final ArtifactState? artifact;
  final bool referenceVisible;

  MapInteractionState copyWith({
    MapHexCoordinate? selected,
    bool clearSelected = false,
    String? selectedUnitId,
    bool clearSelectedUnit = false,
    ReachableView? reachable,
    bool clearReachable = false,
    RoutePlanView? route,
    bool clearRoute = false,
    bool? movementPending,
    MapMovementFailure? movementError,
    bool clearMovementError = false,
    MoveUnitExecutionView? lastMovementExecution,
    ActionDeckViewState? actionDeck,
    bool clearActionDeck = false,
    UnitLogisticsState? unitLogistics,
    bool clearUnitLogistics = false,
    CombatState? combat,
    bool clearCombat = false,
    CityState? city,
    bool clearCity = false,
    WorkerState? worker,
    bool clearWorker = false,
    ProductionState? production,
    bool clearProduction = false,
    ArtifactState? artifact,
    bool clearArtifact = false,
    bool? referenceVisible,
  }) => MapInteractionState(
    selected: _replaceNullable(this.selected, selected, clearSelected),
    selectedUnitId: _replaceNullable(
      this.selectedUnitId,
      selectedUnitId,
      clearSelectedUnit,
    ),
    reachable: _replaceNullable(this.reachable, reachable, clearReachable),
    route: _replaceNullable(this.route, route, clearRoute),
    movementPending: movementPending ?? this.movementPending,
    movementError: _replaceNullable(
      this.movementError,
      movementError,
      clearMovementError,
    ),
    lastMovementExecution: lastMovementExecution ?? this.lastMovementExecution,
    actionDeck: _replaceNullable(this.actionDeck, actionDeck, clearActionDeck),
    unitLogistics: _replaceNullable(
      this.unitLogistics,
      unitLogistics,
      clearUnitLogistics,
    ),
    combat: _replaceNullable(this.combat, combat, clearCombat),
    city: _replaceNullable(this.city, city, clearCity),
    worker: _replaceNullable(this.worker, worker, clearWorker),
    production: _replaceNullable(this.production, production, clearProduction),
    artifact: _replaceNullable(this.artifact, artifact, clearArtifact),
    referenceVisible: referenceVisible ?? this.referenceVisible,
  );
}

T? _replaceNullable<T>(T? current, T? replacement, bool clear) =>
    clear ? null : replacement ?? current;
