import '../../map/read_model/map_view.dart';
import '../../map/read_model/player_map_view.dart';
import '../read_model/combat_view.dart';

abstract interface class CombatSessionPort {
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  });

  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  });
}

final class CombatSessionException implements Exception {
  const CombatSessionException({
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
