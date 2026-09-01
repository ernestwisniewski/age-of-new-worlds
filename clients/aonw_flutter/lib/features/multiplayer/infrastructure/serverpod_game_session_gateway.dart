import '../../map/application/map_session_port.dart';
import '../../map/application/network_game_session_port.dart';
import '../../map/infrastructure/engine_game_session_gateway.dart';
import '../../map/read_model/map_scene.dart';
import 'serverpod_multiplayer_session.dart';

/// Opens an authenticated Serverpod match through the shared gameplay gateway.
final class ServerpodGameSessionGateway implements NetworkGameSessionPort {
  const ServerpodGameSessionGateway({
    required EngineGameSessionGateway gameplay,
    required ServerpodMultiplayerSession multiplayer,
    this.assets = MapAssetPaths.starter,
  }) : _gameplay = gameplay,
       _multiplayer = multiplayer;

  final EngineGameSessionGateway _gameplay;
  final ServerpodMultiplayerSession _multiplayer;
  final MapAssetPaths assets;

  @override
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup) =>
      _gameplay.startRemoteMatch(
        assets: MapAssetPaths(
          document: assets.document,
          bundleManifest: assets.bundleManifest,
          scenarioDocument: assets.scenarioDocument,
          actorPlayerId: setup.playerId,
        ),
        session: _multiplayer.openGameTransport(setup.matchId),
      );
}
