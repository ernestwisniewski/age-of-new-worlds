import 'package:aonw_server_client/aonw_server_client.dart' as server;

import '../application/multiplayer_access_port.dart';
import 'server_connection_config.dart';

final class ServerpodMultiplayerAccess implements MultiplayerAccessPort {
  const ServerpodMultiplayerAccess({required ServerConnectionConfig config})
    : _config = config;

  final ServerConnectionConfig _config;

  @override
  Future<MultiplayerAccessStatus> check() async {
    final client = server.Client(
      _config.host,
      connectionTimeout: _config.requestTimeout,
    );
    try {
      final status = await client.appStatus
          .versionStatus(
            platform: _config.platform,
            buildNumber: _config.buildNumber,
          )
          .timeout(_config.requestTimeout);
      return switch (status) {
        'current' => MultiplayerAccessStatus.current,
        'soon' => MultiplayerAccessStatus.updateRequired,
        _ => throw FormatException(
          'The server returned an unknown version status.',
          status,
        ),
      };
    } finally {
      client.close();
    }
  }
}
