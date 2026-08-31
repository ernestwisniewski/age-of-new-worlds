enum LocalHandoffPhase { idle, switching, awaitingConfirmation, failed }

final class LocalHandoffState {
  const LocalHandoffState._({
    required this.phase,
    this.playerId,
    this.playerName,
  });

  const LocalHandoffState.idle() : this._(phase: LocalHandoffPhase.idle);

  const LocalHandoffState.switching({
    required String playerId,
    required String playerName,
  }) : this._(
         phase: LocalHandoffPhase.switching,
         playerId: playerId,
         playerName: playerName,
       );

  const LocalHandoffState.awaitingConfirmation({
    required String playerId,
    required String playerName,
  }) : this._(
         phase: LocalHandoffPhase.awaitingConfirmation,
         playerId: playerId,
         playerName: playerName,
       );

  const LocalHandoffState.failed({
    required String playerId,
    required String playerName,
  }) : this._(
         phase: LocalHandoffPhase.failed,
         playerId: playerId,
         playerName: playerName,
       );

  final LocalHandoffPhase phase;
  final String? playerId;
  final String? playerName;

  bool get blocksGameplay => phase != LocalHandoffPhase.idle;
}
