part of 'multiplayer_coordinator.dart';

void _validateLobby(
  MultiplayerMatchLobbyView lobby, {
  required String matchId,
  String? playerId,
  bool requireWaiting = false,
}) {
  if (lobby.match.matchId != matchId ||
      (playerId != null && lobby.currentParticipant.playerId != playerId) ||
      (requireWaiting && lobby.match.phase != MultiplayerMatchPhase.lobby)) {
    throw const MultiplayerSessionException(
      code: 'invalid_match_lifecycle',
      message: 'The authoritative lobby changed match identity or phase.',
    );
  }
}

extension MultiplayerLobbyLifecycle on MultiplayerCoordinator {
  Future<void> createMatch([
    MultiplayerMatchSetupView setup = MultiplayerMatchSetupView.defaults,
  ]) async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final documents = await _documents.load(setup);
      final lobby = await _session.createMatch(documents);
      _validateLobby(
        lobby,
        matchId: lobby.match.matchId,
        playerId: documents.creatorPlayerId,
        requireWaiting: true,
      );
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerWaitingRoom(account: current.account, lobby: lobby),
        );
      }
    } on Object catch (error, stackTrace) {
      _waitingFailure(
        current,
        generation,
        'multiplayer_match_create_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> joinMatch({required String matchId, required String playerId}) =>
      _joinMatch(matchId.trim(), playerId.trim());

  Future<void> _joinMatch(String matchId, String playerId) async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final lobby = await _session.joinMatch(
        matchId: matchId,
        playerId: playerId,
      );
      _validateLobby(lobby, matchId: matchId, playerId: playerId);
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerWaitingRoom(account: current.account, lobby: lobby),
        );
      }
    } on Object catch (error, stackTrace) {
      _waitingFailure(
        current,
        generation,
        'multiplayer_match_join_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> openMatch(MultiplayerMatchView match) async {
    final current = _state;
    if (current is! MultiplayerLobby || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      if (match.phase == MultiplayerMatchPhase.lobby) {
        await _openWaitingMatch(current, match.matchId, generation);
      } else {
        await _resyncListedMatch(current, match.matchId, generation);
      }
    } on Object catch (error, stackTrace) {
      _waitingFailure(
        current,
        generation,
        'multiplayer_match_open_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> refreshMatchLobby() async {
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final lobby = await _session.lobby(current.lobby.match.matchId);
      _validateSameParticipant(current, lobby);
      if (!_isCurrent(generation)) return;
      if (lobby.match.phase == MultiplayerMatchPhase.lobby) {
        _setState(current.copyWith(lobby: lobby, busy: false));
        return;
      }
      await _openStartedMatch(current.account, lobby, generation);
    } on Object catch (error, stackTrace) {
      _waitingRoomFailure(
        current,
        generation,
        'multiplayer_match_lobby_refresh_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> setReady(bool ready) async {
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final lobby = await _session.setReady(
        matchId: current.lobby.match.matchId,
        ready: ready,
      );
      _validateSameParticipant(current, lobby, requireWaiting: true);
      if (_isCurrent(generation)) {
        _setState(current.copyWith(lobby: lobby, busy: false));
      }
    } on Object catch (error, stackTrace) {
      _waitingRoomFailure(
        current,
        generation,
        'multiplayer_match_ready_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> startMatch() async {
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    final generation = _generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final lobby = await _session.startMatch(current.lobby.match.matchId);
      _validateSameParticipant(current, lobby);
      _requireRunning(lobby);
      await _openStartedMatch(current.account, lobby, generation);
    } on Object catch (error, stackTrace) {
      _waitingRoomFailure(
        current,
        generation,
        'multiplayer_match_start_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> closeWaitingRoom() async {
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    final generation = ++_generation;
    try {
      await _openLobby(current.account, generation);
    } on Object catch (error, stackTrace) {
      _report('multiplayer_lobby_open_failed', error, stackTrace);
      if (_isCurrent(generation)) {
        _setState(
          MultiplayerLobby(
            account: current.account,
            matches: const [],
            failureCode: _failureCode(error),
          ),
        );
      }
    }
  }

  Future<void> leaveWaitingRoom() async {
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    final generation = ++_generation;
    _setState(current.copyWith(busy: true, clearFailure: true));
    try {
      final match = await _session.leaveLobby(current.lobby.match.matchId);
      if (match.matchId != current.lobby.match.matchId) {
        throw const MultiplayerSessionException(
          code: 'invalid_match_lifecycle',
          message: 'The leave response belongs to another match.',
        );
      }
      await _openLobby(current.account, generation);
    } on Object catch (error, stackTrace) {
      _waitingRoomFailure(
        current,
        generation,
        'multiplayer_match_leave_failed',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _openWaitingMatch(
    MultiplayerLobby current,
    String matchId,
    int generation,
  ) async {
    final lobby = await _session.lobby(matchId);
    _validateLobby(lobby, matchId: matchId);
    if (_isCurrent(generation)) {
      _setState(MultiplayerWaitingRoom(account: current.account, lobby: lobby));
    }
  }

  Future<void> _resyncListedMatch(
    MultiplayerLobby current,
    String matchId,
    int generation,
  ) async {
    final lobby = await _session.lobby(matchId);
    _validateLobby(lobby, matchId: matchId);
    final projection = await _session.resync(matchId);
    _validateStartedProjection(lobby, projection);
    if (_isCurrent(generation)) {
      _setState(
        MultiplayerInMatch(
          account: current.account,
          phase: NetworkSessionPhase.ready,
          projection: projection,
          lobby: lobby,
        ),
      );
    }
  }

  Future<void> _openStartedMatch(
    MultiplayerAccountView account,
    MultiplayerMatchLobbyView lobby,
    int generation,
  ) async {
    final projection = await _session.resync(lobby.match.matchId);
    _validateStartedProjection(lobby, projection);
    if (_isCurrent(generation)) {
      _setState(
        MultiplayerInMatch(
          account: account,
          phase: NetworkSessionPhase.ready,
          projection: projection,
          lobby: lobby,
        ),
      );
    }
  }

  void _waitingFailure(
    MultiplayerLobby current,
    int generation,
    String diagnosticCode,
    Object error,
    StackTrace stackTrace,
  ) {
    _report(diagnosticCode, error, stackTrace);
    if (_isCurrent(generation)) {
      _setState(
        current.copyWith(busy: false, failureCode: _failureCode(error)),
      );
    }
  }

  void _waitingRoomFailure(
    MultiplayerWaitingRoom current,
    int generation,
    String diagnosticCode,
    Object error,
    StackTrace stackTrace,
  ) {
    _report(diagnosticCode, error, stackTrace);
    if (_isCurrent(generation)) {
      _setState(
        current.copyWith(busy: false, failureCode: _failureCode(error)),
      );
    }
  }
}

void _validateSameParticipant(
  MultiplayerWaitingRoom current,
  MultiplayerMatchLobbyView lobby, {
  bool requireWaiting = false,
}) => _validateLobby(
  lobby,
  matchId: current.lobby.match.matchId,
  playerId: current.lobby.currentParticipant.playerId,
  requireWaiting: requireWaiting,
);

void _requireRunning(MultiplayerMatchLobbyView lobby) {
  if (lobby.match.phase == MultiplayerMatchPhase.running) return;
  throw const MultiplayerSessionException(
    code: 'invalid_match_lifecycle',
    message: 'The authoritative match did not enter the running phase.',
  );
}

void _validateStartedProjection(
  MultiplayerMatchLobbyView lobby,
  MultiplayerProjectionView projection,
) {
  if (projection.matchId == lobby.match.matchId &&
      projection.playerId == lobby.currentParticipant.playerId) {
    return;
  }
  throw const MultiplayerSessionException(
    code: 'invalid_resync_sequence',
    message: 'The started match projection belongs to another participant.',
  );
}
