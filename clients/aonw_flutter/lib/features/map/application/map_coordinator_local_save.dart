part of 'map_coordinator.dart';

extension MapCoordinatorLocalSave on MapCoordinator {
  bool get canTransferLocalSaves => _saveWorkflow.canTransfer;

  Future<bool> hasLocalSave() => _saveWorkflow.hasSave();

  Future<List<LocalSaveSummaryView>> listLocalSaves() =>
      _saveWorkflow.listSaves();

  Future<LocalSaveTransferResultView> importLocalSave() =>
      _saveWorkflow.importSave();

  Future<LocalSaveTransferResultView> exportLocalSave(LocalSaveSlotView slot) =>
      _saveWorkflow.exportSave(slot);

  Future<LocalResumeResultView> resumeLocalGame(LocalSaveSlotView slot) =>
      _resumeLocalGame(() => _saveWorkflow.resume(slot));

  Future<LocalResumeResultView> resumeLatestLocalGame() =>
      _resumeLocalGame(_saveWorkflow.resumeLatest);

  Future<LocalResumeResultView> _resumeLocalGame(
    Future<LocalResumeAttemptView> Function() resume,
  ) async {
    if (_disposed) {
      return const LocalResumeResultView.failed(
        LocalResumeFailureViewCode.unavailable,
      );
    }
    final previous = _state;
    final generation = ++_loadGeneration;
    _interactionGeneration += 1;
    _setCursor(null);
    _setState(const GameSessionLoading());
    final attempt = await resume();
    if (!_isCurrent(generation)) {
      return const LocalResumeResultView.failed(
        LocalResumeFailureViewCode.unavailable,
      );
    }
    if (!attempt.started) {
      _setState(previous);
      return LocalResumeResultView.failed(attempt.failure!);
    }
    final ready = _restoredState(attempt);
    if (ready == null) {
      _setState(previous);
      return const LocalResumeResultView.failed(
        LocalResumeFailureViewCode.incompatible,
      );
    }
    _localGameEntry = attempt.entry;
    _localSaveSlot = attempt.slot;
    _localControlPlan = attempt.controlPlan;
    _setState(ready);
    return const LocalResumeResultView.started();
  }

  GameSessionReady? _restoredState(LocalResumeAttemptView attempt) {
    final ready = GameSessionReady.initial(attempt.scene!);
    final controlPlan = attempt.controlPlan!;
    if (!controlPlan.requiresPrivateHandoff) return ready;
    final actor = controlPlan.participant(ready.recipient.actorPlayerId);
    if (actor == null || actor.control != LocalPlayerControlView.human) {
      return null;
    }
    return ready.withLocalHandoff(
      LocalHandoffState.awaitingConfirmation(
        playerId: actor.id,
        playerName: actor.name,
      ),
    );
  }

  void saveLocalGame() => unawaited(_saveLocalGame());

  Future<void> _saveLocalGame() async {
    final current = _state;
    if (current is! GameSessionReady || _localFlowBusy(current)) return;
    final entry = _localGameEntry;
    if (entry == null) {
      _setState(
        current.withLocalSave(
          const LocalSaveState.failed(LocalSaveFailureViewCode.unavailable),
        ),
      );
      return;
    }
    final generation = _loadGeneration;
    _setState(current.withLocalSave(const LocalSaveState.saving()));
    final result = await _saveWorkflow.save(entry, slot: _localSaveSlot);
    if (!_isCurrent(generation)) return;
    if (result.saved) {
      _localSaveSlot = result.slot;
      await _captureReplay(entry);
      if (!_isCurrent(generation)) return;
    }
    final ready = _state;
    if (ready is GameSessionReady) {
      _setState(
        ready.withLocalSave(
          result.saved
              ? const LocalSaveState.saved()
              : LocalSaveState.failed(result.failure!),
        ),
      );
    }
  }

  bool _localFlowBusy(GameSessionReady current) =>
      current.localSave.inFlight ||
      current.localAiTurn.blocksGameplay ||
      current.localHandoff.blocksGameplay;

  Future<void> _captureReplay(LocalGameCatalogEntryView entry) async {
    try {
      await _replayCapture?.captureReplay(entry);
    } on Object catch (error, stackTrace) {
      _diagnosticReporter(
        'unexpected_replay_capture_failure',
        error,
        stackTrace,
      );
    }
  }
}
