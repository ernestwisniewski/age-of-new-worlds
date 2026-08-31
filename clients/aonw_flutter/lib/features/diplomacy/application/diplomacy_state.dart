import '../read_model/diplomacy_view.dart';

enum DiplomacyFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class DiplomacyFailureView {
  const DiplomacyFailureView(this.code) : rejectionCode = null;

  const DiplomacyFailureView.rejected(this.rejectionCode)
    : code = DiplomacyFailureCode.rejected;

  final DiplomacyFailureCode code;
  final DiplomacyRejectionCodeView? rejectionCode;
}

final class DiplomacyState {
  const DiplomacyState({
    this.correlationId = 0,
    this.inFlightAction,
    this.failure,
  });

  final int correlationId;
  final DiplomacyActionView? inFlightAction;
  final DiplomacyFailureView? failure;

  bool get commandPending => inFlightAction != null;

  DiplomacyState copyWith({
    int? correlationId,
    DiplomacyActionView? inFlightAction,
    bool clearInFlightAction = false,
    DiplomacyFailureView? failure,
    bool clearFailure = false,
  }) => DiplomacyState(
    correlationId: correlationId ?? this.correlationId,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
