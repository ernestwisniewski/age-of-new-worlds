part of 'engine_game_session_gateway.dart';

extension _EngineGameSessionGatewaySupport on EngineGameSessionGateway {
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
    _replayPosition = null;
  }

  void _ensureCurrentLoad(int generation) {
    if (generation != _loadGeneration) {
      throw const MapLoadException(
        code: 'map_load_superseded',
        message: 'A newer map load replaced this request.',
      );
    }
  }

  Future<LocalAiTurnExecutionView> _advanceLocalAiTurn(
    LocalAiTurnRequestView request,
  ) => _serialize(() => _executeLocalAiTurn(request));

  Future<LocalAiTurnExecutionView> _executeLocalAiTurn(
    LocalAiTurnRequestView request,
  ) async {
    final context = _context();
    final initialSnapshot = context.cache.snapshot;
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
    return _mapAiTurnResponse(
      response,
      request.aiPlayerId,
      player,
      context,
      initialSnapshot,
    );
  }

  LocalAiTurnExecutionView _mapAiTurnResponse(
    AonwClientResponse response,
    String aiPlayerId,
    PlayerMapView player,
    EngineGameSessionContext context,
    AonwPlayerViewSnapshot initialSnapshot,
  ) {
    try {
      final execution = response.require<AonwAiTurnAdvancedResponse>();
      if (execution.actorPlayerId != aiPlayerId) {
        throw const FormatException(
          'AI response actor does not match request.',
        );
      }
      validateObservedStamp(player.stamp, execution.stamp);
      final observed = ObservedCommandFrames(
        initialSnapshot: initialSnapshot,
        initialPlayer: context.player,
        map: context.map,
        recipientPlayerId: execution.recipientPlayerId,
        commands: execution.commands,
        finalStamp: execution.stamp,
        mapper: _playerMapper,
      );
      _retainPlayer(context, observed.finalPlayer);
      return LocalAiTurnExecutionView(
        aiPlayerId: execution.actorPlayerId,
        executedCommands: execution.executedCommands,
        completedTurn: execution.completedTurn,
        player: observed.finalPlayer,
        frames: observed.frames,
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
        recentFeedback: mapCommandFeedback(
          command: command,
          snapshot: snapshot,
          previous: context.player,
          map: context.map,
        ),
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
