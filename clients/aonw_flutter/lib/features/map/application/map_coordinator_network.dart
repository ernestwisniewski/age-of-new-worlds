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

  Future<bool> reconnectNetworkMatch() async {
    final networkGame = _capabilities.networkGame;
    final current = _state;
    if (_disposed || networkGame == null || current is! GameSessionReady) {
      return false;
    }
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    try {
      final scene = await networkGame.reconnectNetworkMatch();
      if (!_isCurrent(generation)) return false;
      _setCursor(null);
      _setState(GameSessionReady.initial(scene));
      return true;
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return false;
      _diagnosticReporter('network_resync_failed', error, stackTrace);
      return false;
    }
  }
}
