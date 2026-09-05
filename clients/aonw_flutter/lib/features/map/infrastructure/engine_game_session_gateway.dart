import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter/services.dart';

import '../../artifacts/application/artifact_session_port.dart';
import '../../artifacts/infrastructure/engine_artifact_gateway.dart';
import '../../artifacts/read_model/artifact_view.dart';
import '../../cities/application/city_session_port.dart';
import '../../cities/infrastructure/engine_city_gateway.dart';
import '../../cities/read_model/city_view.dart';
import '../../combat/application/combat_session_port.dart';
import '../../combat/infrastructure/engine_combat_gateway.dart';
import '../../combat/read_model/combat_view.dart';
import '../../diplomacy/application/diplomacy_session_port.dart';
import '../../diplomacy/infrastructure/engine_diplomacy_gateway.dart';
import '../../diplomacy/read_model/diplomacy_view.dart';
import '../../local_game/application/local_game_session_port.dart';
import '../../local_game/infrastructure/local_match_mapper.dart';
import '../../logistics/application/unit_logistics_session_port.dart';
import '../../logistics/infrastructure/engine_unit_logistics_gateway.dart';
import '../../logistics/read_model/unit_logistics_view.dart';
import '../../production/application/production_session_port.dart';
import '../../production/infrastructure/engine_production_gateway.dart';
import '../../production/read_model/production_view.dart';
import '../../replay/application/replay_session_port.dart';
import '../../replay/read_model/replay_frame_view.dart';
import '../../research/application/research_session_port.dart';
import '../../research/infrastructure/engine_research_gateway.dart';
import '../../research/read_model/research_view.dart';
import '../../save_game/application/game_save_session_port.dart';
import '../../turns/application/turn_session_port.dart';
import '../../turns/infrastructure/engine_turn_gateway.dart';
import '../../turns/read_model/turn_command_view.dart';
import '../../unit_actions/application/unit_action_session_port.dart';
import '../../unit_actions/infrastructure/engine_unit_action_gateway.dart';
import '../../unit_actions/infrastructure/unit_action_view_mapper.dart';
import '../../unit_actions/read_model/unit_action_view.dart';
import '../../workers/application/worker_session_port.dart';
import '../../workers/infrastructure/engine_worker_gateway.dart';
import '../../workers/read_model/worker_view.dart';
import '../application/game_session_capabilities.dart';
import '../application/map_session_port.dart';
import '../application/movement_session_port.dart';
import '../read_model/map_scene.dart';
import '../read_model/map_view.dart';
import '../read_model/movement_view.dart';
import '../read_model/player_map_view.dart';
import 'engine_game_session_context.dart';
import 'engine_game_session_loader.dart';
import 'engine_game_session_operations.dart';
import 'engine_movement_gateway.dart';
import 'map_feedback_mapper.dart';
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';

part 'engine_game_artifact_session.dart';
part 'engine_game_city_session.dart';
part 'engine_game_production_session.dart';
part 'engine_game_replay_session.dart';
part 'engine_game_save_session.dart';
part 'engine_game_remote_session.dart';
part 'engine_game_session_gateway_support.dart';
part 'engine_game_worker_session.dart';

final class EngineGameSessionGateway
    implements
        MapSessionPort,
        MovementSessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        ResearchSessionPort,
        DiplomacySessionPort,
        TurnSessionPort,
        UnitActionSessionPort,
        LocalGameSessionPort {
  EngineGameSessionGateway({
    required AssetBundle assets,
    EngineSessionFactory sessionFactory = createAonwEngineSession,
    MapViewMapper mapper = const MapViewMapper(),
    PlayerMapViewMapper playerMapper = const PlayerMapViewMapper(),
    EngineMovementGateway movementGateway = const EngineMovementGateway(),
    EngineCombatGateway combatGateway = const EngineCombatGateway(),
    EngineCityGateway cityGateway = const EngineCityGateway(),
    EngineWorkerGateway workerGateway = const EngineWorkerGateway(),
    EngineProductionGateway productionGateway = const EngineProductionGateway(),
    EngineArtifactGateway artifactGateway = const EngineArtifactGateway(),
    EngineResearchGateway researchGateway = const EngineResearchGateway(),
    EngineDiplomacyGateway diplomacyGateway = const EngineDiplomacyGateway(),
    EngineTurnGateway turnGateway = const EngineTurnGateway(),
    EngineUnitLogisticsGateway logisticsGateway =
        const EngineUnitLogisticsGateway(),
    UnitActionViewMapper unitActionMapper = const UnitActionViewMapper(),
    LocalMatchMapper localMatchMapper = const LocalMatchMapper(),
  }) : _loader = EngineGameSessionLoader(
         assets: assets,
         sessionFactory: sessionFactory,
         mapMapper: mapper,
         playerMapper: playerMapper,
       ),
       _playerMapper = playerMapper,
       _movementGateway = movementGateway,
       _combatGateway = combatGateway,
       _cityGateway = cityGateway,
       _workerGateway = workerGateway,
       _productionGateway = productionGateway,
       _artifactGateway = artifactGateway,
       _researchGateway = researchGateway,
       _diplomacyGateway = diplomacyGateway,
       _turnGateway = turnGateway,
       _logisticsGateway = logisticsGateway,
       _localMatchMapper = localMatchMapper,
       _unitActions = EngineUnitActionGateway(
         playerMapper: playerMapper,
         mapper: unitActionMapper,
       ) {
    citySession = _EngineGameCitySession(this);
    workerSession = _EngineGameWorkerSession(this);
    productionSession = _EngineGameProductionSession(this);
    artifactSession = _EngineGameArtifactSession(this);
    replaySession = _EngineGameReplaySession(this);
    saveSession = _EngineGameSaveSession(this);
  }

  final EngineGameSessionLoader _loader;
  final PlayerMapViewMapper _playerMapper;
  final EngineMovementGateway _movementGateway;
  final EngineCombatGateway _combatGateway;
  final EngineCityGateway _cityGateway;
  final EngineWorkerGateway _workerGateway;
  final EngineProductionGateway _productionGateway;
  final EngineArtifactGateway _artifactGateway;
  final EngineResearchGateway _researchGateway;
  final EngineDiplomacyGateway _diplomacyGateway;
  final EngineTurnGateway _turnGateway;
  final EngineUnitLogisticsGateway _logisticsGateway;
  final LocalMatchMapper _localMatchMapper;
  final EngineUnitActionGateway _unitActions;
  late final CitySessionPort citySession;
  late final WorkerSessionPort workerSession;
  late final ProductionSessionPort productionSession;
  late final ArtifactSessionPort artifactSession;
  late final ReplaySessionPort replaySession;
  late final GameSaveSessionPort saveSession;

  GameSessionCapabilities get capabilities => GameSessionCapabilities(
    map: this,
    movement: this,
    combat: this,
    cities: citySession,
    logistics: this,
    workers: workerSession,
    production: productionSession,
    artifacts: artifactSession,
    research: this,
    diplomacy: this,
    unitActions: this,
    turns: this,
    localGame: this,
    save: saveSession,
  );
  AonwEngineSession? _session;
  MapScene? _scene;
  MapView? _map;
  PlayerMapView? _player;
  RecipientProjectionCache? _cache;
  String? _actorPlayerId;
  int? _replayEntryCount;
  Future<void> _requestTail = Future<void>.value();
  var _loadGeneration = 0;
  var _sessionGeneration = 0;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final generation = ++_loadGeneration;
    final prepared = await _loader.prepare(assets);
    var retained = false;
    try {
      await _activate(prepared, assets.actorPlayerId, generation);
      retained = true;
      return prepared.scene;
    } finally {
      if (!retained) await prepared.session.close();
    }
  }

  @override
  Future<MapScene> startLocalMatch(LocalMatchSetupView setup) async {
    final generation = ++_loadGeneration;
    final prepared = await _loader.prepareMatch(
      setup.assets,
      matchIdentity: _localMatchMapper.toWire(setup),
      fogEnabled: setup.fogEnabled,
    );
    var retained = false;
    try {
      await _activate(prepared, setup.assets.actorPlayerId, generation);
      retained = true;
      return prepared.scene;
    } finally {
      if (!retained) await prepared.session.close();
    }
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => _serialize(
    () => _movementGateway.reachable(
      readContext: _context,
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: _send,
    ),
  );

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _serialize(
    () => _movementGateway.routePlan(
      readContext: _context,
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
      send: _send,
    ),
  );

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => _serialize(
    () => _movementGateway.moveUnit(
      readContext: _context,
      expectedRevision: expectedRevision,
      unitId: unitId,
      target: target,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) => _serialize(
    () => _researchGateway.options(
      readContext: _context,
      expectedRevision: expectedRevision,
      send: _send,
    ),
  );

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) => _serialize(
    () => _researchGateway.select(
      readContext: _context,
      expectedRevision: expectedRevision,
      technology: technology,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  }) => _serialize(
    () => _diplomacyGateway.execute(
      readContext: _context,
      expectedRevision: expectedRevision,
      action: action,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) => _serialize(
    () => _combatGateway.preview(
      readContext: _context,
      expectedRevision: expectedRevision,
      attackerUnitId: attackerUnitId,
      defender: defender,
      send: _send,
    ),
  );

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) => _serialize(
    () => _combatGateway.attack(
      readContext: _context,
      expectedRevision: expectedRevision,
      attack: attack,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => _serialize(
    () => _logisticsGateway.options(
      readContext: _context,
      expectedRevision: expectedRevision,
      unitId: unitId,
      send: _send,
    ),
  );

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) => _serialize(
    () => _logisticsGateway.execute(
      readContext: _context,
      expectedRevision: expectedRevision,
      action: action,
      send: _send,
      applyPatch: _applyCommandPatch,
    ),
  );

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => _serialize(() async {
    try {
      return await _unitActions.execute(
        context: _context(),
        expectedRevision: expectedRevision,
        unitId: unitId,
        action: action,
        send: _send,
        ensureCurrent: _ensureCurrentSession,
        retainPlayer: _retainPlayer,
      );
    } on EngineSessionTransportException catch (error) {
      throw UnitActionSessionException(
        code: error.code,
        message: 'The unit action request could not be completed.',
        diagnosticCause: error.diagnosticCause,
        diagnosticStackTrace: error.diagnosticStackTrace,
        resyncedPlayer: error.resyncedPlayer,
      );
    }
  });

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      _serialize(
        () => _turnGateway.execute(
          readContext: _context,
          expectedRevision: expectedRevision,
          send: _send,
          applyPatch: _applyCommandPatch,
        ),
      );

  @override
  Future<LocalAiTurnExecutionView> advanceAiTurn(
    LocalAiTurnRequestView request,
  ) => _advanceLocalAiTurn(request);

  @override
  Future<PlayerMapView> handoffLocalActor(String playerId) =>
      _serialize(() => _restoreHuman(_context(), playerId));

  @override
  Future<void> close() async {
    _loadGeneration += 1;
    _sessionGeneration += 1;
    final session = _session;
    _session = null;
    _scene = null;
    _map = null;
    _player = null;
    _cache = null;
    _actorPlayerId = null;
    _replayEntryCount = null;
    await _requestTail;
    if (session != null) await session.close();
  }
}
