import 'dart:async';
import 'dart:math';

import 'package:aonw_flutter/features/multiplayer/application/account_profile_port.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_coordinator.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_state.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter_test/flutter_test.dart';

part 'multiplayer_coordinator_fixture.dart';
part 'multiplayer_session_fixture.dart';
part 'account_profile_cases.dart';

void main() {
  accountProfileCases();
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

  test(
    'resignation keeps one identity across reconnect and returns to lobby',
    () async {
      final session = _Session()
        ..restored = _account
        ..resignFailures = 1;
      final coordinator = _coordinator(session);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      await coordinator.openMatch(session.matches.single);

      await coordinator.resignMatch();

      final state = coordinator.state as MultiplayerLobby;
      expect(state.matches, isEmpty);
      expect(session.reconnectCount, 1);
      expect(session.resignCommandIds, hasLength(2));
      expect(session.resignCommandIds.toSet(), hasLength(1));
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

MultiplayerProjectionView _projection({
  int revision = 7,
  int eventOffset = 10,
  bool submitted = false,
  String outcomeCondition = 'ongoing',
  String? winnerPlayerId,
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
  outcomeCondition: outcomeCondition,
  winnerPlayerId: winnerPlayerId,
);
