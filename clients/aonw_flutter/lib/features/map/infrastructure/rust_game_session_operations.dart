import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/player_map_view.dart';
import 'rust_game_session_context.dart';

typedef RustRequestSender =
    Future<AonwClientResponse> Function(
      AonwRustSession session,
      AonwClientRequest request,
    );
typedef RustPatchApplier =
    Future<PlayerMapView> Function(
      RustGameSessionContext context,
      AonwCommandResult command,
    );

/// Failure raised by the shared Rust session boundary before a feature maps it
/// to its application-facing exception.
final class RustSessionTransportException implements Exception {
  const RustSessionTransportException({
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
  String toString() => 'RustSessionTransportException($code): $message';
}
