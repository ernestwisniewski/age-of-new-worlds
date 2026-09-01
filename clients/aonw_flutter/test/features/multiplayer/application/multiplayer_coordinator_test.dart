import 'dart:math';

import 'package:aonw_flutter/features/multiplayer/application/multiplayer_coordinator.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_state.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores an authenticated account into its match lobby', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);

    await coordinator.initialize();

    final state = coordinator.state as MultiplayerLobby;
    expect(state.account.userId, _account.userId);
    expect(state.matches.single.matchId, 'match-1');
  });

  test('enters the map only after ready, start, and fresh resync', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();

    await coordinator.createMatch();
    var waiting = coordinator.state as MultiplayerWaitingRoom;
    expect(waiting.lobby.match.phase, MultiplayerMatchPhase.lobby);
    expect(waiting.lobby.canStart, isFalse);
    expect(session.resyncCount, 0);

    await coordinator.setReady(true);
    waiting = coordinator.state as MultiplayerWaitingRoom;
    expect(waiting.lobby.currentParticipant.isReady, isTrue);
    expect(waiting.lobby.canStart, isTrue);

    await coordinator.startMatch();
    final started = coordinator.state as MultiplayerInMatch;
    expect(started.projection.matchId, 'match-1');
    expect(session.resyncCount, 1);
  });

  test('refresh enters a match started by the host', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();
    session.lobbyView = _lobbyView(
      phase: MultiplayerMatchPhase.running,
      ready: true,
    );

    await coordinator.refreshMatchLobby();

    final started = coordinator.state as MultiplayerInMatch;
    expect(started.projection.playerId, 'player-1');
    expect(session.resyncCount, 1);
  });

  test('leaves a waiting room and removes it from joined matches', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.createMatch();

    await coordinator.leaveWaitingRoom();

    final lobby = coordinator.state as MultiplayerLobby;
    expect(lobby.matches, isEmpty);
    expect(session.leaveLobbyCount, 1);
  });

  test(
    'keeps one command identity across reconnect and durable retry',
    () async {
      final session = _Session()
        ..restored = _account
        ..submitFailures = 1;
      final coordinator = _coordinator(session);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      await coordinator.openMatch(session.matches.single);

      await coordinator.submitTurn();

      final state = coordinator.state as MultiplayerInMatch;
      expect(state.phase, NetworkSessionPhase.ready);
      expect(state.projection.revision, 8);
      expect(state.projection.eventOffset, 11);
      expect(session.reconnectCount, 1);
      expect(session.resyncCount, 2);
      expect(session.commandIds, hasLength(2));
      expect(session.commandIds.toSet(), hasLength(1));
    },
  );

  test(
    'host kick keeps one identity and refreshes the active roster',
    () async {
      final session = _Session()
        ..restored = _account
        ..kickFailures = 1
        ..lobbyView = _lobbyView(
          phase: MultiplayerMatchPhase.running,
          ready: true,
          guestKind: 'human',
          guestClaimed: true,
        );
      final coordinator = _coordinator(session);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      await coordinator.openMatch(session.matches.single);

      await coordinator.kickParticipant('player-2');

      final state = coordinator.state as MultiplayerInMatch;
      expect(state.phase, NetworkSessionPhase.ready);
      expect(state.projection.revision, 8);
      expect(state.projection.eventOffset, 11);
      expect(
        state.lobby.participants
            .singleWhere((participant) => participant.playerId == 'player-2')
            .isClaimed,
        isFalse,
      );
      expect(session.reconnectCount, 1);
      expect(session.kickCommandIds, hasLength(2));
      expect(session.kickCommandIds.toSet(), hasLength(1));
    },
  );

  test('fails closed when a command skips a revision', () async {
    final session = _Session()
      ..restored = _account
      ..commandRevisionIncrement = 2;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.openMatch(session.matches.single);

    await coordinator.submitTurn();

    final state = coordinator.state as MultiplayerInMatch;
    expect(state.phase, NetworkSessionPhase.failed);
    expect(state.failureCode, 'invalid_command_sequence');
  });

  test(
    'rejects a reconnect resync that moves durable state backwards',
    () async {
      final session = _Session()..restored = _account;
      final coordinator = _coordinator(session);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      await coordinator.openMatch(session.matches.single);
      session.projection = _projection(revision: 6, eventOffset: 9);

      await coordinator.reconnect();

      final state = coordinator.state as MultiplayerInMatch;
      expect(state.phase, NetworkSessionPhase.failed);
      expect(state.failureCode, 'invalid_resync_sequence');
    },
  );

  test('returns to a recoverable lobby when leaving cannot refresh', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    await coordinator.openMatch(session.matches.single);
    session.listFailure = const MultiplayerSessionException(
      code: 'connection_interrupted',
      message: 'Connection interrupted.',
      retryable: true,
    );

    await coordinator.leaveMatch();

    final state = coordinator.state as MultiplayerLobby;
    expect(state.matches, isEmpty);
    expect(state.failureCode, 'connection_interrupted');
  });
}

MultiplayerCoordinator _coordinator(_Session session) => MultiplayerCoordinator(
  session: session,
  documents: const _Documents(),
  secureRandom: Random(7),
);

const _account = MultiplayerAccountView(userId: 'account-1');

MultiplayerProjectionView _projection({
  int revision = 7,
  int eventOffset = 10,
  bool submitted = false,
}) => MultiplayerProjectionView(
  matchId: 'match-1',
  playerId: 'player-1',
  revision: revision,
  stateDigest: 'digest-$revision',
  eventOffset: eventOffset,
  turn: 1,
  ownTurnState: MultiplayerTurnStateView.active,
  ownSubmitted: submitted,
  requiredSubmissionCount: 2,
  submittedCount: submitted ? 1 : 0,
  visibleUnitCount: 1,
  outcomeCondition: 'ongoing',
  winnerPlayerId: null,
);

final class _Session implements MultiplayerSessionPort {
  MultiplayerAccountView? restored;
  var projection = _projection();
  var submitFailures = 0;
  var kickFailures = 0;
  var commandRevisionIncrement = 1;
  var reconnectCount = 0;
  var resyncCount = 0;
  var leaveLobbyCount = 0;
  var leftLobby = false;
  Object? listFailure;
  final commandIds = <String>[];
  final kickCommandIds = <String>[];
  List<MultiplayerMatchView> get matches => [
    MultiplayerMatchView(
      matchId: 'match-1',
      mapId: 'map-1',
      mapHash: 'map-hash',
      rulesetId: 'ruleset-1',
      rulesetHash: 'ruleset-hash',
      phase: MultiplayerMatchPhase.running,
      hostPlayerId: 'player-1',
      startedAt: DateTime.utc(2026),
      revision: 7,
      eventOffset: 10,
    ),
  ];
  var lobbyView = _lobbyView(phase: MultiplayerMatchPhase.running, ready: true);

  @override
  Future<MultiplayerAccountView?> restoreAccount() async => restored;

  @override
  Future<MultiplayerAccountView> signIn({
    required String email,
    required String password,
  }) async => _account;

  @override
  Future<MultiplayerAccountView> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> reconnect() async {
    reconnectCount += 1;
  }

  @override
  Future<List<MultiplayerMatchView>> listMatches() async {
    if (listFailure case final error?) throw error;
    return leftLobby ? const [] : matches;
  }

  @override
  Future<MultiplayerMatchLobbyView> createMatch(
    MultiplayerMatchDocuments documents,
  ) async => lobbyView = _lobbyView();

  @override
  Future<MultiplayerMatchLobbyView> joinMatch({
    required String matchId,
    required String playerId,
  }) async => _lobbyView(currentPlayerId: playerId);

  @override
  Future<MultiplayerMatchLobbyView> lobby(String matchId) async => lobbyView;

  @override
  Future<MultiplayerMatchLobbyView> setReady({
    required String matchId,
    required bool ready,
  }) async {
    lobbyView = _lobbyView(ready: ready);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchLobbyView> startMatch(String matchId) async {
    lobbyView = _lobbyView(phase: MultiplayerMatchPhase.running, ready: true);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchView> leaveLobby(String matchId) async {
    leaveLobbyCount += 1;
    leftLobby = true;
    return lobbyView.match;
  }

  @override
  Future<MultiplayerProjectionView> resync(String matchId) async {
    resyncCount += 1;
    return projection;
  }

  @override
  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) async {
    commandIds.add(clientCommandId);
    if (submitFailures > 0) {
      submitFailures -= 1;
      throw const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Connection interrupted.',
        retryable: true,
      );
    }
    projection = _projection(
      revision: expectedRevision + commandRevisionIncrement,
      eventOffset: 11,
      submitted: true,
    );
    lobbyView = _lobbyView(
      phase: MultiplayerMatchPhase.running,
      ready: true,
      revision: projection.revision,
      eventOffset: projection.eventOffset,
    );
    return MultiplayerCommandView(
      clientCommandId: clientCommandId,
      initialEventOffset: 10,
      finalEventOffset: 11,
      duplicate: commandIds.length > 1,
      accepted: true,
      rejectionCode: null,
      projection: projection,
    );
  }

  @override
  Future<MultiplayerCommandView> kickParticipant({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  }) async {
    kickCommandIds.add(clientCommandId);
    if (kickFailures > 0) {
      kickFailures -= 1;
      throw const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Connection interrupted.',
        retryable: true,
      );
    }
    projection = _projection(revision: expectedRevision + 1, eventOffset: 11);
    lobbyView = _lobbyView(
      phase: MultiplayerMatchPhase.running,
      ready: true,
      revision: projection.revision,
      eventOffset: projection.eventOffset,
      guestKind: 'human',
      guestClaimed: false,
    );
    return MultiplayerCommandView(
      clientCommandId: clientCommandId,
      initialEventOffset: 10,
      finalEventOffset: 11,
      duplicate: kickCommandIds.length > 1,
      accepted: true,
      rejectionCode: null,
      projection: projection,
    );
  }

  @override
  Future<void> close() async {}
}

MultiplayerMatchLobbyView _lobbyView({
  MultiplayerMatchPhase phase = MultiplayerMatchPhase.lobby,
  bool ready = false,
  String currentPlayerId = 'player-1',
  int revision = 7,
  int eventOffset = 10,
  String guestKind = 'ai',
  bool guestClaimed = false,
}) => MultiplayerMatchLobbyView(
  match: MultiplayerMatchView(
    matchId: 'match-1',
    mapId: 'map-1',
    mapHash: 'map-hash',
    rulesetId: 'ruleset-1',
    rulesetHash: 'ruleset-hash',
    phase: phase,
    hostPlayerId: 'player-1',
    startedAt: phase == MultiplayerMatchPhase.lobby ? null : DateTime.utc(2026),
    revision: revision,
    eventOffset: eventOffset,
  ),
  participants: [
    MultiplayerLobbyParticipantView(
      playerId: 'player-1',
      name: 'Player one',
      kind: 'human',
      isHost: true,
      isClaimed: true,
      isReady: ready,
      isCurrentUser: currentPlayerId == 'player-1',
    ),
    MultiplayerLobbyParticipantView(
      playerId: 'player-2',
      name: guestKind == 'ai' ? 'Computer' : 'Player two',
      kind: guestKind,
      isHost: false,
      isClaimed: guestClaimed,
      isReady: true,
      isCurrentUser: currentPlayerId == 'player-2',
    ),
  ],
  canStart:
      phase == MultiplayerMatchPhase.lobby &&
      currentPlayerId == 'player-1' &&
      ready,
);

final class _Documents implements MultiplayerMatchDocumentSource {
  const _Documents();

  @override
  Future<MultiplayerMatchDocuments> load() async =>
      const MultiplayerMatchDocuments(
        mapId: 'map-1',
        mapDocument: '{}',
        scenarioDocument: '{}',
        rulesetId: 'ruleset-1',
        matchIdentityDocument: '{}',
        fogEnabled: true,
        creatorPlayerId: 'player-1',
      );
}
