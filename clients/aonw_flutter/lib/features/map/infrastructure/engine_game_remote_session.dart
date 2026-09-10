part of 'engine_game_session_gateway.dart';

extension EngineGameSessionGatewayRemote on EngineGameSessionGateway {
  Future<ReplayFrameView> startRemoteReplay({
    required MapAssetPaths assets,
    required AonwEngineSession session,
  }) async {
    final generation = ++_loadGeneration;
    var retained = false;
    try {
      final response = await session.send(
        AonwClientRequest.seekReplay(position: 0),
      );
      final frame = response.require<AonwReplayFrameResponse>();
      if (frame.position != 0 ||
          frame.command != null ||
          frame.recipientPlayerId != assets.actorPlayerId) {
        throw const FormatException(
          'The initial replay frame is inconsistent.',
        );
      }
      final prepared = await _loader.prepareRemote(assets, session: session);
      final stamp = prepared.cache.snapshot.stamp;
      if (stamp.revision != frame.snapshot.stamp.revision ||
          stamp.stateDigest != frame.snapshot.stamp.stateDigest ||
          stamp.mapHash != frame.snapshot.stamp.mapHash ||
          stamp.rulesetHash != frame.snapshot.stamp.rulesetHash) {
        throw const FormatException('Replay changed while preparing the map.');
      }
      await _activate(prepared, assets.actorPlayerId, generation);
      _replayEntryCount = frame.entryCount;
      _replayPosition = 0;
      retained = true;
      return ReplayFrameView(
        position: 0,
        entryCount: frame.entryCount,
        scene: prepared.scene,
      );
    } finally {
      if (!retained) await session.close();
    }
  }

  Future<MapScene> startRemoteMatch({
    required MapAssetPaths assets,
    required AonwEngineSession session,
  }) async {
    final generation = ++_loadGeneration;
    final prepared = await _loader.prepareRemote(assets, session: session);
    var retained = false;
    try {
      await _activate(prepared, assets.actorPlayerId, generation);
      retained = true;
      return prepared.scene;
    } finally {
      if (!retained) await prepared.session.close();
    }
  }
}
