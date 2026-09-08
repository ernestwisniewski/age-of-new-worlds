part of 'worker_workflow.dart';

extension WorkerWorkflowSelection on WorkerWorkflow {
  void setActionsOpen({
    required String unitId,
    required bool open,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
  }) {
    final current = _selectedWorker(readState(), unitId);
    final worker = current?.interaction.worker;
    if (current == null || worker == null || worker.actionsOpen == open) return;
    if (worker.loading || worker.commandPending) return;
    if (open && !_canOpenWorkerActions(current)) return;
    publish(
      current.withInteraction(
        current.interaction.copyWith(
          selected: open ? worker.options!.coordinate : null,
          clearRoute: open,
          clearCombat: open,
          worker: worker.copyWith(
            actionsOpen: open,
            clearPreview: true,
            clearFailure: true,
          ),
        ),
      ),
    );
  }

  void previewImprovement({
    required String unitId,
    required FieldImprovementKind improvement,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
  }) {
    final current = _selectedWorker(readState(), unitId);
    if (current == null || !_canPreviewImprovement(current, improvement)) {
      return;
    }
    final worker = current.interaction.worker!;
    if (worker.previewedImprovement == improvement) return;
    publish(
      current.withInteraction(
        current.interaction.copyWith(
          worker: worker.copyWith(
            previewedImprovement: improvement,
            clearFailure: true,
          ),
        ),
      ),
    );
  }
}

bool _canOpenWorkerActions(GameSessionReady current) {
  if (current.recipient.pendingAction is PendingResearchSelectionView) {
    return false;
  }
  final worker = current.interaction.worker;
  final options = worker?.options;
  if (worker == null || options == null || options.improvements.isEmpty) {
    return false;
  }
  final unit = current.recipient.controlledUnitById(worker.unitId);
  return unit != null &&
      unit.kind == VisibleUnitKind.worker &&
      unit.workerJob == null &&
      options.unitId == unit.id &&
      options.coordinate == unit.coordinate &&
      _sameWorkerStamp(options.stamp, current.recipient.stamp);
}

bool _canPreviewImprovement(
  GameSessionReady current,
  FieldImprovementKind kind,
) {
  final worker = current.interaction.worker;
  return worker != null &&
      worker.actionsOpen &&
      !worker.loading &&
      !worker.commandPending &&
      _canOpenWorkerActions(current) &&
      worker.options!.improvements.any((option) => option.improvement == kind);
}

bool _sameWorkerStamp(SessionStampView left, SessionStampView right) =>
    left.revision == right.revision &&
    left.stateDigest == right.stateDigest &&
    left.mapHash == right.mapHash &&
    left.rulesetHash == right.rulesetHash;

bool _canConfirmImprovement(
  GameSessionReady current,
  FieldImprovementKind kind,
) =>
    _canPreviewImprovement(current, kind) &&
    current.interaction.worker?.previewedImprovement == kind;
