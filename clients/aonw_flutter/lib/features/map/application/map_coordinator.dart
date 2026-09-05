import 'dart:async';

import '../../artifacts/application/artifact_state.dart';
import '../../artifacts/application/artifact_workflow.dart';
import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/application/city_state.dart';
import '../../cities/application/city_workflow.dart';
import '../../cities/read_model/city_view.dart';
import '../../combat/application/combat_workflow.dart';
import '../../combat/read_model/combat_view.dart';
import '../../diplomacy/application/diplomacy_workflow.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../local_game/application/local_ai_turn_state.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../local_game/application/local_handoff_state.dart';
import '../../logistics/application/unit_logistics_state.dart';
import '../../logistics/application/unit_logistics_workflow.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../production/application/production_state.dart';
import '../../production/application/production_workflow.dart';
import '../../production/read_model/production_view.dart';
import '../../replay/application/replay_capture.dart';
import '../../research/application/research_state.dart';
import '../../research/application/research_workflow.dart';
import '../../research/read_model/research_view.dart';
import '../../save_game/application/local_save_state.dart';
import '../../save_game/application/local_save_store.dart';
import '../../save_game/application/local_save_summary.dart';
import '../../save_game/application/local_save_transfer.dart';
import '../../save_game/application/local_save_workflow.dart';
import '../../turns/application/turn_workflow.dart';
import '../../unit_actions/application/action_deck_state.dart';
import '../../unit_actions/application/unit_action_command_runner.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../../workers/application/worker_state.dart';
import '../../workers/application/worker_workflow.dart';
import '../../workers/read_model/worker_view.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/map_view_mode.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'game_session_capabilities.dart';
import 'game_session_state.dart';
import 'map_interaction_state.dart';
import 'map_session_port.dart';
import 'movement_command_runner.dart';
import 'network_game_session_port.dart';
import 'unit_action_workflow.dart';

part 'map_coordinator_actions.dart';
part 'map_coordinator_local_save.dart';
part 'map_coordinator_local_turns.dart';
part 'map_coordinator_network.dart';
part 'map_coordinator_selection.dart';

typedef MapDiagnosticReporter =
    void Function(String code, Object error, StackTrace stackTrace);

UnitActionWorkflow _unitActionWorkflow(
  GameSessionCapabilities capabilities,
  MapDiagnosticReporter? diagnosticReporter,
) => UnitActionWorkflow(
  runner: UnitActionCommandRunner(
    session: capabilities.unitActions,
    diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
  ),
);

final class MapCoordinator {
  Future<void> Function()? waitForCommandEffects;
  MapCoordinator({
    required GameSessionCapabilities capabilities,
    LocalSaveStore? saveStore,
    LocalSaveTransferPort? saveTransfer,
    ReplayCapture? replayCapture,
    this.assets = MapAssetPaths.starter,
    MapDiagnosticReporter? diagnosticReporter,
  }) : _session = capabilities.map,
       _movement = MovementCommandRunner(
         session: capabilities.movement,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _combat = CombatWorkflow(
         session: capabilities.combat,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _cities = CityWorkflow(
         session: capabilities.cities,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _logistics = UnitLogisticsWorkflow(
         session: capabilities.logistics,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _workers = WorkerWorkflow(
         session: capabilities.workers,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _production = ProductionWorkflow(
         session: capabilities.production,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _artifacts = ArtifactWorkflow(
         session: capabilities.artifacts,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _research = ResearchWorkflow(
         session: capabilities.research,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _diplomacy = DiplomacyWorkflow(
         session: capabilities.diplomacy,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _unitActions = _unitActionWorkflow(capabilities, diagnosticReporter),
       _turns = TurnWorkflow(
         session: capabilities.turns,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _capabilities = capabilities,
       _saveWorkflow = LocalSaveWorkflow(
         session: capabilities.save,
         store: saveStore,
         transfer: saveTransfer,
         diagnosticReporter: diagnosticReporter ?? _ignoreDiagnostic,
       ),
       _replayCapture = replayCapture,
       _diagnosticReporter = diagnosticReporter ?? _ignoreDiagnostic;

  final MapSessionPort _session;
  LocalGameCatalogEntryView? _localGameEntry;
  LocalSaveSlotView? _localSaveSlot;
  LocalMatchControlPlanView? _localControlPlan;
  final MovementCommandRunner _movement;
  final CombatWorkflow _combat;
  final CityWorkflow _cities;
  final UnitLogisticsWorkflow _logistics;
  final WorkerWorkflow _workers;
  final ProductionWorkflow _production;
  final ArtifactWorkflow _artifacts;
  final ResearchWorkflow _research;
  final DiplomacyWorkflow _diplomacy;
  final UnitActionWorkflow _unitActions;
  final TurnWorkflow _turns;
  final GameSessionCapabilities _capabilities;
  final LocalSaveWorkflow _saveWorkflow;
  final ReplayCapture? _replayCapture;
  final MapDiagnosticReporter _diagnosticReporter;
  final MapAssetPaths assets;
  final StreamController<GameSessionState> _changes =
      StreamController<GameSessionState>.broadcast(sync: true);
  final StreamController<MapHexCoordinate?> _cursorChanges =
      StreamController<MapHexCoordinate?>.broadcast(sync: true);
  GameSessionState _state = const GameSessionLoading();
  MapHexCoordinate? _hovered;
  var _disposed = false;
  var _loadGeneration = 0;
  var _interactionGeneration = 0;

  GameSessionState get state => _state;

  Stream<GameSessionState> get changes => _changes.stream;

  MapHexCoordinate? get hovered => _hovered;

  Stream<MapHexCoordinate?> get cursorChanges => _cursorChanges.stream;

  Future<void> load() async {
    await _openSession(
      () => _session.load(assets),
      localGameEntry: null,
      controlPlan: null,
    );
  }

  Future<bool> startLocalMatch(
    LocalGameCatalogEntryView entry,
    LocalMatchSetupView setup,
  ) {
    _validateCatalogSetup(entry, setup);
    return _openSession(
      () {
        final localGame = _capabilities.localGame;
        if (localGame == null) {
          throw const LocalGameSessionException(
            code: 'local_game_unavailable',
            message: 'The local game session is unavailable.',
          );
        }
        return localGame.startLocalMatch(setup);
      },
      localGameEntry: entry,
      controlPlan: setup.controlPlan,
    );
  }

  Future<bool> _openSession(
    Future<MapScene> Function() open, {
    required LocalGameCatalogEntryView? localGameEntry,
    required LocalMatchControlPlanView? controlPlan,
  }) async {
    if (_disposed) return false;
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    _setCursor(null);
    _setState(const GameSessionLoading());
    try {
      final scene = await open();
      if (!_isCurrent(generation)) return false;
      _localGameEntry = localGameEntry;
      _localSaveSlot = null;
      _localControlPlan = controlPlan;
      _setState(GameSessionReady.initial(scene));
      return true;
    } on MapLoadException catch (error, stackTrace) {
      if (!_isCurrent(generation)) return false;
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      _setState(GameSessionFailure(code: _loadFailureCode(error.code)));
      return false;
    } on LocalGameSessionException catch (error, stackTrace) {
      if (!_isCurrent(generation)) return false;
      final cause = error.diagnosticCause;
      if (cause != null) {
        _diagnosticReporter(
          error.code,
          cause,
          error.diagnosticStackTrace ?? stackTrace,
        );
      }
      _setState(
        const GameSessionFailure(code: MapLoadFailureViewCode.mapUnavailable),
      );
      return false;
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return false;
      _diagnosticReporter('unexpected_map_failure', error, stackTrace);
      _setState(
        const GameSessionFailure(code: MapLoadFailureViewCode.mapUnavailable),
      );
      return false;
    }
  }

  void hover(MapHexCoordinate? coordinate) {
    final current = _state;
    if (current is! GameSessionReady || current.localHandoff.blocksGameplay) {
      return;
    }
    final next = coordinate != null && current.scene.map.contains(coordinate)
        ? coordinate
        : null;
    _setCursor(next);
  }

  void select(MapHexCoordinate? coordinate) {
    unawaited(_select(coordinate));
  }

  void selectUnit(String unitId) {
    unawaited(_selectUnitById(unitId));
  }

  void selectCity(String cityId) {
    _selectCityById(cityId);
  }

  void confirmMove() {
    unawaited(_confirmMove());
  }

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
    if (completion.failure != null) {
      _setState(_movementFailureState(ready, completion));
    } else {
      _setState(
        _moveResultState(ready, completion.result!, unitId, route.destination),
      );
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration += 1;
    _interactionGeneration += 1;
    unawaited(_session.close());
    unawaited(_changes.close());
    unawaited(_cursorChanges.close());
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _loadGeneration;

  bool _gameplayActive() {
    final current = _state;
    return current is GameSessionReady &&
        !(_capabilities.networkGame?.connection.blocksGameplay ?? false) &&
        !current.recipient.turnView.outcome.isTerminal &&
        !current.localAiTurn.blocksGameplay &&
        !current.localHandoff.blocksGameplay &&
        !current.localSave.inFlight;
  }

  GameSessionReady? _currentInteraction(int generation) {
    if (_disposed || generation != _interactionGeneration) return null;
    final current = _state;
    return current is GameSessionReady ? current : null;
  }

  void _setState(GameSessionState value) {
    if (_disposed) return;
    final previous = _state;
    _state = value;
    _changes.add(value);
    if (_shouldLoadResearch(previous, value)) {
      scheduleMicrotask(() {
        if (_disposed) return;
        _research.load(
          readState: () => _state,
          publish: _setState,
          isDisposed: () => _disposed,
        );
      });
    }
  }

  void _setCursor(MapHexCoordinate? value) {
    if (_disposed || value == _hovered) return;
    _hovered = value;
    _cursorChanges.add(value);
  }
}

bool _shouldLoadResearch(GameSessionState previous, GameSessionState next) {
  if (next is! GameSessionReady ||
      !next.research.loading ||
      next.localAiTurn.inFlight) {
    return false;
  }
  final before = previous is GameSessionReady ? previous.research : null;
  return (previous is GameSessionReady && previous.localAiTurn.inFlight) ||
      before == null ||
      !before.loading ||
      before.requestedRevision != next.research.requestedRevision;
}

void _ignoreDiagnostic(String code, Object error, StackTrace stackTrace) {}

GameSessionReady _setMapViewModeState(
  GameSessionReady current,
  MapViewMode mode,
) => current.withInteraction(current.interaction.copyWith(viewMode: mode));

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
  var movedCoordinate = routeDestination;
  for (final unit in player.units) {
    if (unit.id == unitId) movedCoordinate = unit.coordinate;
  }
  return current
      .withRecipient(player)
      .withInteraction(
        current.interaction.copyWith(
          selected: movedCoordinate,
          clearSelectedUnit: true,
          clearReachable: true,
          clearRoute: true,
          clearActionDeck: true,
          clearUnitLogistics: true,
          clearWorker: true,
          clearProduction: true,
          clearArtifact: true,
          clearCombat: true,
          movementPending: false,
          clearMovementError: true,
          lastMovementExecution: result.execution,
        ),
      );
}

GameSessionReady _movementFailureState<T>(
  GameSessionReady current,
  MovementCommandCompletion<T> completion,
) {
  final player = completion.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      movementPending: false,
      movementError: completion.failure!,
    ),
  );
}

bool _interactionBusy(MapInteractionState interaction) =>
    interaction.movementPending ||
    (interaction.combat?.commandPending ?? false) ||
    (interaction.combat?.loading ?? false) ||
    (interaction.city?.commandPending ?? false) ||
    (interaction.city?.loading ?? false) ||
    (interaction.actionDeck?.commandPending ?? false) ||
    (interaction.unitLogistics?.commandPending ?? false) ||
    (interaction.worker?.commandPending ?? false) ||
    (interaction.worker?.loading ?? false) ||
    (interaction.production?.commandPending ?? false) ||
    (interaction.production?.loading ?? false) ||
    (interaction.artifact?.commandPending ?? false);

void _validateCatalogSetup(
  LocalGameCatalogEntryView entry,
  LocalMatchSetupView setup,
) {
  if (entry.assets.document != setup.assets.document ||
      entry.assets.bundleManifest != setup.assets.bundleManifest ||
      entry.assets.scenarioDocument != setup.assets.scenarioDocument ||
      entry.assets.actorPlayerId != setup.assets.actorPlayerId) {
    throw ArgumentError.value(
      setup.assets,
      'setup.assets',
      'must match the selected catalog entry',
    );
  }
  final participantIds = [
    for (final participant in setup.participants) participant.id,
  ];
  if (participantIds.length != entry.participantIds.length ||
      !entry.participantIds.every(participantIds.contains)) {
    throw ArgumentError.value(
      participantIds,
      'setup.participants',
      'participants must match the selected catalog entry',
    );
  }
}

MapLoadFailureViewCode _loadFailureCode(String code) => switch (code) {
  'engine_adapter_unavailable' ||
  'engine_unavailable' => MapLoadFailureViewCode.adapterUnavailable,
  'engine_capability_mismatch' ||
  'invalid_map_protocol' => MapLoadFailureViewCode.incompatibleClient,
  'map_load_superseded' => MapLoadFailureViewCode.loadSuperseded,
  _ => MapLoadFailureViewCode.mapUnavailable,
};
