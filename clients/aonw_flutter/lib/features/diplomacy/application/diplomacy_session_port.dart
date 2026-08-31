import '../../map/read_model/player_map_view.dart';
import '../read_model/diplomacy_view.dart';

abstract interface class DiplomacySessionPort {
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  });
}

final class DiplomacySessionException implements Exception {
  const DiplomacySessionException({
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

final class DiplomacyCommandResultView {
  const DiplomacyCommandResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const DiplomacyCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null;

  final bool accepted;
  final DiplomacyRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}
