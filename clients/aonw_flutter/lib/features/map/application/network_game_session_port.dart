import '../read_model/map_scene.dart';

final class NetworkMatchSetupView {
  const NetworkMatchSetupView({required this.matchId, required this.playerId});

  final String matchId;
  final String playerId;
}

abstract interface class NetworkGameSessionPort {
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup);
}
