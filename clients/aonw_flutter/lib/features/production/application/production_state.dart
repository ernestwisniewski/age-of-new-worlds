import '../read_model/production_view.dart';

enum ProductionFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class ProductionFailureView {
  const ProductionFailureView(this.code) : rejectionCode = null;

  const ProductionFailureView.rejected(this.rejectionCode)
    : code = ProductionFailureCode.rejected;

  final ProductionFailureCode code;
  final ProductionRejectionCodeView? rejectionCode;
}

final class ProductionState {
  const ProductionState({
    required this.cityId,
    this.loading = false,
    this.correlationId = 0,
    this.options,
    this.resources,
    this.inFlightAction,
    this.failure,
  });

  const ProductionState.loading(String cityId)
    : this(cityId: cityId, loading: true);

  final String cityId;
  final bool loading;
  final int correlationId;
  final ProductionOptionsView? options;
  final StrategicResourceProjectionView? resources;
  final ProductionActionView? inFlightAction;
  final ProductionFailureView? failure;

  bool get commandPending => inFlightAction != null;

  ProductionState copyWith({
    bool? loading,
    int? correlationId,
    ProductionOptionsView? options,
    StrategicResourceProjectionView? resources,
    ProductionActionView? inFlightAction,
    bool clearInFlightAction = false,
    ProductionFailureView? failure,
    bool clearFailure = false,
  }) => ProductionState(
    cityId: cityId,
    loading: loading ?? this.loading,
    correlationId: correlationId ?? this.correlationId,
    options: options ?? this.options,
    resources: resources ?? this.resources,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
