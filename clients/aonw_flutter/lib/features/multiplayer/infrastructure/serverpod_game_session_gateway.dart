import 'dart:async';

import '../../map/application/map_session_port.dart';
import '../../map/application/network_game_session_port.dart';
import '../../map/infrastructure/engine_game_session_gateway.dart';
import '../../map/read_model/map_scene.dart';
import '../application/multiplayer_session_port.dart';
import 'serverpod_multiplayer_session.dart';

/// Opens an authenticated Serverpod match through the shared gameplay gateway.
final class ServerpodGameSessionGateway implements NetworkGameSessionPort {
  ServerpodGameSessionGateway({
    required EngineGameSessionGateway gameplay,
    required ServerpodMultiplayerSession multiplayer,
    this.assets = MapAssetPaths.starter,
  }) : _gameplay = gameplay,
       _multiplayer = multiplayer;

  final EngineGameSessionGateway _gameplay;
  final ServerpodMultiplayerSession _multiplayer;
  final MapAssetPaths assets;
  final StreamController<NetworkGameConnectionView> _connectionChanges =
      StreamController<NetworkGameConnectionView>.broadcast(sync: true);
  NetworkGameConnectionView _connection = NetworkGameConnectionView.inactive;
  NetworkMatchSetupView? _setup;

  @override
  NetworkGameConnectionView get connection => _connection;

  @override
  Stream<NetworkGameConnectionView> get connectionChanges =>
      _connectionChanges.stream;

  @override
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup) async {
    _setup = setup;
    _publish(
      const NetworkGameConnectionView(NetworkGameConnectionPhase.connecting),
    );
    try {
      final scene = await _open(setup);
      _publish(
        const NetworkGameConnectionView(NetworkGameConnectionPhase.ready),
      );
      return scene;
    } on Object catch (error) {
      _publishFailure(_failureCode(error));
      rethrow;
    }
  }

  @override
  Future<MapScene> reconnectNetworkMatch() async {
    final setup = _setup;
    if (setup == null) {
      throw StateError('No network match is available for reconnect.');
    }
    _publish(
      const NetworkGameConnectionView(NetworkGameConnectionPhase.reconnecting),
    );
    try {
      await _multiplayer.reconnect();
      _publish(
        const NetworkGameConnectionView(NetworkGameConnectionPhase.resyncing),
      );
      final scene = await _open(setup);
      _publish(
        const NetworkGameConnectionView(NetworkGameConnectionPhase.ready),
      );
      return scene;
    } on Object catch (error) {
      _publishFailure(_failureCode(error));
      rethrow;
    }
  }

  Future<MapScene> _open(NetworkMatchSetupView setup) =>
      _gameplay.startRemoteMatch(
        assets: MapAssetPaths(
          document: assets.document,
          bundleManifest: assets.bundleManifest,
          scenarioDocument: assets.scenarioDocument,
          actorPlayerId: setup.playerId,
        ),
        session: _multiplayer.openGameTransport(
          setup.matchId,
          onReconnecting: () => _publish(
            const NetworkGameConnectionView(
              NetworkGameConnectionPhase.reconnecting,
            ),
          ),
          onRecovered: () => _publish(
            const NetworkGameConnectionView(NetworkGameConnectionPhase.ready),
          ),
          onRecoveryFailed: _publishFailure,
        ),
      );

  void _publishFailure(String code) => _publish(
    NetworkGameConnectionView(
      NetworkGameConnectionPhase.failed,
      failureCode: code,
    ),
  );

  void _publish(NetworkGameConnectionView value) {
    if (_connection.phase == value.phase &&
        _connection.failureCode == value.failureCode) {
      return;
    }
    _connection = value;
    _connectionChanges.add(value);
  }
}

String _failureCode(Object error) => switch (error) {
  MultiplayerSessionException(:final code) => code,
  MapLoadException(:final code) => code,
  _ => 'connection_interrupted',
};
