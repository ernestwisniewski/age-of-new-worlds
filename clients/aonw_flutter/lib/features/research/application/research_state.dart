import '../read_model/research_view.dart';

enum ResearchFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class ResearchFailureView {
  const ResearchFailureView(this.code) : rejectionCode = null;

  const ResearchFailureView.rejected(this.rejectionCode)
    : code = ResearchFailureCode.rejected;

  final ResearchFailureCode code;
  final ResearchRejectionCodeView? rejectionCode;
}

final class ResearchState {
  const ResearchState({
    this.loading = false,
    this.requestedRevision,
    this.options,
    this.correlationId = 0,
    this.inFlightTechnology,
    this.failure,
  });

  const ResearchState.loading(int revision)
    : loading = true,
      requestedRevision = revision,
      options = null,
      correlationId = 0,
      inFlightTechnology = null,
      failure = null;

  final bool loading;
  final int? requestedRevision;
  final ResearchOptionsView? options;
  final int correlationId;
  final TechnologyIdView? inFlightTechnology;
  final ResearchFailureView? failure;

  bool get commandPending => inFlightTechnology != null;

  ResearchState copyWith({
    bool? loading,
    int? requestedRevision,
    ResearchOptionsView? options,
    bool clearOptions = false,
    int? correlationId,
    TechnologyIdView? inFlightTechnology,
    bool clearInFlightTechnology = false,
    ResearchFailureView? failure,
    bool clearFailure = false,
  }) => ResearchState(
    loading: loading ?? this.loading,
    requestedRevision: requestedRevision ?? this.requestedRevision,
    options: clearOptions ? null : options ?? this.options,
    correlationId: correlationId ?? this.correlationId,
    inFlightTechnology: clearInFlightTechnology
        ? null
        : inFlightTechnology ?? this.inFlightTechnology,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
