import '../../map/read_model/pending_action_view.dart';
import '../read_model/worker_view.dart';

enum WorkerFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class WorkerFailureView {
  const WorkerFailureView(this.code) : rejectionCode = null;

  const WorkerFailureView.rejected(this.rejectionCode)
    : code = WorkerFailureCode.rejected;

  final WorkerFailureCode code;
  final WorkerRejectionCodeView? rejectionCode;
}

final class WorkerState {
  const WorkerState({
    required this.unitId,
    this.loading = false,
    this.actionsOpen = false,
    this.previewedImprovement,
    this.correlationId = 0,
    this.options,
    this.inFlightAction,
    this.lastAutomation,
    this.failure,
  });

  const WorkerState.loading(String unitId)
    : this(unitId: unitId, loading: true);

  final String unitId;
  final bool loading;
  final bool actionsOpen;
  final FieldImprovementKind? previewedImprovement;
  final int correlationId;
  final WorkerOptionsView? options;
  final WorkerActionView? inFlightAction;
  final WorkerAutomationExecutionView? lastAutomation;
  final WorkerFailureView? failure;

  bool get commandPending => inFlightAction != null;

  WorkerState copyWith({
    bool? loading,
    bool? actionsOpen,
    FieldImprovementKind? previewedImprovement,
    bool clearPreview = false,
    int? correlationId,
    WorkerOptionsView? options,
    bool clearOptions = false,
    WorkerActionView? inFlightAction,
    bool clearInFlightAction = false,
    WorkerAutomationExecutionView? lastAutomation,
    WorkerFailureView? failure,
    bool clearFailure = false,
  }) => WorkerState(
    unitId: unitId,
    loading: loading ?? this.loading,
    actionsOpen: actionsOpen ?? this.actionsOpen,
    previewedImprovement: clearPreview
        ? null
        : previewedImprovement ?? this.previewedImprovement,
    correlationId: correlationId ?? this.correlationId,
    options: clearOptions ? null : options ?? this.options,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    lastAutomation: lastAutomation ?? this.lastAutomation,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
