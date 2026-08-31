part of 'worker_workflow.dart';

extension WorkerWorkflowLoading on WorkerWorkflow {
  Future<void> _load({
    required String unitId,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
    required WorkerDisposed isDisposed,
  }) async {
    final current = _selectedWorker(readState(), unitId);
    if (current == null) return;
    final revision = current.recipient.stamp.revision;
    try {
      final options = await _session.workerOptions(
        expectedRevision: revision,
        unitId: unitId,
      );
      if (isDisposed()) return;
      final ready = _selectedWorkerAtRevision(readState(), unitId, revision);
      if (ready == null) return;
      publish(
        ready.withInteraction(
          ready.interaction.copyWith(
            worker: WorkerState(unitId: unitId, options: options),
          ),
        ),
      );
    } on WorkerSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _selectedWorker(readState(), unitId);
      if (ready != null) publish(_loadFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_worker_failure', error, stackTrace);
      final ready = _selectedWorker(readState(), unitId);
      if (ready != null) publish(_unexpectedLoadFailure(ready));
    }
  }
}

GameSessionReady _loadFailure(
  GameSessionReady current,
  WorkerSessionException error,
) => current.withInteraction(
  current.interaction.copyWith(
    worker: WorkerState(
      unitId: current.interaction.selectedUnitId!,
      failure: WorkerFailureView(_failureCode(error.code)),
    ),
  ),
);

GameSessionReady _unexpectedLoadFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        worker: WorkerState(
          unitId: current.interaction.selectedUnitId!,
          failure: const WorkerFailureView(WorkerFailureCode.requestFailed),
        ),
      ),
    );
