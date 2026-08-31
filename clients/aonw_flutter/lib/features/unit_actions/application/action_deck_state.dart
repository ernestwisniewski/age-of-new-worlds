import '../read_model/unit_action_view.dart';

enum UnitActionFailureViewCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class UnitActionFailure {
  const UnitActionFailure(this.code) : rejectionCode = null;

  const UnitActionFailure.rejected(this.rejectionCode)
    : code = UnitActionFailureViewCode.rejected;

  final UnitActionFailureViewCode code;
  final UnitActionRejectionCodeView? rejectionCode;
}

final class ActionDeckViewState {
  const ActionDeckViewState({
    required this.unitId,
    this.correlationId = 0,
    this.inFlightAction,
    this.failure,
  });

  final String unitId;
  final int correlationId;
  final UnitActionKindView? inFlightAction;
  final UnitActionFailure? failure;

  bool get commandPending => inFlightAction != null;

  ActionDeckViewState copyWith({
    int? correlationId,
    UnitActionKindView? inFlightAction,
    bool clearInFlightAction = false,
    UnitActionFailure? failure,
    bool clearFailure = false,
  }) => ActionDeckViewState(
    unitId: unitId,
    correlationId: correlationId ?? this.correlationId,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
