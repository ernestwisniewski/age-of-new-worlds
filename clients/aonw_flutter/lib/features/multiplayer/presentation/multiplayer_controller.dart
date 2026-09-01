import 'dart:async';

import 'package:flutter/foundation.dart';

import '../application/multiplayer_coordinator.dart';
import '../application/multiplayer_state.dart';
import '../read_model/multiplayer_view.dart';

final class MultiplayerController extends ChangeNotifier {
  MultiplayerController(this._coordinator) {
    _subscription = _coordinator.changes.listen((_) => notifyListeners());
  }

  final MultiplayerCoordinator _coordinator;
  late final StreamSubscription<MultiplayerState> _subscription;
  var _disposed = false;

  MultiplayerState get state => _coordinator.state;

  Future<void> initialize() => _coordinator.initialize();

  Future<void> signIn({required String email, required String password}) =>
      _coordinator.signIn(email: email, password: password);

  Future<void> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => _coordinator.createAccount(
    email: email,
    password: password,
    displayName: displayName,
  );

  Future<void> signOut() => _coordinator.signOut();

  Future<void> refreshLobby() => _coordinator.refreshLobby();

  Future<void> createMatch() => _coordinator.createMatch();

  Future<void> joinMatch({required String matchId, required String playerId}) =>
      _coordinator.joinMatch(matchId: matchId, playerId: playerId);

  Future<void> openMatch(MultiplayerMatchView match) =>
      _coordinator.openMatch(match);

  Future<void> refreshMatchLobby() => _coordinator.refreshMatchLobby();

  Future<void> setReady(bool ready) => _coordinator.setReady(ready);

  Future<void> startMatch() => _coordinator.startMatch();

  Future<void> closeWaitingRoom() => _coordinator.closeWaitingRoom();

  Future<void> leaveWaitingRoom() => _coordinator.leaveWaitingRoom();

  Future<void> submitTurn() => _coordinator.submitTurn();

  Future<void> kickParticipant(String targetPlayerId) =>
      _coordinator.kickParticipant(targetPlayerId);

  Future<void> reconnect() => _coordinator.reconnect();

  Future<void> leaveMatch() => _coordinator.leaveMatch();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(_coordinator.close());
    super.dispose();
  }
}
