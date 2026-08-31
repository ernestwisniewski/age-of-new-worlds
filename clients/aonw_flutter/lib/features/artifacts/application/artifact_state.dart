import '../read_model/artifact_view.dart';

enum ArtifactFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class ArtifactFailureView {
  const ArtifactFailureView(this.code) : rejectionCode = null;

  const ArtifactFailureView.rejected(this.rejectionCode)
    : code = ArtifactFailureCode.rejected;

  final ArtifactFailureCode code;
  final ArtifactRejectionCodeView? rejectionCode;
}

final class ArtifactState {
  const ArtifactState({
    this.correlationId = 0,
    this.inFlightAction,
    this.failure,
  });

  final int correlationId;
  final ArtifactActionView? inFlightAction;
  final ArtifactFailureView? failure;

  bool get commandPending => inFlightAction != null;

  ArtifactState copyWith({
    int? correlationId,
    ArtifactActionView? inFlightAction,
    bool clearInFlightAction = false,
    ArtifactFailureView? failure,
    bool clearFailure = false,
  }) => ArtifactState(
    correlationId: correlationId ?? this.correlationId,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
