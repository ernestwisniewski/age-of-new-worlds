import '../../map/read_model/player_map_view.dart';
import '../read_model/unit_action_view.dart';

abstract interface class UnitActionSessionPort {
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  });
}

final class UnitActionSessionException implements Exception {
  const UnitActionSessionException({
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
  String toString() => 'UnitActionSessionException($code): $message';
}
