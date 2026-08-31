import '../../map/read_model/player_map_view.dart';
import '../read_model/artifact_view.dart';

abstract interface class ArtifactSessionPort {
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  });
}

final class ArtifactSessionException implements Exception {
  const ArtifactSessionException({
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

final class ArtifactCommandResultView {
  const ArtifactCommandResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const ArtifactCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null;

  final bool accepted;
  final ArtifactRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}
