import 'package:aonw_flutter/features/artifacts/application/artifact_session_port.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/application/city_session_port.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/application/combat_session_port.dart';
import 'package:aonw_flutter/features/combat/read_model/combat_view.dart';
import 'package:aonw_flutter/features/diplomacy/application/diplomacy_session_port.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/logistics/application/unit_logistics_session_port.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/application/city_planning_session_port.dart';
import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/hex_inspection_session_port.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_reference_bundle.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_session_port.dart';
import 'package:aonw_flutter/features/production/read_model/production_details_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_session_port.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_session_port.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';

import 'city_planning_test_fixture.dart';
import 'hex_inspection_test_fixture.dart';
import 'pending_turn_actions_test_fixture.dart';

export 'city_planning_test_fixture.dart';
export 'pending_turn_actions_test_fixture.dart';

part 'city_test_fixture.dart';
part 'map_scene_test_fixture.dart';
part 'production_overview_game_fixture.dart';
part 'pending_turn_actions_game_fixture.dart';
part 'map_research_test_fixture.dart';
part 'game_session_capabilities_test_fixture.dart';
part 'local_game_test_fixture.dart';
part 'map_combat_test_fixture.dart';
part 'map_unit_test_fixture.dart';
part 'map_movement_test_fixture.dart';

typedef ProductionOverviewFixture = ({
  ProductionOptionsView options,
  StrategicResourceProjectionView resources,
});

final class FakeGameSession
    with
        FakeLocalGameSessionFixture,
        FakePendingTurnActionsSession,
        FakeProductionSessionFixture,
        FakeResearchSessionFixture
    implements
        MapSessionPort,
        MovementSessionPort,
        CitySessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        WorkerSessionPort,
        ProductionSessionPort,
        ArtifactSessionPort,
        ResearchSessionPort,
        DiplomacySessionPort,
        TurnSessionPort,
        UnitActionSessionPort,
        LocalGameSessionPort {
  FakeGameSession.success(
    this.scene, {
    this.reachableResult,
    this.routeResult,
    this.moveResult,
    this.moveFailure,
    this.unitActionResult,
    this.unitActionFailure,
    this.turnResult,
    this.turnFailure,
    this.logisticsOptions,
    this.logisticsResult,
    this.logisticsFailure,
    this.workerOptionsResult,
    this.workerResult,
    this.workerFailure,
    this.productionOverviewResult,
    this.productionOverviewResults = const [],
    this.productionResult,
    this.productionFailure,
    this.artifactResult,
    this.artifactFailure,
    this.researchOptionsResult,
    this.researchResult,
    this.researchFailure,
    this.diplomacyResult,
    this.diplomacyFailure,
    this.combatPreviewResult,
    this.combatResult,
    this.combatFailure,
    this.cityFoundingOptionsResult,
    this.cityInspection,
    this.cityResult,
    this.cityFailure,
    this.aiTurnResults = const [],
    this.aiTurnFailure,
    this.handoffPlayers = const {},
  }) : failure = null {
    pendingTurnActionsFallback = _emptyPendingTurnActions;
  }
  FakeGameSession.failure(this.failure)
    : scene = null,
      reachableResult = null,
      routeResult = null,
      moveResult = null,
      moveFailure = null,
      unitActionResult = null,
      unitActionFailure = null,
      turnResult = null,
      turnFailure = null,
      logisticsOptions = null,
      logisticsResult = null,
      logisticsFailure = null,
      workerOptionsResult = null,
      workerResult = null,
      workerFailure = null,
      productionOverviewResult = null,
      productionOverviewResults = const [],
      productionResult = null,
      productionFailure = null,
      artifactResult = null,
      artifactFailure = null,
      researchOptionsResult = null,
      researchResult = null,
      researchFailure = null,
      diplomacyResult = null,
      diplomacyFailure = null,
      combatPreviewResult = null,
      combatResult = null,
      combatFailure = null,
      cityFoundingOptionsResult = null,
      cityInspection = null,
      cityResult = null,
      cityFailure = null,
      aiTurnResults = const [],
      aiTurnFailure = null,
      handoffPlayers = const {};

  @override
  final MapScene? scene;
  @override
  final MapLoadException? failure;
  ReachableView? reachableResult;
  final RoutePlanView? routeResult;
  final MoveUnitResultView? moveResult;
  final MovementSessionException? moveFailure;
  final UnitActionResultView? unitActionResult;
  final UnitActionSessionException? unitActionFailure;
  final TurnCommandResultView? turnResult;
  final TurnSessionException? turnFailure;
  final UnitLogisticsOptionsView? logisticsOptions;
  final UnitLogisticsCommandResultView? logisticsResult;
  final UnitLogisticsSessionException? logisticsFailure;
  final WorkerOptionsView? workerOptionsResult;
  final WorkerCommandResultView? workerResult;
  final WorkerSessionException? workerFailure;
  @override
  final ({
    ProductionOptionsView options,
    StrategicResourceProjectionView resources,
  })?
  productionOverviewResult;
  @override
  final List<ProductionOverviewFixture> productionOverviewResults;
  @override
  final ProductionCommandResultView? productionResult;
  @override
  final ProductionSessionException? productionFailure;
  final ArtifactCommandResultView? artifactResult;
  final ArtifactSessionException? artifactFailure;
  @override
  final ResearchOptionsView? researchOptionsResult;
  @override
  final ResearchCommandResultView? researchResult;
  @override
  final ResearchSessionException? researchFailure;
  final DiplomacyCommandResultView? diplomacyResult;
  final DiplomacySessionException? diplomacyFailure;
  final CombatPreviewView? combatPreviewResult;
  final CombatCommandResultView? combatResult;
  final CombatSessionException? combatFailure;
  final CityFoundingOptionsView? cityFoundingOptionsResult;
  final CityInspectionView? cityInspection;
  final CityCommandResultView? cityResult;
  final CitySessionException? cityFailure;
  @override
  final List<LocalAiTurnExecutionView> aiTurnResults;
  @override
  final LocalGameSessionException? aiTurnFailure;
  @override
  final Map<String, PlayerMapView> handoffPlayers;
  var unitActionCalls = 0;
  UnitActionKindView? lastUnitAction;
  int? lastUnitActionExpectedRevision;
  String? lastUnitActionUnitId;
  var endTurnCalls = 0;
  int? lastEndTurnExpectedRevision;
  var logisticsOptionCalls = 0;
  var logisticsCommandCalls = 0;
  int? lastLogisticsExpectedRevision;
  UnitLogisticsActionView? lastLogisticsAction;
  var workerOptionCalls = 0;
  var workerCommandCalls = 0;
  int? lastWorkerExpectedRevision;
  WorkerActionView? lastWorkerAction;
  var artifactCommandCalls = 0;
  ArtifactActionView? lastArtifactAction;
  int? lastArtifactExpectedRevision;
  var diplomacyCommandCalls = 0;
  int? lastDiplomacyExpectedRevision;
  DiplomacyActionView? lastDiplomacyAction;
  var combatPreviewCalls = 0;
  var combatAttackCalls = 0;
  MapHexCoordinate? lastCombatDefender;
  CombatAttackView? lastCombatAttack;
  var cityFoundingOptionCalls = 0;
  var cityInspectionCalls = 0;
  var cityCommandCalls = 0;
  CityActionView? lastCityAction;
  @override
  var localStartCalls = 0;
  @override
  LocalMatchSetupView? lastLocalMatchSetup;
  @override
  var aiTurnCalls = 0;
  @override
  final aiTurnRequests = <LocalAiTurnRequestView>[];
  @override
  final handoffRequests = <String>[];
  final selectionRequestOrder = <String>[];

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final error = failure;
    if (error != null) throw error;
    return scene!;
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) async {
    selectionRequestOrder.add('reachable');
    return reachableResult ?? (throw StateError('No reachable fixture.'));
  }

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async => routeResult ?? (throw StateError('No route fixture.'));

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async {
    final error = moveFailure;
    if (error != null) throw error;
    return moveResult ?? (throw StateError('No move fixture.'));
  }

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) async {
    combatPreviewCalls += 1;
    lastCombatDefender = defender;
    final error = combatFailure;
    if (error != null) throw error;
    return combatPreviewResult ??
        (throw StateError('No combat preview fixture.'));
  }

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) async {
    combatAttackCalls += 1;
    lastCombatAttack = attack;
    final error = combatFailure;
    if (error != null) throw error;
    return combatResult ?? (throw StateError('No combat result fixture.'));
  }

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) async {
    cityFoundingOptionCalls += 1;
    final error = cityFailure;
    if (error != null) throw error;
    return cityFoundingOptionsResult ??
        (throw StateError('No city founding fixture.'));
  }

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) async {
    cityInspectionCalls += 1;
    final error = cityFailure;
    if (error != null) throw error;
    return cityInspection ?? (throw StateError('No city inspection fixture.'));
  }

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) async {
    cityCommandCalls += 1;
    lastCityAction = action;
    final error = cityFailure;
    if (error != null) throw error;
    return cityResult ?? (throw StateError('No city command fixture.'));
  }

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) async {
    unitActionCalls += 1;
    lastUnitAction = action;
    lastUnitActionExpectedRevision = expectedRevision;
    lastUnitActionUnitId = unitId;
    final error = unitActionFailure;
    if (error != null) throw error;
    return unitActionResult ?? (throw StateError('No unit action fixture.'));
  }

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) async {
    endTurnCalls += 1;
    lastEndTurnExpectedRevision = expectedRevision;
    final error = turnFailure;
    if (error != null) throw error;
    return turnResult ?? (throw StateError('No turn fixture.'));
  }

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) async {
    selectionRequestOrder.add('logistics');
    logisticsOptionCalls += 1;
    final error = logisticsFailure;
    if (error != null) throw error;
    return logisticsOptions ??
        UnitLogisticsOptionsView(
          stamp: testSessionStamp(revision: expectedRevision),
          unitId: unitId,
          autoExplore: null,
          merchantRouteDestinations: const [],
          merchantTravelDestinations: const [],
          detachments: const [],
        );
  }

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) async {
    logisticsCommandCalls += 1;
    lastLogisticsExpectedRevision = expectedRevision;
    lastLogisticsAction = action;
    final error = logisticsFailure;
    if (error != null) throw error;
    return logisticsResult ??
        (throw StateError('No unit logistics result fixture.'));
  }

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) async {
    workerOptionCalls += 1;
    final error = workerFailure;
    if (error != null) throw error;
    return workerOptionsResult ??
        WorkerOptionsView(
          stamp: testSessionStamp(revision: expectedRevision),
          unitId: unitId,
          coordinate:
              scene?.player.controlledUnitById(unitId)?.coordinate ??
              (col: 0, row: 0),
          improvements: const [],
          canAssign: false,
          canBuildRoad: false,
          automation: null,
        );
  }

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) async {
    workerCommandCalls += 1;
    lastWorkerExpectedRevision = expectedRevision;
    lastWorkerAction = action;
    final error = workerFailure;
    if (error != null) throw error;
    return workerResult ?? (throw StateError('No worker result fixture.'));
  }

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) async {
    artifactCommandCalls += 1;
    lastArtifactExpectedRevision = expectedRevision;
    lastArtifactAction = action;
    final error = artifactFailure;
    if (error != null) throw error;
    return artifactResult ?? (throw StateError('No artifact result fixture.'));
  }

  @override
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  }) async {
    diplomacyCommandCalls += 1;
    lastDiplomacyExpectedRevision = expectedRevision;
    lastDiplomacyAction = action;
    final error = diplomacyFailure;
    if (error != null) throw error;
    return diplomacyResult ??
        (throw StateError('No diplomacy result fixture.'));
  }

  @override
  Future<void> close() async {}
}
