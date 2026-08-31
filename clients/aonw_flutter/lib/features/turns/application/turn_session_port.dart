import '../../map/read_model/player_map_view.dart';
import '../read_model/turn_command_view.dart';

abstract interface class TurnSessionPort {
  Future<TurnCommandResultView> endTurn({required int expectedRevision});
}

final class TurnSessionException implements Exception {
  const TurnSessionException({
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
  String toString() => 'TurnSessionException($code): $message';
}
