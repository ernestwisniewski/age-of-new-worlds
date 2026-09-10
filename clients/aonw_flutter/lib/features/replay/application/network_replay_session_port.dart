import '../../map/application/map_session_port.dart';
import '../read_model/replay_frame_view.dart';

/// Opens a completed online match on the shared replay playback session.
abstract interface class NetworkReplaySessionPort {
  Future<ReplayFrameView> openNetworkReplay({
    required String userId,
    required String matchId,
    required String mapHash,
    required String rulesetHash,
    required MapAssetPaths assets,
  });
}
