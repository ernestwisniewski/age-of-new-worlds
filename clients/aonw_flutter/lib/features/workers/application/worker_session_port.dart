import '../../map/read_model/player_map_view.dart';
import '../read_model/worker_view.dart';

abstract interface class WorkerSessionPort {
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  });

  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  });
}

final class WorkerCommandResultView {
  const WorkerCommandResultView.accepted({
    required this.player,
    required this.automation,
  }) : accepted = true,
       rejectionCode = null;

  const WorkerCommandResultView.rejected({required this.rejectionCode})
    : accepted = false,
      player = null,
      automation = null;

  final bool accepted;
  final WorkerRejectionCodeView? rejectionCode;
  final PlayerMapView? player;
  final WorkerAutomationExecutionView? automation;
}

final class WorkerSessionException implements Exception {
  const WorkerSessionException({
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
