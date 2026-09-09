part of 'map_coordinator.dart';

extension MapCoordinatorAutosave on MapCoordinator {
  Future<void> _completeLocalTurn(GameSessionReady afterActor) async {
    final generation = _loadGeneration;
    await _advanceLocalTurns(afterActor);
    if (!_isCurrent(generation)) return;
    await _autosaveLocalGame();
  }

  Future<void> _autosaveLocalGame() async {
    final current = _state;
    final entry = _localGameEntry;
    final plan = _localControlPlan;
    if (!_saveWorkflow.canAutosave ||
        entry == null ||
        plan == null ||
        current is! GameSessionReady ||
        !_autosaveReady(current)) {
      return;
    }
    final generation = _loadGeneration;
    _setState(current.withLocalSave(const LocalSaveState.saving()));
    final result = await _saveWorkflow.saveAutomatic(
      entry,
      privateHandoff: plan.requiresPrivateHandoff,
      turnMode: current.recipient.turnMode,
      isCurrent: () => _isCurrent(generation),
    );
    await _finishAutosave(result, entry, generation);
  }

  Future<void> _finishAutosave(
    LocalSaveWriteResultView result,
    LocalGameCatalogEntryView entry,
    int generation,
  ) async {
    if (!_isCurrent(generation)) return;
    if (result.saved) {
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

  bool _autosaveReady(GameSessionReady current) =>
      !current.localSave.inFlight &&
      !current.localAiTurn.blocksGameplay &&
      current.localHandoff.phase != LocalHandoffPhase.failed &&
      current.localHandoff.phase != LocalHandoffPhase.switching;
}
