part of 'engine_game_session_loader.dart';

extension EngineGameSessionLoaderRemote on EngineGameSessionLoader {
  Future<PreparedEngineGameSession> prepareRemote(
    MapAssetPaths assets, {
    required AonwEngineSession session,
  }) async {
    try {
      return await _prepareRemote(session, assets);
    } on MapLoadException {
      await session.close();
      rethrow;
    } on FormatException catch (error, stackTrace) {
      await session.close();
      throw MapLoadException(
        code: 'invalid_map_protocol',
        message: 'The multiplayer map data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } on Object {
      await session.close();
      rethrow;
    }
  }

  Future<PreparedEngineGameSession> _prepareRemote(
    AonwEngineSession session,
    MapAssetPaths assets,
  ) async {
    final inspector = await _sessionFactory();
    if (inspector == null) {
      throw const MapLoadException(
        code: 'engine_adapter_unavailable',
        message: 'The engine map adapter is unavailable on this platform.',
      );
    }
    final MapView map;
    try {
      await EngineGameSessionLoader._verifyCapabilities(
        inspector,
        _remoteInspectorFeatures,
      );
      final document = await _assets.loadString(assets.document);
      map = await _inspectMap(inspector, document);
    } finally {
      await inspector.close();
    }
    final response = await session.send(AonwClientRequest.snapshot());
    final snapshot =
        EngineGameSessionLoader._loadResponse<AonwSnapshotResponse>(
          response,
          'The multiplayer player view could not be loaded.',
        ).snapshot;
    final player = _playerMapper.fromWire(
      snapshot,
      map: map,
      actorPlayerId: assets.actorPlayerId,
    );
    final reference = await _bundleLoader.load(
      manifestAsset: assets.bundleManifest,
      map: map,
    );
    return PreparedEngineGameSession(
      session: session,
      scene: MapScene(map: map, reference: reference, player: player),
      cache: RecipientProjectionCache.open(snapshot: snapshot, map: map),
    );
  }
}

const _remoteInspectorFeatures = <AonwClientFeature>{
  AonwClientFeature.inspectMap,
};
