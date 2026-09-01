part of 'engine_game_session_gateway.dart';

final class _EngineGameSaveSession implements GameSaveSessionPort {
  const _EngineGameSaveSession(this._owner);

  final EngineGameSessionGateway _owner;

  @override
  Future<String> exportSaveDocument() => _owner._serialize(() async {
    final context = _owner._context();
    try {
      final response = await context.session.send(
        AonwClientRequest.exportSave(),
      );
      _owner._ensureCurrentSession(context);
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
  Future<OpenedGameSaveView> inspectSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    try {
      final prepared = await _prepare(assets, document);
      try {
        return _openedSave(prepared);
      } finally {
        await prepared.session.close();
      }
    } on Object catch (error, stackTrace) {
      throw _saveOpenFailure(error, stackTrace);
    }
  }

  @override
  Future<OpenedGameSaveView> openSaveDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    final generation = ++_owner._loadGeneration;
    try {
      final prepared = await _prepare(assets, document);
      var retained = false;
      try {
        await _owner._activate(
          prepared,
          prepared.scene.player.actorPlayerId,
          generation,
        );
        retained = true;
        return _openedSave(prepared);
      } finally {
        if (!retained) await prepared.session.close();
      }
    } on Object catch (error, stackTrace) {
      throw _saveOpenFailure(error, stackTrace);
    }
  }

  Future<PreparedEngineGameSession> _prepare(
    MapAssetPaths assets,
    String document,
  ) => _owner._loader.prepareSave(assets, saveDocument: document);

  OpenedGameSaveView _openedSave(PreparedEngineGameSession prepared) =>
      OpenedGameSaveView(
        scene: prepared.scene,
        controlPlan: _owner._localMatchMapper.restoredControlPlan(
          prepared.restoredParticipants,
        ),
      );

  GameSaveSessionException _saveOpenFailure(
    Object error,
    StackTrace stackTrace,
  ) {
    if (error is GameSaveSessionException) return error;
    if (error is MapLoadException) {
      return GameSaveSessionException(
        code: error.code,
        message: 'The saved game could not be opened.',
        diagnosticCause: error.diagnosticCause ?? error,
        diagnosticStackTrace: error.diagnosticStackTrace ?? stackTrace,
      );
    }
    return GameSaveSessionException(
      code: 'save_open_failed',
      message: 'The saved game could not be opened.',
      diagnosticCause: error,
      diagnosticStackTrace: stackTrace,
    );
  }
}
