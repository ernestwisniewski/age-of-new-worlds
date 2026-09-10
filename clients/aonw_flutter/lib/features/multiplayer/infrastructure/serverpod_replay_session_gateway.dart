import '../../map/application/map_session_port.dart';
import '../../map/infrastructure/engine_game_session_gateway.dart';
import '../../replay/application/network_replay_session_port.dart';
import '../../replay/application/replay_session_port.dart';
import '../../replay/read_model/replay_frame_view.dart';
import 'serverpod_multiplayer_session.dart';

/// Installs read-only Serverpod playback on the existing engine view gateway.
final class ServerpodReplaySessionGateway implements NetworkReplaySessionPort {
  const ServerpodReplaySessionGateway({
    required EngineGameSessionGateway gameplay,
    required ServerpodMultiplayerSession multiplayer,
  }) : _gameplay = gameplay,
       _multiplayer = multiplayer;

  final EngineGameSessionGateway _gameplay;
  final ServerpodMultiplayerSession _multiplayer;

  @override
  Future<ReplayFrameView> openNetworkReplay({
    required String userId,
    required String matchId,
    required String mapHash,
    required String rulesetHash,
    required MapAssetPaths assets,
  }) async {
    try {
      return await _gameplay.startRemoteReplay(
        assets: assets,
        session: _multiplayer.openReplayTransport(
          userId: userId,
          matchId: matchId,
          playerId: assets.actorPlayerId,
          mapHash: mapHash,
          rulesetHash: rulesetHash,
        ),
      );
    } on Object catch (error, stackTrace) {
      throw ReplaySessionException(
        code: 'online_replay_open_failed',
        message: 'The online replay could not be opened.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}
