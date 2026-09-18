import '../read_model/production_view.dart';
import 'production_inspection_state.dart';

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
    this.catalogOpen = false,
    this.correlationId = 0,
    this.options,
    this.resources,
    this.inFlightAction,
    this.failure,
    this.inspection,
  });

  const ProductionState.loading(
    String cityId, {
    bool catalogOpen = false,
    ProductionInspectionState? inspection,
  }) : this(
         cityId: cityId,
         loading: true,
         catalogOpen: catalogOpen,
         inspection: inspection,
       );

  final String cityId;
  final bool loading;
  final bool catalogOpen;
  final int correlationId;
  final ProductionOptionsView? options;
  final StrategicResourceProjectionView? resources;
  final ProductionActionView? inFlightAction;
  final ProductionFailureView? failure;
  final ProductionInspectionState? inspection;

  bool get commandPending => inFlightAction != null;

  ProductionState invalidateInspection({bool clear = false}) {
    final selected = inspection;
    return copyWith(
      clearInspection: clear,
      inspection: selected == null || clear
          ? null
          : ProductionInspectionState(
              target: selected.target,
              correlationId: selected.correlationId,
            ),
    );
  }

  ProductionState copyWith({
    bool? loading,
    bool? catalogOpen,
    int? correlationId,
    ProductionOptionsView? options,
    StrategicResourceProjectionView? resources,
    ProductionActionView? inFlightAction,
    bool clearInFlightAction = false,
    ProductionFailureView? failure,
    bool clearFailure = false,
    ProductionInspectionState? inspection,
    bool clearInspection = false,
  }) => ProductionState(
    cityId: cityId,
    loading: loading ?? this.loading,
    catalogOpen: catalogOpen ?? this.catalogOpen,
    correlationId: correlationId ?? this.correlationId,
    options: options ?? this.options,
    resources: resources ?? this.resources,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
    inspection: clearInspection ? null : inspection ?? this.inspection,
  );
}
