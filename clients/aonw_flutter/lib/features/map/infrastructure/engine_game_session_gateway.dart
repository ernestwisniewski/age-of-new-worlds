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
import 'map_view_mapper.dart';
import 'player_map_view_mapper.dart';
import 'recipient_projection_cache.dart';

part 'engine_game_artifact_session.dart';
part 'engine_game_city_session.dart';
part 'engine_game_production_session.dart';
part 'engine_game_replay_session.dart';
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
        LocalGameSessionPort,
        GameSaveSessionPort {
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
    save: this,
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
  Future<String> exportSaveDocument() => _serialize(() async {
    final context = _context();
    try {
      final response = await context.session.send(
        AonwClientRequest.exportSave(),
      );
      _ensureCurrentSession(context);
      if (!response.isSuccess) {
        final error = response.error!;
        throw GameSaveSessionException(
          code: error.code,
          message: 'The current game could not be exported.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      return response.require<AonwSaveExportedResponse>().document;
    } on GameSaveSessionException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw GameSaveSessionException(
        code: 'save_export_failed',
        message: 'The current game could not be exported.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  });

  @override
  Future<MapScene> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    final generation = ++_loadGeneration;
    try {
      final prepared = await _loader.prepareSave(
        assets,
        saveDocument: document,
      );
      var retained = false;
      try {
        await _activate(prepared, assets.actorPlayerId, generation);
        retained = true;
        return prepared.scene;
      } finally {
        if (!retained) await prepared.session.close();
      }
    } on MapLoadException catch (error, stackTrace) {
      throw GameSaveSessionException(
        code: error.code,
        message: 'The saved game could not be opened.',
        diagnosticCause: error.diagnosticCause ?? error,
        diagnosticStackTrace: error.diagnosticStackTrace ?? stackTrace,
      );
    } on GameSaveSessionException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw GameSaveSessionException(
        code: 'save_open_failed',
        message: 'The saved game could not be opened.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  Future<void> _activate(
    PreparedEngineGameSession prepared,
    String actorPlayerId,
    int generation,
  ) async {
    _ensureCurrentLoad(generation);
    await _requestTail;
    _ensureCurrentLoad(generation);
    final previous = _session;
    if (previous != null) await previous.close();
    _ensureCurrentLoad(generation);
    _sessionGeneration += 1;
    _session = prepared.session;
    _scene = prepared.scene;
    _map = prepared.scene.map;
    _player = prepared.scene.player;
    _cache = prepared.cache;
    _actorPlayerId = actorPlayerId;
    _replayEntryCount = null;
  }

  void _ensureCurrentLoad(int generation) {
    if (generation != _loadGeneration) {
      throw const MapLoadException(
        code: 'map_load_superseded',
        message: 'A newer map load replaced this request.',
      );
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
  ) => _serialize(() async {
    final context = _context();
    if (context.actorPlayerId != request.humanPlayerId) {
      throw const LocalGameSessionException(
        code: 'local_actor_mismatch',
        message: 'The local game actor does not match the requested human.',
      );
    }
    AonwClientResponse response;
    try {
      response = await context.session.send(
        AonwClientRequest.advanceAiTurn(
          actorPlayerId: request.aiPlayerId,
          commandBudget: request.commandBudget,
        ),
      );
      _ensureCurrentSession(context);
    } on Object catch (error, stackTrace) {
      final player = await _tryRestoreHuman(context, request.humanPlayerId);
      throw LocalGameSessionException(
        code: 'ai_turn_request_failed',
        message: 'The AI turn could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
        resyncedPlayer: player,
      );
    }
    final player = await _restoreHuman(context, request.humanPlayerId);
    if (!response.isSuccess) {
      final error = response.error!;
      throw LocalGameSessionException(
        code: error.code,
        message: 'The AI turn could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
        resyncedPlayer: player,
      );
    }
    try {
      final execution = response.require<AonwAiTurnAdvancedResponse>();
      if (execution.actorPlayerId != request.aiPlayerId) {
        throw const FormatException(
          'AI response actor does not match request.',
        );
      }
      return LocalAiTurnExecutionView(
        aiPlayerId: execution.actorPlayerId,
        executedCommands: execution.executedCommands,
        completedTurn: execution.completedTurn,
        player: player,
      );
    } on FormatException catch (error, stackTrace) {
      throw LocalGameSessionException(
        code: 'invalid_ai_turn_protocol',
        message: 'The AI turn response is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
        resyncedPlayer: player,
      );
    }
  });

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

  EngineGameSessionContext _context() {
    final session = _session;
    final map = _map;
    final player = _player;
    final cache = _cache;
    final actorPlayerId = _actorPlayerId;
    if (session == null ||
        map == null ||
        player == null ||
        cache == null ||
        actorPlayerId == null) {
      throw const EngineSessionTransportException(
        code: 'session_not_open',
        message: 'The local game session is not open.',
      );
    }
    return (
      session: session,
      map: map,
      player: player,
      cache: cache,
      actorPlayerId: actorPlayerId,
      generation: _sessionGeneration,
    );
  }

  void _ensureCurrentSession(EngineGameSessionContext context) {
    if (context.generation != _sessionGeneration ||
        !identical(context.session, _session)) {
      throw const EngineSessionTransportException(
        code: 'session_superseded',
        message: 'The local game session was closed or replaced.',
      );
    }
  }

  Future<AonwClientResponse> _send(
    EngineGameSessionContext context,
    AonwClientRequest request,
  ) async {
    _ensureCurrentSession(context);
    final AonwClientResponse response;
    try {
      response = await context.session.send(request);
    } on FormatException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw EngineSessionTransportException(
        code: 'engine_session_request_failed',
        message: 'The engine session request could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
    _ensureCurrentSession(context);
    if (!response.isSuccess) {
      final error = response.error!;
      throw EngineSessionTransportException(
        code: error.code,
        message: 'The engine session request could not be completed.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    return response;
  }

  Future<PlayerMapView> _applyCommandPatch(
    EngineGameSessionContext context,
    AonwCommandResult command,
  ) async {
    _ensureCurrentSession(context);
    try {
      final snapshot = context.cache.apply(command);
      final player = _playerMapper.fromWire(
        snapshot,
        map: context.map,
        actorPlayerId: context.actorPlayerId,
      );
      _player = player;
      return player;
    } on FormatException catch (error, stackTrace) {
      final resyncedPlayer = await _resync(context);
      throw EngineSessionTransportException(
        code: 'recipient_resynchronized',
        message:
            'The recipient view was resynchronized after an invalid patch.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
        resyncedPlayer: resyncedPlayer,
      );
    }
  }

  Future<PlayerMapView> _resync(EngineGameSessionContext context) async {
    _ensureCurrentSession(context);
    final response = await _send(context, AonwClientRequest.snapshot());
    final snapshot = response.require<AonwSnapshotResponse>().snapshot;
    context.cache.replaceAfterResync(snapshot);
    final player = _playerMapper.fromWire(
      snapshot,
      map: context.map,
      actorPlayerId: context.actorPlayerId,
    );
    _player = player;
    return player;
  }

  Future<PlayerMapView> _restoreHuman(
    EngineGameSessionContext context,
    String humanPlayerId,
  ) async {
    _ensureCurrentSession(context);
    final handoff = await context.session.send(
      AonwClientRequest.handoffActor(actorPlayerId: humanPlayerId),
    );
    _ensureCurrentSession(context);
    if (!handoff.isSuccess) {
      final error = handoff.error!;
      throw LocalGameSessionException(
        code: error.code,
        message: 'The human player view could not be restored.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    handoff.require<AonwActorHandedOffResponse>();
    final snapshotResponse = await context.session.send(
      AonwClientRequest.snapshot(),
    );
    _ensureCurrentSession(context);
    if (!snapshotResponse.isSuccess) {
      final error = snapshotResponse.error!;
      throw LocalGameSessionException(
        code: error.code,
        message: 'The human player view could not be restored.',
        diagnosticCause: error,
        diagnosticStackTrace: StackTrace.current,
      );
    }
    final snapshot = snapshotResponse.require<AonwSnapshotResponse>().snapshot;
    context.cache.replaceAfterResync(snapshot);
    final player = _playerMapper.fromWire(
      snapshot,
      map: context.map,
      actorPlayerId: humanPlayerId,
    );
    _player = player;
    _actorPlayerId = humanPlayerId;
    return player;
  }

  Future<PlayerMapView?> _tryRestoreHuman(
    EngineGameSessionContext context,
    String humanPlayerId,
  ) async {
    try {
      return await _restoreHuman(context, humanPlayerId);
    } on Object {
      return null;
    }
  }

  void _retainPlayer(EngineGameSessionContext context, PlayerMapView player) {
    _ensureCurrentSession(context);
    _player = player;
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _requestTail.then((_) => operation());
    _requestTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
