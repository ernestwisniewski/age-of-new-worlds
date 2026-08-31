part of 'worker_workflow.dart';

GameSessionReady? _selectedWorker(GameSessionState state, String unitId) =>
    state is GameSessionReady &&
        state.interaction.selectedUnitId == unitId &&
        state.interaction.worker?.unitId == unitId
    ? state
    : null;

GameSessionReady? _selectedWorkerAtRevision(
  GameSessionState state,
  String unitId,
  int revision,
) {
  final ready = _selectedWorker(state, unitId);
  return ready?.recipient.stamp.revision == revision ? ready : null;
}

GameSessionReady? _executableWorker(
  GameSessionState state,
  WorkerActionView action,
) {
  final current = _selectedWorker(state, action.unitId);
  final worker = current?.interaction.worker;
  if (current == null ||
      current.research.commandPending ||
      current.diplomacy.commandPending ||
      worker == null ||
      worker.loading ||
      worker.commandPending ||
      !_containsWorkerAction(current, worker.options, action)) {
    return null;
  }
  return current;
}

bool _containsWorkerAction(
  GameSessionReady current,
  WorkerOptionsView? options,
  WorkerActionView action,
) {
  if (options == null || options.unitId != action.unitId) return false;
  final unit = current.recipient.controlledUnitById(action.unitId);
  if (unit == null) return false;
  return switch (action) {
    SelectWorkerImprovementActionView(:final improvement) =>
      options.improvements.any((option) => option.improvement == improvement),
    ConfirmWorkerImprovementActionView(:final improvement) =>
      current.recipient.pendingAction is PendingWorkerActionSelectionView &&
          (current.recipient.pendingAction! as PendingWorkerActionSelectionView)
                  .unitId ==
              action.unitId &&
          (current.recipient.pendingAction! as PendingWorkerActionSelectionView)
                  .improvement ==
              improvement,
    CancelWorkerJobActionView() => unit.workerJob != null,
    AssignWorkerToHexActionView() => options.canAssign,
    CancelWorkerAssignmentActionView() => unit.workerAssignment != null,
    BuildRoadActionView() => options.canBuildRoad,
    AutomateWorkerActionView(:final option) => identical(
      options.automation,
      option,
    ),
  };
}

GameSessionReady? _correlatedWorker(
  GameSessionState state,
  String unitId,
  int correlationId,
) {
  final ready = _selectedWorker(state, unitId);
  return ready?.interaction.worker?.correlationId == correlationId
      ? ready
      : null;
}

MapInteractionState _clearWorkerSelection(GameSessionReady current) =>
    current.interaction.copyWith(
      clearSelected: true,
      clearSelectedUnit: true,
      clearReachable: true,
      clearRoute: true,
      clearActionDeck: true,
      clearUnitLogistics: true,
      clearWorker: true,
      clearProduction: true,
    );

WorkerFailureCode _failureCode(String code) => switch (code) {
  'invalid_session_protocol' => WorkerFailureCode.responseIncompatible,
  'session_not_open' => WorkerFailureCode.sessionUnavailable,
  _ => WorkerFailureCode.requestFailed,
};
