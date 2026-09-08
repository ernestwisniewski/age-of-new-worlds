import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../artifacts/read_model/artifact_view.dart';
import '../../audio/application/game_audio_port.dart';
import '../../cities/application/city_state.dart';
import '../../cities/read_model/city_view.dart';
import '../../combat/read_model/combat_view.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../production/read_model/production_view.dart';
import '../../replay/application/replay_capture.dart';
import '../../research/read_model/research_view.dart';
import '../../save_game/application/local_save_state.dart';
import '../../save_game/application/local_save_store.dart';
import '../../save_game/application/local_save_summary.dart';
import '../../save_game/application/local_save_transfer.dart';
import '../../turns/application/automatic_turn_policy.dart';
import '../../turns/read_model/pending_turn_actions_view.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../../workers/read_model/worker_view.dart';
import '../application/game_session_capabilities.dart';
import '../application/game_session_state.dart';
import '../application/map_coordinator.dart';
import '../application/map_session_port.dart';
import '../application/network_game_session_port.dart';
import '../read_model/map_view.dart';
import '../read_model/map_view_mode.dart';
import '../read_model/pending_action_view.dart';
import 'map_interaction_audio.dart';

final class MapPresentationController extends ChangeNotifier {
  MapPresentationController({
    required GameSessionCapabilities capabilities,
    LocalSaveStore? saveStore,
    LocalSaveTransferPort? saveTransfer,
    ReplayCapture? replayCapture,
    MapAssetPaths assets = MapAssetPaths.starter,
    MapDiagnosticReporter diagnosticReporter = _reportMapDiagnostic,
  }) : this.fromCoordinator(
         MapCoordinator(
           capabilities: capabilities,
           saveStore: saveStore,
           saveTransfer: saveTransfer,
           replayCapture: replayCapture,
           assets: assets,
           diagnosticReporter: diagnosticReporter,
         ),
         networkGame: capabilities.networkGame,
       );

  MapPresentationController.fromCoordinator(
    this._coordinator, {
    NetworkGameSessionPort? networkGame,
  }) : _networkGame = networkGame {
    _interactionAudio = MapInteractionAudio(
      readState: () => state,
      play: (cue) => _interactionSoundSink?.call(cue),
    );
    _subscription = _coordinator.changes.listen((state) {
      _interactionAudio.observe(state);
      notifyListeners();
    });
    _networkSubscription = networkGame?.connectionChanges.listen((connection) {
      if (connection.blocksGameplay) _interactionAudio.cancelPending();
      notifyListeners();
    });
    _cursor = ValueNotifier<MapHexCoordinate?>(_coordinator.hovered);
    _cursorSubscription = _coordinator.cursorChanges.listen((value) {
      _cursor.value = value;
    });
  }

  final MapCoordinator _coordinator;
  final NetworkGameSessionPort? _networkGame;
  late final StreamSubscription<GameSessionState> _subscription;
  StreamSubscription<NetworkGameConnectionView>? _networkSubscription;
  late final ValueNotifier<MapHexCoordinate?> _cursor;
  late final StreamSubscription<MapHexCoordinate?> _cursorSubscription;
  var _disposed = false;
  late final MapInteractionAudio _interactionAudio;
  void Function(GameSoundCue)? _interactionSoundSink;

  void bindInteractionSounds(void Function(GameSoundCue)? sink) {
    _interactionAudio.cancelPending();
    _interactionSoundSink = _disposed ? null : sink;
  }

  void silencePendingInteractionSounds() => _interactionAudio.cancelPending();

  GameSessionState get state => _coordinator.state;

  void bindCommandEffects(Future<void> Function()? wait) {
    _coordinator.waitForCommandEffects = wait;
  }

  NetworkGameConnectionView get networkConnection =>
      _networkGame?.connection ?? NetworkGameConnectionView.inactive;

  ValueListenable<MapHexCoordinate?> get cursor => _cursor;

  Future<void> load() => _coordinator.load();

  Future<bool> startLocalMatch(
    LocalGameCatalogEntryView entry,
    LocalMatchSetupView setup,
  ) => _coordinator.startLocalMatch(entry, setup);

  Future<bool> startNetworkMatch(NetworkMatchSetupView setup) =>
      _coordinator.startNetworkMatch(setup);

  Future<bool> reconnectNetworkMatch() => _coordinator.reconnectNetworkMatch();

  Future<bool> hasLocalSave() => _coordinator.hasLocalSave();

  Future<List<LocalSaveSummaryView>> listLocalSaves() =>
      _coordinator.listLocalSaves();

  bool get canTransferLocalSaves => _coordinator.canTransferLocalSaves;

  Future<LocalSaveTransferResultView> importLocalSave() =>
      _coordinator.importLocalSave();

  Future<LocalSaveTransferResultView> exportLocalSave(LocalSaveSlotView slot) =>
      _coordinator.exportLocalSave(slot);

  Future<LocalResumeResultView> resumeLocalGame(LocalSaveSlotView slot) =>
      _coordinator.resumeLocalGame(slot);

  Future<LocalResumeResultView> resumeLatestLocalGame() =>
      _coordinator.resumeLatestLocalGame();

  void saveLocalGame() => _coordinator.saveLocalGame();

  void hover(MapHexCoordinate? coordinate) => _coordinator.hover(coordinate);

  void select(MapHexCoordinate? coordinate) => _interactionAudio.perform(
    MapInteractionAudioAction.selectHex,
    () => _coordinator.select(coordinate),
  );

  void selectUnit(String unitId) => _coordinator.selectUnit(unitId);

  void selectCity(String cityId) => _interactionAudio.perform(
    MapInteractionAudioAction.selectCity,
    () => _coordinator.selectCity(cityId),
  );

  void confirmMove() => _coordinator.confirmMove();

  void cancelInteraction() => _coordinator.cancelInteraction();

  bool get canToggleMoveTargeting => _coordinator.canToggleMoveTargeting;

  void inspectHex(MapHexCoordinate coordinate) =>
      _coordinator.inspectHex(coordinate);

  void closeHexInspection() => _coordinator.closeHexInspection();

  void toggleMoveTargeting() => _coordinator.toggleMoveTargeting();

  void moveMapCursor(MapHexCoordinate coordinate) =>
      _coordinator.moveMapCursor(coordinate);

  void executeUnitAction(UnitActionKindView action) =>
      _coordinator.executeUnitAction(action);

  void executeUnitLogistics(UnitLogisticsActionView action) =>
      _coordinator.executeUnitLogistics(action);

  void setWorkerActionsOpen(bool open) => _interactionAudio.perform(
    MapInteractionAudioAction.workerActions,
    () => _coordinator.setWorkerActionsOpen(open),
  );

  void previewWorkerImprovement(
    String unitId,
    FieldImprovementKind improvement,
  ) => _coordinator.previewWorkerImprovement(unitId, improvement);

  void executeWorkerAction(WorkerActionView action) =>
      _coordinator.executeWorkerAction(action);

  void executeProductionAction(ProductionActionView action) =>
      _coordinator.executeProductionAction(action);

  void executeArtifactAction(ArtifactActionView action) =>
      _coordinator.executeArtifactAction(action);

  void selectTechnology(TechnologyIdView technology) =>
      _coordinator.selectTechnology(technology);

  void refreshResearch() => _coordinator.refreshResearch();

  void executeDiplomacyAction(DiplomacyActionView action) =>
      _coordinator.executeDiplomacyAction(action);

  void confirmCombat() => _coordinator.confirmCombat();

  void setCityConquestAction(CityConquestActionView action) =>
      _coordinator.setCityConquestAction(action);

  void inspectSelectedCity(String cityId) => _interactionAudio.perform(
    MapInteractionAudioAction.selectCity,
    () => _coordinator.inspectSelectedCity(cityId),
  );

  void openCityFounding() => _interactionAudio.perform(
    MapInteractionAudioAction.foundCity,
    _coordinator.openCityFounding,
  );

  void toggleCityFoundingHex(MapHexCoordinate coordinate) =>
      _coordinator.toggleCityFoundingHex(coordinate);

  void cancelCityFounding() => _coordinator.cancelCityFounding();

  void confirmCityFounding() => _coordinator.confirmCityFounding();

  void startCityManagement(CityManagementMode mode) =>
      _interactionAudio.perform(
        MapInteractionAudioAction.manageCity,
        () => _coordinator.startCityManagement(mode),
      );

  void cancelCityManagement() => _coordinator.cancelCityManagement();

  void executeCityAction(CityActionView action) =>
      _coordinator.executeCityAction(action);

  Future<void> navigateTurnActions({
    required int step,
    bool endWhenEmpty = false,
    AutomaticTurnPolicyBuilder? automatic,
    required bool Function() inputAvailable,
    void Function(MapHexCoordinate)? onFocus,
  }) => _coordinator.navigateTurnActions(
    step: step,
    endWhenEmpty: endWhenEmpty,
    automatic: automatic,
    inputAvailable: inputAvailable,
    onFocused: (action) {
      switch (action) {
        case PendingUnitTurnActionView(:final coordinate):
          onFocus?.call(coordinate);
        case PendingCityProductionTurnActionView(:final coordinate):
          _interactionSoundSink?.call(GameSoundCue.city);
          onFocus?.call(coordinate);
        case PendingResearchTurnActionView():
          break;
      }
    },
  );

  void closeTurnResearch() => _coordinator.closeTurnResearch();

  void endTurn() => _coordinator.endTurn();

  void confirmLocalHandoff() => _coordinator.confirmLocalHandoff();

  void retryLocalHandoff() => _coordinator.retryLocalHandoff();

  void toggleMapViewMode() => _coordinator.toggleMapViewMode();

  void setMapViewMode(MapViewMode mode) => _coordinator.setMapViewMode(mode);

  void completeTurnPresentation() => _coordinator.completeTurnPresentation();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bindInteractionSounds(null);
    unawaited(_subscription.cancel());
    unawaited(_networkSubscription?.cancel());
    unawaited(_cursorSubscription.cancel());
    _cursor.dispose();
    _coordinator.dispose();
    super.dispose();
  }
}

void _reportMapDiagnostic(String code, Object error, StackTrace stackTrace) {
  debugPrintStack(
    label: 'Map diagnostic [$code]: $error',
    stackTrace: stackTrace,
  );
}
