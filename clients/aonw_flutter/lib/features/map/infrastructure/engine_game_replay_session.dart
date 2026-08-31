part of 'engine_game_session_gateway.dart';

final class _EngineGameReplaySession implements ReplaySessionPort {
  const _EngineGameReplaySession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<String> exportReplayDocument() => _owner._serialize(() async {
    final context = _owner._context();
    try {
      final response = await context.session.send(
        AonwClientRequest.exportReplay(),
      );
      _owner._ensureCurrentSession(context);
      if (!response.isSuccess) {
        final error = response.error!;
        throw ReplaySessionException(
          code: error.code,
          message: 'The current replay could not be exported.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      return response.require<AonwReplayExportedResponse>().document;
    } on ReplaySessionException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw ReplaySessionException(
        code: 'replay_export_failed',
        message: 'The current replay could not be exported.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  });

  @override
  Future<ReplayFrameView> openReplayDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    final generation = ++_owner._loadGeneration;
    try {
      final prepared = await _owner._loader.prepareReplay(
        assets,
        replayDocument: document,
      );
      var retained = false;
      try {
        await _owner._activate(
          PreparedEngineGameSession(
            session: prepared.session,
            scene: prepared.frame.scene,
            cache: prepared.cache,
          ),
          assets.actorPlayerId,
          generation,
        );
        _owner._replayEntryCount = prepared.frame.entryCount;
        retained = true;
        return prepared.frame;
      } finally {
        if (!retained) await prepared.session.close();
      }
    } on MapLoadException catch (error, stackTrace) {
      throw ReplaySessionException(
        code: error.code,
        message: 'The replay could not be opened.',
        diagnosticCause: error.diagnosticCause ?? error,
        diagnosticStackTrace: error.diagnosticStackTrace ?? stackTrace,
      );
    } on ReplaySessionException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw ReplaySessionException(
        code: 'replay_open_failed',
        message: 'The replay could not be opened.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  @override
  Future<ReplayFrameView> seekReplay(int position) =>
      _owner._serialize(() async {
        final context = _owner._context();
        final retainedScene = _owner._scene;
        final retainedEntryCount = _owner._replayEntryCount;
        if (retainedScene == null || retainedEntryCount == null) {
          throw const ReplaySessionException(
            code: 'replay_not_open',
            message: 'Replay playback is not open.',
          );
        }
        try {
          final response = await context.session.send(
            AonwClientRequest.seekReplay(position: position),
          );
          _owner._ensureCurrentSession(context);
          if (!response.isSuccess) {
            final error = response.error!;
            throw ReplaySessionException(
              code: error.code,
              message: 'The replay position could not be opened.',
              diagnosticCause: error,
              diagnosticStackTrace: StackTrace.current,
            );
          }
          final frame = response.require<AonwReplayFrameResponse>();
          if (frame.position != position ||
              frame.entryCount != retainedEntryCount) {
            throw const FormatException(
              'Replay frame identity changed during seek.',
            );
          }
          final player = _owner._playerMapper.fromWire(
            frame.snapshot,
            map: context.map,
            actorPlayerId: context.actorPlayerId,
          );
          final scene = retainedScene.withPlayer(player);
          _owner._player = player;
          _owner._scene = scene;
          _owner._cache = RecipientProjectionCache.open(
            snapshot: frame.snapshot,
            map: context.map,
          );
          return ReplayFrameView(
            position: frame.position,
            entryCount: frame.entryCount,
            scene: scene,
          );
        } on ReplaySessionException {
          rethrow;
        } on Object catch (error, stackTrace) {
          throw ReplaySessionException(
            code: 'invalid_replay_frame',
            message: 'The replay frame is incompatible with this client.',
            diagnosticCause: error,
            diagnosticStackTrace: stackTrace,
          );
        }
      });
}
