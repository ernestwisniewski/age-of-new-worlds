part of 'map_coordinator.dart';

extension MapCoordinatorNetwork on MapCoordinator {
  Future<bool> startNetworkMatch(NetworkMatchSetupView setup) => _openSession(
    () {
      final networkGame = _capabilities.networkGame;
      if (networkGame == null) {
        throw const MapLoadException(
          code: 'network_game_unavailable',
          message: 'The network game session is unavailable.',
        );
      }
      return networkGame.startNetworkMatch(setup);
    },
    localGameEntry: null,
    controlPlan: null,
  );
}
