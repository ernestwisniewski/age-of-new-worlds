import '../../map/read_model/map_view.dart';
import '../read_model/combat_view.dart';

enum CombatFailureCode {
  requestFailed,
  responseIncompatible,
  sessionUnavailable,
  targetUnavailable,
  rejected,
}

final class CombatFailureView {
  const CombatFailureView(this.code) : rejectionCode = null;

  const CombatFailureView.rejected(this.rejectionCode)
    : code = CombatFailureCode.rejected;

  final CombatFailureCode code;
  final CombatRejectionCodeView? rejectionCode;
}

final class CombatState {
  const CombatState({
    required this.attackerUnitId,
    required this.defenderCoordinate,
    this.loading = false,
    this.correlationId = 0,
    this.preview,
    this.cityConquestAction = CityConquestActionView.capture,
    this.commandPending = false,
    this.failure,
    this.lastExecution,
  });

  const CombatState.loading({
    required String attackerUnitId,
    required MapHexCoordinate defenderCoordinate,
    required int correlationId,
  }) : this(
         attackerUnitId: attackerUnitId,
         defenderCoordinate: defenderCoordinate,
         correlationId: correlationId,
         loading: true,
       );

  final String attackerUnitId;
  final MapHexCoordinate defenderCoordinate;
  final bool loading;
  final int correlationId;
  final CombatPreviewView? preview;
  final CityConquestActionView cityConquestAction;
  final bool commandPending;
  final CombatFailureView? failure;
  final CombatExecutionView? lastExecution;

  CombatState copyWith({
    bool? loading,
    int? correlationId,
    CombatPreviewView? preview,
    bool clearPreview = false,
    CityConquestActionView? cityConquestAction,
    bool? commandPending,
    CombatFailureView? failure,
    bool clearFailure = false,
    CombatExecutionView? lastExecution,
    bool clearLastExecution = false,
  }) => CombatState(
    attackerUnitId: attackerUnitId,
    defenderCoordinate: defenderCoordinate,
    loading: loading ?? this.loading,
    correlationId: correlationId ?? this.correlationId,
    preview: clearPreview ? null : preview ?? this.preview,
    cityConquestAction: cityConquestAction ?? this.cityConquestAction,
    commandPending: commandPending ?? this.commandPending,
    failure: clearFailure ? null : failure ?? this.failure,
    lastExecution: clearLastExecution
        ? null
        : lastExecution ?? this.lastExecution,
  );
}
