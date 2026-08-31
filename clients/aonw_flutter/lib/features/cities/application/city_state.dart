import '../read_model/city_view.dart';

enum CityFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  rejected,
}

final class CityFailureView {
  const CityFailureView(this.code) : rejectionCode = null;

  const CityFailureView.rejected(this.rejectionCode)
    : code = CityFailureCode.rejected;

  final CityFailureCode code;
  final CityRejectionCodeView? rejectionCode;
}

final class CityState {
  const CityState({
    this.cityId,
    this.founderUnitId,
    this.loading = false,
    this.correlationId = 0,
    this.inspection,
    this.foundingOptions,
    this.foundingSelection = const [],
    this.inFlightAction,
    this.failure,
  });

  const CityState.loadingCity(String cityId)
    : this(cityId: cityId, loading: true);

  const CityState.loadingFounding(String founderUnitId)
    : this(founderUnitId: founderUnitId, loading: true);

  final String? cityId;
  final String? founderUnitId;
  final bool loading;
  final int correlationId;
  final CityInspectionView? inspection;
  final CityFoundingOptionsView? foundingOptions;
  final List<({int col, int row})> foundingSelection;
  final CityActionView? inFlightAction;
  final CityFailureView? failure;

  bool get commandPending => inFlightAction != null;

  CityState copyWith({
    bool? loading,
    int? correlationId,
    CityInspectionView? inspection,
    bool clearInspection = false,
    CityFoundingOptionsView? foundingOptions,
    bool clearFoundingOptions = false,
    List<({int col, int row})>? foundingSelection,
    CityActionView? inFlightAction,
    bool clearInFlightAction = false,
    CityFailureView? failure,
    bool clearFailure = false,
  }) => CityState(
    cityId: cityId,
    founderUnitId: founderUnitId,
    loading: loading ?? this.loading,
    correlationId: correlationId ?? this.correlationId,
    inspection: clearInspection ? null : inspection ?? this.inspection,
    foundingOptions: clearFoundingOptions
        ? null
        : foundingOptions ?? this.foundingOptions,
    foundingSelection: foundingSelection ?? this.foundingSelection,
    inFlightAction: clearInFlightAction
        ? null
        : inFlightAction ?? this.inFlightAction,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
