import '../read_model/map_scene.dart';

final class NetworkMatchSetupView {
  const NetworkMatchSetupView({required this.matchId, required this.playerId});

  final String matchId;
  final String playerId;
}

enum NetworkGameConnectionPhase {
  inactive,
  connecting,
  ready,
  reconnecting,
  resyncing,
  failed,
}

final class NetworkGameConnectionView {
  const NetworkGameConnectionView(this.phase, {this.failureCode})
    : assert(
        phase == NetworkGameConnectionPhase.failed
            ? failureCode != null && failureCode != ''
            : failureCode == null,
      );

  static const inactive = NetworkGameConnectionView(
    NetworkGameConnectionPhase.inactive,
  );

  final NetworkGameConnectionPhase phase;
  final String? failureCode;

  bool get blocksGameplay => switch (phase) {
    NetworkGameConnectionPhase.inactive ||
    NetworkGameConnectionPhase.ready => false,
    _ => true,
  };
}

abstract interface class NetworkGameSessionPort {
  NetworkGameConnectionView get connection;

  Stream<NetworkGameConnectionView> get connectionChanges;

  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup);

  Future<MapScene> reconnectNetworkMatch();
}
