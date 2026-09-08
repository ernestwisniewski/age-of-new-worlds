import '../read_model/hex_inspection_view.dart';
import '../read_model/map_view.dart';
import '../read_model/player_map_view.dart';

abstract interface class HexInspectionSessionPort {
  Future<HexInspectionView> inspectHex({
    required int expectedRevision,
    required MapHexCoordinate coordinate,
  });
}

final class HexInspectionSessionException implements Exception {
  const HexInspectionSessionException({
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
}
