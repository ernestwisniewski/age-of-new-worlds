import '../../map/read_model/player_map_view.dart';
import '../read_model/research_view.dart';

abstract interface class ResearchSessionPort {
  Future<ResearchOptionsView> researchOptions({required int expectedRevision});

  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  });
}

final class ResearchSessionException implements Exception {
  const ResearchSessionException({
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

final class ResearchCommandResultView {
  const ResearchCommandResultView.accepted({required this.player})
    : accepted = true,
      rejectionCode = null;

  const ResearchCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null;

  final bool accepted;
  final ResearchRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
}
