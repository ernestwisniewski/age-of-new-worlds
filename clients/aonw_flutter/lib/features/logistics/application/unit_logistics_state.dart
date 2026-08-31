import '../read_model/unit_logistics_view.dart';

enum UnitLogisticsFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class UnitLogisticsFailureView {
  const UnitLogisticsFailureView(this.code) : rejectionCode = null;

  const UnitLogisticsFailureView.rejected(this.rejectionCode)
    : code = UnitLogisticsFailureCode.rejected;

  final UnitLogisticsFailureCode code;
  final UnitLogisticsRejectionCodeView? rejectionCode;
}

final class UnitLogisticsState {
  const UnitLogisticsState({
    required this.unitId,
    this.loading = false,
    this.correlationId = 0,
    this.options,
    this.inFlightAction,
    this.failure,
  });

  const UnitLogisticsState.loading(String unitId)
    : this(unitId: unitId, loading: true);

  final String unitId;
  final bool loading;
  final int correlationId;
  final UnitLogisticsOptionsView? options;
  final UnitLogisticsActionView? inFlightAction;
  final UnitLogisticsFailureView? failure;

  bool get commandPending => inFlightAction != null;

  UnitLogisticsState copyWith({
    bool? loading,
    int? correlationId,
    UnitLogisticsOptionsView? options,
    bool clearOptions = false,
    UnitLogisticsActionView? inFlightAction,
    bool clearInFlightAction = false,
    UnitLogisticsFailureView? failure,
    bool clearFailure = false,
  }) => UnitLogisticsState(
    unitId: unitId,
    loading: loading ?? this.loading,
    correlationId: correlationId ?? this.correlationId,
    options: clearOptions ? null : options ?? this.options,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
