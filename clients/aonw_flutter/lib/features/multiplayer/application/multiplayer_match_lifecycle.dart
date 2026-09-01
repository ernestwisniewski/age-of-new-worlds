part of 'multiplayer_coordinator.dart';

extension MultiplayerMatchLifecycle on MultiplayerCoordinator {
  Future<MultiplayerMatchLobbyView> _synchronizedLobby(
    MultiplayerInMatch current,
    MultiplayerProjectionView projection,
  ) async {
    final lobby = await _session.lobby(projection.matchId);
    _validateInMatchLobby(current, lobby, projection);
    return lobby;
  }

  Future<void> kickParticipant(String targetPlayerId) async {
    final current = _state;
    final target = targetPlayerId.trim();
    if (current is! MultiplayerInMatch ||
        current.phase != NetworkSessionPhase.ready ||
        current.commandPending ||
        !current.lobby.currentParticipant.isHost ||
        !_canKick(current, target)) {
      return;
    }
    final generation = _generation;
    final commandId = _commandId();
    _setState(current.copyWith(commandPending: true, clearFailure: true));
    try {
      await _applyKick(current, target, commandId, generation);
    } on Object catch (error, stackTrace) {
      _report('multiplayer_kick_failed', error, stackTrace);
      if (!_isCurrent(generation)) return;
      if (error case MultiplayerSessionException(retryable: true)) {
        await _recoverKick(current, target, commandId, generation);
        return;
      }
      _setState(
        current.copyWith(
          phase: NetworkSessionPhase.failed,
          commandPending: false,
          failureCode: _failureCode(error),
        ),
      );
    }
  }

  Future<void> _recoverKick(
    MultiplayerInMatch current,
    String targetPlayerId,
    String commandId,
    int generation,
  ) async {
    _setState(
      current.copyWith(
        phase: NetworkSessionPhase.reconnecting,
        commandPending: true,
        clearFailure: true,
      ),
    );
    try {
      await _session.reconnect();
      if (_isCurrent(generation)) {
        await _applyKick(current, targetPlayerId, commandId, generation);
      }
    } on Object catch (error, stackTrace) {
      _report('multiplayer_kick_reconnect_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          current.copyWith(
            phase: NetworkSessionPhase.failed,
            commandPending: false,
            failureCode: _failureCode(error),
          ),
        );
      }
    }
  }

  Future<void> _applyKick(
    MultiplayerInMatch current,
    String targetPlayerId,
    String commandId,
    int generation,
  ) async {
    final outcome = await _session.kickParticipant(
      matchId: current.projection.matchId,
      clientCommandId: commandId,
      expectedRevision: current.projection.revision,
      targetPlayerId: targetPlayerId,
    );
    MultiplayerCoordinator._validateCommand(
      current.projection,
      outcome,
      commandId,
    );
    final lobby = await _session.lobby(current.projection.matchId);
    _validatePostKick(current, lobby, outcome, targetPlayerId);
    if (_isCurrent(generation)) {
      _setState(
        current.copyWith(
          phase: NetworkSessionPhase.ready,
          projection: outcome.projection,
          lobby: lobby,
          commandPending: false,
          failureCode: outcome.rejectionCode,
          clearFailure: outcome.rejectionCode == null,
        ),
      );
    }
  }
}

bool _canKick(MultiplayerInMatch current, String targetPlayerId) => current
    .lobby
    .participants
    .where(
      (participant) =>
          participant.playerId == targetPlayerId &&
          participant.kind == 'human' &&
          participant.isClaimed &&
          !participant.isHost &&
          !participant.isCurrentUser,
    )
    .isNotEmpty;

void _validatePostKick(
  MultiplayerInMatch current,
  MultiplayerMatchLobbyView lobby,
  MultiplayerCommandView outcome,
  String targetPlayerId,
) {
  _validateInMatchLobby(current, lobby, outcome.projection);
  if (outcome.accepted &&
      lobby.participants.any(
        (participant) =>
            participant.playerId == targetPlayerId && participant.isClaimed,
      )) {
    throw const MultiplayerSessionException(
      code: 'invalid_match_lifecycle',
      message: 'The removed participant remained active.',
    );
  }
}

void _validateInMatchLobby(
  MultiplayerInMatch current,
  MultiplayerMatchLobbyView lobby,
  MultiplayerProjectionView projection,
) {
  _validateLobby(
    lobby,
    matchId: current.projection.matchId,
    playerId: current.projection.playerId,
  );
  if (lobby.match.phase == MultiplayerMatchPhase.lobby ||
      lobby.match.phase == MultiplayerMatchPhase.abandoned ||
      lobby.match.revision != projection.revision ||
      lobby.match.eventOffset != projection.eventOffset) {
    throw const MultiplayerSessionException(
      code: 'invalid_match_lifecycle',
      message: 'The match roster did not match the authoritative game.',
    );
  }
}
