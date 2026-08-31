import 'package:aonw_engine_client/aonw_engine_client.dart';

import '../read_model/player_map_view.dart';
import 'engine_game_session_context.dart';

typedef EngineRequestSender =
    Future<AonwClientResponse> Function(
      EngineGameSessionContext context,
      AonwClientRequest request,
    );
typedef EnginePatchApplier =
    Future<PlayerMapView> Function(
      EngineGameSessionContext context,
      AonwCommandResult command,
    );

/// Failure raised by the shared engine session boundary before a feature maps it
/// to its application-facing exception.
final class EngineSessionTransportException implements Exception {
  const EngineSessionTransportException({
    required this.code,
    required this.message,
    this.diagnosticCause,
    this.diagnosticStackTrace,
    this.resyncedPlayer,
  });

  final String code;
  final String message;
  final Object? diagnosticCause;
  final StackTrace? diagnosticStackTrace;
  final PlayerMapView? resyncedPlayer;

  @override
  String toString() => 'EngineSessionTransportException($code): $message';
}
