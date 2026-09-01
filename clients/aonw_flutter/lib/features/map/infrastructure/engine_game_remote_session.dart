part of 'engine_game_session_gateway.dart';

extension EngineGameSessionGatewayRemote on EngineGameSessionGateway {
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
