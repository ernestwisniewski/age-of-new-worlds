part of 'map_coordinator.dart';

extension MapCoordinatorLocalTurns on MapCoordinator {
  Future<void> _advanceLocalTurns(GameSessionReady afterActor) async {
    final plan = _localControlPlan;
    final localGame = _capabilities.localGame;
    if (plan == null || localGame == null) return;
    final generation = _loadGeneration;
    final actorPlayerId = afterActor.recipient.actorPlayerId;
    var current = afterActor;
    for (final participant in plan.after(actorPlayerId)) {
      if (current.recipient.turnView.outcome.isTerminal) return;
      if (participant.control == LocalPlayerControlView.human) {
        await _continueWithHuman(
          current,
          participant,
          actorPlayerId,
          generation,
        );
        return;
      }
      final advanced = await _advanceAiParticipant(
        localGame,
        current,
        participant.id,
        actorPlayerId,
        generation,
      );
      if (advanced == null) return;
      current = advanced;
    }
  }

  Future<void> _continueWithHuman(
    GameSessionReady current,
    LocalParticipantControlView participant,
    String actorPlayerId,
    int generation,
  ) async {
    if (participant.id == actorPlayerId) {
      _setState(current.withLocalAiTurn(const LocalAiTurnState.idle()));
      return;
    }
    await _switchToLocalHuman(current, participant, generation);
  }

  Future<GameSessionReady?> _advanceAiParticipant(
    LocalGameSessionPort localGame,
    GameSessionReady current,
    String aiPlayerId,
    String humanPlayerId,
    int generation,
  ) async {
    _setState(current.withLocalAiTurn(LocalAiTurnState.running(aiPlayerId)));
    try {
      final execution = await localGame.advanceAiTurn(
        LocalAiTurnRequestView(
          aiPlayerId: aiPlayerId,
          humanPlayerId: humanPlayerId,
        ),
      );
      if (!_isCurrent(generation)) return null;
      await _presentAiFrames(execution, generation);
      if (!_isCurrent(generation)) return null;
      final ready = _state;
      if (ready is! GameSessionReady) return null;
      final advanced = ready.withRecipient(execution.player);
      if (!execution.completedTurn &&
          !execution.player.turnView.outcome.isTerminal) {
        _setState(
          advanced.withLocalAiTurn(
            const LocalAiTurnState.failed(
              LocalAiTurnFailureViewCode.incomplete,
            ),
          ),
        );
        return null;
      }
      final completed = advanced.withLocalAiTurn(const LocalAiTurnState.idle());
      _setState(completed);
      return completed;
    } on LocalGameSessionException catch (error, stackTrace) {
      _publishAiSessionFailure(error, stackTrace, generation);
      return null;
    } on Object catch (error, stackTrace) {
      _publishUnexpectedAiFailure(error, stackTrace, generation);
      return null;
    }
  }

  Future<void> _presentAiFrames(
    LocalAiTurnExecutionView execution,
    int generation,
  ) async {
    try {
      for (final frame in execution.frames) {
        if (!_isCurrent(generation)) return;
        final ready = _state;
        if (ready is! GameSessionReady) return;
        _setState(ready.withRecipient(frame.player, commandFrame: frame));
        await waitForCommandEffects?.call();
      }
    } finally {
      final ready = _state;
      if (_isCurrent(generation) && ready is GameSessionReady) {
        _setState(ready.withRecipient(execution.player));
      }
    }
  }

  void _publishAiSessionFailure(
    LocalGameSessionException error,
    StackTrace stackTrace,
    int generation,
  ) {
    if (!_isCurrent(generation)) return;
    _diagnosticReporter(
      error.code,
      error.diagnosticCause ?? error,
      error.diagnosticStackTrace ?? stackTrace,
    );
    final ready = _state;
    if (ready is! GameSessionReady) return;
    final synchronized = error.resyncedPlayer == null
        ? ready
        : ready.withRecipient(error.resyncedPlayer!);
    _setState(
      synchronized.withLocalAiTurn(
        LocalAiTurnState.failed(
          error.code == 'invalid_ai_turn_protocol'
              ? LocalAiTurnFailureViewCode.responseIncompatible
              : LocalAiTurnFailureViewCode.requestFailed,
        ),
      ),
    );
  }

  void _publishUnexpectedAiFailure(
    Object error,
    StackTrace stackTrace,
    int generation,
  ) {
    if (!_isCurrent(generation)) return;
    _diagnosticReporter('unexpected_ai_turn_failure', error, stackTrace);
    final ready = _state;
    if (ready is GameSessionReady) {
      _setState(
        ready.withLocalAiTurn(
          const LocalAiTurnState.failed(
            LocalAiTurnFailureViewCode.requestFailed,
          ),
        ),
      );
    }
  }

  Future<void> _switchToLocalHuman(
    GameSessionReady current,
    LocalParticipantControlView participant,
    int generation,
  ) async {
    final localGame = _capabilities.localGame;
    if (localGame == null) return;
    _setState(
      current
          .withLocalAiTurn(const LocalAiTurnState.idle())
          .withLocalHandoff(
            LocalHandoffState.switching(
              playerId: participant.id,
              playerName: participant.name,
            ),
          ),
    );
    try {
      final player = await localGame.handoffLocalActor(participant.id);
      if (!_isCurrent(generation)) return;
      final ready = _state;
      if (ready is! GameSessionReady) return;
      _interactionGeneration += 1;
      _setCursor(null);
      _setState(
        ready
            .withRecipient(player)
            .withInteraction(const MapInteractionState())
            .withLocalHandoff(
              LocalHandoffState.awaitingConfirmation(
                playerId: participant.id,
                playerName: participant.name,
              ),
            ),
      );
    } on Object catch (error, stackTrace) {
      if (!_isCurrent(generation)) return;
      _diagnosticReporter('local_handoff_failed', error, stackTrace);
      final ready = _state;
      if (ready is GameSessionReady) {
        _setState(
          ready.withLocalHandoff(
            LocalHandoffState.failed(
              playerId: participant.id,
              playerName: participant.name,
            ),
          ),
        );
      }
    }
  }

  void confirmLocalHandoff() {
    final current = _state;
    if (current is! GameSessionReady ||
        current.localHandoff.phase != LocalHandoffPhase.awaitingConfirmation) {
      return;
    }
    _setState(current.withLocalHandoff(const LocalHandoffState.idle()));
  }

  void retryLocalHandoff() {
    final current = _state;
    final handoff = current is GameSessionReady ? current.localHandoff : null;
    if (current is! GameSessionReady ||
        handoff?.phase != LocalHandoffPhase.failed) {
      return;
    }
    final participant = _localControlPlan?.participant(handoff!.playerId!);
    if (participant != null) {
      unawaited(_switchToLocalHuman(current, participant, _loadGeneration));
    }
  }
}
