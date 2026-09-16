part of 'multiplayer_coordinator_test.dart';

void lobbyPresenceCases() {
  testWidgets('live roster updates and host start trigger one fresh resync', (
    tester,
  ) async {
    final session = _LiveSession()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    await tester.pump();
    expect(_waiting(coordinator).connection, LobbyConnectionPhase.connecting);
    session.latest.add(_lobbyView(ready: true));
    await tester.pump();
    expect(_waiting(coordinator).connection, LobbyConnectionPhase.connected);
    expect(_waiting(coordinator).lobby.canStart, isTrue);
    final resync = Completer<MultiplayerProjectionView>();
    session.resyncRequest = () => resync.future;
    session.latest.add(
      _lobbyView(phase: MultiplayerMatchPhase.running, ready: true),
    );
    await tester.pump();
    await session.latest.close();
    await tester.pump();
    expect(_waiting(coordinator).busy, isTrue);
    resync.complete(_projection());
    await tester.pump();
    expect(coordinator.state, isA<MultiplayerInMatch>());
    expect(session.resyncCount, 1);
    expect(session.cancelled, 1);
  });

  testWidgets('disconnect disables readiness and retries with authentication', (
    tester,
  ) async {
    final session = _LiveSession()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    await tester.pump();
    await coordinator.setReady(true);
    expect(_waiting(coordinator).lobby.currentParticipant.isReady, isFalse);
    session.latest.add(_lobbyView());
    await tester.pump();
    session.latest.addError(
      const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Offline',
        retryable: true,
      ),
    );
    await tester.pump();
    expect(_waiting(coordinator).connection, LobbyConnectionPhase.reconnecting);
    await coordinator.setReady(true);
    expect(_waiting(coordinator).lobby.currentParticipant.isReady, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(session.reconnectCount, 1);
    expect(session.watches, hasLength(2));
    session.latest.add(_lobbyView(ready: true));
    await tester.pump();
    expect(_waiting(coordinator).connection, LobbyConnectionPhase.connected);
    expect(_waiting(coordinator).failureCode, isNull);
  });

  testWidgets('hidden lobby cancels presence and ignores delayed resync', (
    tester,
  ) async {
    final session = _LiveSession()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    await tester.pump();
    final pending = Completer<MultiplayerProjectionView>();
    session.resyncRequest = () => pending.future;
    session.latest.add(
      _lobbyView(phase: MultiplayerMatchPhase.running, ready: true),
    );
    await tester.pump();
    coordinator.setLobbyVisible(false);
    pending.complete(_projection());
    await tester.pump();
    expect(coordinator.state, isA<MultiplayerWaitingRoom>());
    expect(session.cancelled, 1);
    coordinator.setLobbyVisible(true);
    await tester.pump();
    expect(session.watches, hasLength(2));
  });

  testWidgets('invalid recipient stops observation until explicit retry', (
    tester,
  ) async {
    final session = _LiveSession()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    await tester.pump();
    session.latest.add(_lobbyView(currentPlayerId: 'player-2'));
    await tester.pump();
    expect(_waiting(coordinator).connection, LobbyConnectionPhase.offline);
    expect(_waiting(coordinator).failureCode, 'invalid_match_lifecycle');
    await tester.pump(const Duration(minutes: 1));
    expect(session.watches, hasLength(1));
    await coordinator.refreshMatchLobby();
    await tester.pump();
    expect(session.watches, hasLength(2));
  });

  testWidgets('sign-out cancels a scheduled reconnect', (tester) async {
    final session = _LiveSession()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    await tester.pump();
    session.latest.addError(
      const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Offline',
        retryable: true,
      ),
    );
    await tester.pump();
    await coordinator.signOut();
    await tester.pump(const Duration(minutes: 1));
    expect(coordinator.state, isA<MultiplayerSignedOut>());
    expect(session.reconnectCount, 0);
    expect(session.watches, hasLength(1));
  });
}

MultiplayerWaitingRoom _waiting(MultiplayerCoordinator coordinator) =>
    coordinator.state as MultiplayerWaitingRoom;

final class _LiveSession extends _Session implements MultiplayerLobbyWatchPort {
  final watches = <StreamController<MultiplayerMatchLobbyView>>[];
  var cancelled = 0;
  Future<MultiplayerProjectionView> Function()? resyncRequest;
  StreamController<MultiplayerMatchLobbyView> get latest => watches.last;

  @override
  Stream<MultiplayerMatchLobbyView> watchLobby(String matchId) {
    expectSync(matchId, 'match-1');
    final controller = StreamController<MultiplayerMatchLobbyView>(
      onCancel: () => cancelled++,
    );
    watches.add(controller);
    return controller.stream;
  }

  @override
  Future<MultiplayerProjectionView> resync(String matchId) {
    if (resyncRequest case final request?) {
      resyncCount++;
      return request();
    }
    return super.resync(matchId);
  }
}
