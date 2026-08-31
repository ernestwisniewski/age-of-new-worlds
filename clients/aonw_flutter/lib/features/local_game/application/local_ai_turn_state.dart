enum LocalAiTurnPhase { idle, running, failed }

enum LocalAiTurnFailureViewCode {
  requestFailed,
  responseIncompatible,
  incomplete,
}

final class LocalAiTurnState {
  const LocalAiTurnState._({
    required this.phase,
    this.activePlayerId,
    this.failure,
  });

  const LocalAiTurnState.idle() : this._(phase: LocalAiTurnPhase.idle);

  const LocalAiTurnState.running(String playerId)
    : this._(phase: LocalAiTurnPhase.running, activePlayerId: playerId);

  const LocalAiTurnState.failed(LocalAiTurnFailureViewCode failure)
    : this._(phase: LocalAiTurnPhase.failed, failure: failure);

  final LocalAiTurnPhase phase;
  final String? activePlayerId;
  final LocalAiTurnFailureViewCode? failure;

  bool get inFlight => phase == LocalAiTurnPhase.running;

  bool get blocksGameplay => phase != LocalAiTurnPhase.idle;
}
