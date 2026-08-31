import '../read_model/turn_command_view.dart';

enum TurnFailureViewCode {
  sessionUnavailable,
  responseIncompatible,
  requestFailed,
}

final class TurnActionFailureView {
  const TurnActionFailureView.transport(this.code) : rejectionCode = null;

  const TurnActionFailureView.rejected(this.rejectionCode) : code = null;

  final TurnFailureViewCode? code;
  final TurnRejectionCodeView? rejectionCode;
}

final class TurnActionState {
  const TurnActionState({
    this.correlationId = 0,
    this.inFlight = false,
    this.failure,
  });

  final int correlationId;
  final bool inFlight;
  final TurnActionFailureView? failure;

  TurnActionState copyWith({
    int? correlationId,
    bool? inFlight,
    TurnActionFailureView? failure,
    bool clearFailure = false,
  }) => TurnActionState(
    correlationId: correlationId ?? this.correlationId,
    inFlight: inFlight ?? this.inFlight,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
