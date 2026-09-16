part of 'multiplayer_coordinator.dart';

extension MultiplayerLobbyPresence on MultiplayerCoordinator {
  void setLobbyVisible(bool visible) {
    if (_closed || _lobbyVisible == visible) return;
    _lobbyVisible = visible;
    final current = _state;
    _setState(
      !visible && _lobbyOpening && current is MultiplayerWaitingRoom
          ? current.copyWith(busy: false)
          : current,
    );
  }

  void retryLobbyConnection() {
    if (_closed || _state is! MultiplayerWaitingRoom) return;
    _stopLobbyObservation();
    _setState(_state);
  }

  void _syncLobbyObservation(MultiplayerState state) {
    if (!_lobbyVisible ||
        state is! MultiplayerWaitingRoom ||
        _session is! MultiplayerLobbyWatchPort) {
      _stopLobbyObservation();
      return;
    }
    final scope = (
      state.account.userId,
      state.lobby.match.matchId,
      state.lobby.currentParticipant.playerId,
      _generation,
    );
    if (_lobbyScope == scope) return;
    _stopLobbyObservation();
    if (state.busy) return;
    _lobbyScope = scope;
    _lobbyConnection = LobbyConnectionPhase.connecting;
    final epoch = _lobbyEpoch;
    scheduleMicrotask(() => _observeLobby(epoch, refreshAuthentication: false));
  }

  void _stopLobbyObservation() {
    ++_lobbyEpoch;
    _lobbyScope = null;
    _lobbyRetry?.cancel();
    _lobbyRetry = null;
    _lobbyRetryCount = 0;
    _lobbyOpening = false;
    _lobbyConnection = LobbyConnectionPhase.offline;
    _cancelLobbySubscription();
  }

  void _cancelLobbySubscription() {
    final subscription = _lobbySubscription;
    _lobbySubscription = null;
    if (subscription == null) return;
    unawaited(
      subscription.cancel().catchError((Object error, StackTrace stack) {
        _report('multiplayer_lobby_cancel_failed', error, stack);
      }),
    );
  }

  bool _observingLobby(int epoch, [int? attempt]) =>
      !_closed &&
      _lobbyVisible &&
      _lobbyScope != null &&
      _lobbyScope!.$4 == _generation &&
      _lobbyEpoch == epoch &&
      (attempt == null || attempt == _lobbyAttempt);

  Future<void> _observeLobby(
    int epoch, {
    required bool refreshAuthentication,
  }) async {
    if (!_observingLobby(epoch)) return;
    final attempt = ++_lobbyAttempt;
    try {
      if (refreshAuthentication) await _session.reconnect();
      if (!_observingLobby(epoch, attempt)) return;
      final port = _session as MultiplayerLobbyWatchPort;
      _lobbySubscription = port
          .watchLobby(_lobbyScope!.$2)
          .listen(
            (lobby) => unawaited(_receiveObservedLobby(lobby, epoch, attempt)),
            onError: (Object error, StackTrace stack) =>
                _lobbyObservationFailed(error, stack, epoch, attempt),
            onDone: () {
              if (_lobbyOpening) return;
              _lobbyObservationFailed(
                const MultiplayerSessionException(
                  code: 'connection_interrupted',
                  message: 'The lobby connection closed.',
                  retryable: true,
                ),
                StackTrace.current,
                epoch,
                attempt,
              );
            },
            cancelOnError: true,
          );
    } on Object catch (error, stack) {
      _lobbyObservationFailed(error, stack, epoch, attempt);
    }
  }

  Future<void> _receiveObservedLobby(
    MultiplayerMatchLobbyView lobby,
    int epoch,
    int attempt,
  ) async {
    if (!_observingLobby(epoch, attempt)) return;
    final current = _state;
    if (current is! MultiplayerWaitingRoom || current.busy) return;
    try {
      _validateSameParticipant(current, lobby);
      _lobbyRetryCount = 0;
      _lobbyConnection = LobbyConnectionPhase.connected;
      if (lobby.match.phase == MultiplayerMatchPhase.lobby) {
        _setState(current.copyWith(lobby: lobby, clearFailure: true));
        return;
      }
      _requireRunning(lobby);
      _lobbyOpening = true;
      _setState(current.copyWith(lobby: lobby, busy: true, clearFailure: true));
      final projection = await _session.resync(lobby.match.matchId);
      _validateStartedProjection(lobby, projection);
      if (!_observingLobby(epoch)) return;
      _setState(
        MultiplayerInMatch(
          account: current.account,
          phase: NetworkSessionPhase.ready,
          projection: projection,
          lobby: lobby,
        ),
      );
    } on Object catch (error, stack) {
      _lobbyObservationFailed(error, stack, epoch, attempt);
    }
  }

  void _lobbyObservationFailed(
    Object error,
    StackTrace stack,
    int epoch,
    int attempt,
  ) {
    if (!_observingLobby(epoch, attempt)) return;
    final current = _state;
    if (current is! MultiplayerWaitingRoom) return;
    _report('multiplayer_lobby_observation_failed', error, stack);
    _cancelLobbySubscription();
    final retryable = error is MultiplayerSessionException && error.retryable;
    _lobbyConnection = retryable
        ? LobbyConnectionPhase.reconnecting
        : LobbyConnectionPhase.offline;
    final busy = _lobbyOpening ? false : current.busy;
    _lobbyOpening = false;
    _setState(current.copyWith(busy: busy, failureCode: _failureCode(error)));
    if (!retryable || _lobbyRetry?.isActive == true) return;
    final seconds = min(30, 2 << min(_lobbyRetryCount++, 4));
    _lobbyRetry = Timer(Duration(seconds: seconds), () {
      _lobbyRetry = null;
      unawaited(_observeLobby(epoch, refreshAuthentication: true));
    });
  }
}
