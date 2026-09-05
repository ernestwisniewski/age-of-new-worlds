part of 'map_coordinator_turn_test.dart';

void observedTurnTests() {
  test(
    'presents each AI frame before advancing and queries only the final revision',
    () async {
      final session = _observedSession();
      final controller = _controller(session);
      addTearDown(controller.dispose);
      final gates = <Completer<void>>[];
      controller.waitForCommandEffects = () {
        final gate = Completer<void>();
        gates.add(gate);
        return gate.future;
      };
      await controller.startLocalMatch(_localEntry, _localSetup());
      await Future<void>.delayed(Duration.zero);
      final initialQueries = session.researchOptionCalls;
      controller.endTurn();
      await Future<void>.delayed(Duration.zero);
      for (var revision = 2; revision <= 4; revision++) {
        final ready = controller.state as GameSessionReady;
        expect(ready.recipient.stamp.revision, revision);
        expect(ready.commandFrame!.player, same(ready.recipient));
        expect(ready.localAiTurn.inFlight, isTrue);
        expect(session.researchOptionCalls, initialQueries);
        controller.endTurn();
        expect(session.endTurnCalls, 1);
        gates.last.complete();
        await Future<void>.delayed(Duration.zero);
      }
      final completed = controller.state as GameSessionReady;
      expect(completed.localAiTurn.phase, LocalAiTurnPhase.idle);
      expect(completed.recipient.stamp.revision, 4);
      expect(completed.commandFrame, isNull);
      expect(gates, hasLength(3));
      expect(session.researchOptionCalls, initialQueries + 1);
    },
  );

  test(
    'reloading during AI presentation discards the remaining old frames',
    () async {
      final session = _observedSession();
      final controller = _controller(session);
      addTearDown(controller.dispose);
      final gate = Completer<void>();
      var calls = 0;
      controller.waitForCommandEffects = () {
        calls++;
        return gate.future;
      };
      await controller.startLocalMatch(_localEntry, _localSetup());
      controller.endTurn();
      await Future<void>.delayed(Duration.zero);
      expect(
        (controller.state as GameSessionReady).recipient.stamp.revision,
        2,
      );
      await controller.load();
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      final ready = controller.state as GameSessionReady;
      expect(ready.recipient.actorPlayerId, 'preview-player');
      expect(ready.recipient.stamp.revision, 0);
      expect(ready.commandFrame, isNull);
      expect(calls, 1);
    },
  );
}

FakeGameSession _observedSession() => FakeGameSession.success(
  testMapScene(),
  turnResult: TurnCommandResultView.accepted(
    player: _observedPlayer(1),
    activities: const [],
    evidence: _turnEvidence,
  ),
  aiTurnResults: [
    LocalAiTurnExecutionView(
      aiPlayerId: 'player-2',
      executedCommands: 3,
      completedTurn: true,
      player: _observedPlayer(4),
      frames: [
        for (var revision = 2; revision <= 4; revision++)
          MapCommandFrameView(player: _observedPlayer(revision)),
      ],
    ),
  ],
);

PlayerMapView _observedPlayer(int revision) => PlayerMapView.preview(
  actorPlayerId: 'player-1',
  stamp: testSessionStamp(
    revision: revision,
    stateDigest: '$revision'.padLeft(64, 'a'),
  ),
  turn: revision == 4 ? 2 : 1,
  pendingAction: null,
  units: const [],
);
