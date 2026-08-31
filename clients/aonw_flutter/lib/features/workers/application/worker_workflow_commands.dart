part of 'worker_workflow.dart';

extension WorkerWorkflowCommands on WorkerWorkflow {
  Future<void> _execute({
    required WorkerActionView action,
    required WorkerStateReader readState,
    required WorkerStatePublisher publish,
    required WorkerDisposed isDisposed,
  }) async {
    final current = _executableWorker(readState(), action);
    if (current == null) return;
    final correlationId = ++_correlationId;
    publish(_pendingWorker(current, action, correlationId));
    try {
      final result = await _session.executeWorkerAction(
        expectedRevision: current.recipient.stamp.revision,
        action: action,
      );
      if (isDisposed()) return;
      final ready = _correlatedWorker(
        readState(),
        action.unitId,
        correlationId,
      );
      if (ready == null) return;
      if (!result.accepted) {
        publish(_rejectedWorker(ready, result.rejectionCode!));
        return;
      }
      publish(
        _acceptedWorker(
          ready,
          result.player!,
          action.unitId,
          result.automation,
        ),
      );
      load(
        unitId: action.unitId,
        readState: readState,
        publish: publish,
        isDisposed: isDisposed,
      );
    } on WorkerSessionException catch (error, stackTrace) {
      if (isDisposed()) return;
      _report(error, stackTrace);
      final ready = _correlatedWorker(
        readState(),
        action.unitId,
        correlationId,
      );
      if (ready != null) publish(_commandFailure(ready, error));
    } on Object catch (error, stackTrace) {
      if (isDisposed()) return;
      _diagnosticReporter('unexpected_worker_failure', error, stackTrace);
      final ready = _correlatedWorker(
        readState(),
        action.unitId,
        correlationId,
      );
      if (ready != null) publish(_unexpectedCommandFailure(ready));
    }
  }
}

GameSessionReady _pendingWorker(
  GameSessionReady current,
  WorkerActionView action,
  int correlationId,
) => current.withInteraction(
  current.interaction.copyWith(
    clearReachable: true,
    clearRoute: true,
    worker: current.interaction.worker!.copyWith(
      correlationId: correlationId,
      inFlightAction: action,
      clearFailure: true,
    ),
  ),
);

GameSessionReady _rejectedWorker(
  GameSessionReady current,
  WorkerRejectionCodeView code,
) => current.withInteraction(
  current.interaction.copyWith(
    worker: current.interaction.worker!.copyWith(
      clearInFlightAction: true,
      failure: WorkerFailureView.rejected(code),
    ),
  ),
);

GameSessionReady _acceptedWorker(
  GameSessionReady current,
  PlayerMapView player,
  String unitId,
  WorkerAutomationExecutionView? automation,
) {
  final synchronized = current.withRecipient(player);
  final worker = synchronized.recipient.controlledUnitById(unitId);
  if (worker == null) {
    return synchronized.withInteraction(_clearWorkerSelection(synchronized));
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      selected: worker.coordinate,
      worker: WorkerState(
        unitId: unitId,
        loading: true,
        lastAutomation: automation,
      ),
      actionDeck: synchronized.interaction.actionDeck?.copyWith(
        clearFailure: true,
      ),
    ),
  );
}

GameSessionReady _commandFailure(
  GameSessionReady current,
  WorkerSessionException error,
) {
  final player = error.resyncedPlayer;
  final synchronized = player == null ? current : current.withRecipient(player);
  final worker = synchronized.interaction.worker!;
  if (player != null &&
      synchronized.recipient.controlledUnitById(worker.unitId) == null) {
    return synchronized.withInteraction(_clearWorkerSelection(synchronized));
  }
  return synchronized.withInteraction(
    synchronized.interaction.copyWith(
      worker: worker.copyWith(
        clearInFlightAction: true,
        failure: WorkerFailureView(_failureCode(error.code)),
      ),
    ),
  );
}

GameSessionReady _unexpectedCommandFailure(GameSessionReady current) =>
    current.withInteraction(
      current.interaction.copyWith(
        worker: current.interaction.worker!.copyWith(
          clearInFlightAction: true,
          failure: const WorkerFailureView(WorkerFailureCode.requestFailed),
        ),
      ),
    );
