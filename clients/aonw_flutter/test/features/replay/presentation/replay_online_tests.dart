part of 'replay_presentation_controller_test.dart';

void replayOnlineTests() {
  testWidgets(
    'online replay uses shared playback and clears on account change',
    (tester) async {
      final session = _ReplaySession(observed: true);
      final network = _NetworkReplay(session);
      final controller = ReplayPresentationController(
        session: session,
        networkSession: network,
        store: _ReplayStore(primary: 'local'),
      );
      addTearDown(controller.dispose);
      expect(
        (await controller.openOnline(_history(), 'account')).started,
        isTrue,
      );
      expect(network.userId, 'account');
      expect(network.assets!.actorPlayerId, 'player-2');
      expect(controller.cityPlanningSession, same(session));
      controller.play();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      expect(session.positions, [1]);
      expect((controller.state as ReplayReady).frame.command, isNotNull);
      controller.updateOnlineAccount('another');
      expect(controller.state, isA<ReplayIdle>());
      await tester.pump(const Duration(seconds: 3));
      expect(session.positions, [1]);
      expect((await controller.openLatest()).started, isTrue);
      controller.updateOnlineAccount(null);
      expect(controller.state, isA<ReplayReady>());
      expect(session.openedDocuments, ['local']);
    },
  );

  test('account change prevents accepting a pending open', () async {
    final session = _ReplaySession();
    final network = _NetworkReplay(session)
      ..pending = Completer<ReplayFrameView>();
    final controller = ReplayPresentationController(
      session: session,
      networkSession: network,
      store: null,
    );
    addTearDown(controller.dispose);
    final opened = controller.openOnline(_history(), 'account');
    await Future<void>.delayed(Duration.zero);
    controller.updateOnlineAccount(null);
    network.pending!.complete(session._frame(0));
    expect((await opened).started, isFalse);
    expect(controller.state, isA<ReplayIdle>());
  });

  test(
    'unavailable archives do not invoke the network and failures are visible',
    () async {
      final session = _ReplaySession();
      final network = _NetworkReplay(session);
      final controller = ReplayPresentationController(
        session: session,
        networkSession: network,
        store: null,
        diagnosticReporter: (_, _, _) {},
      );
      addTearDown(controller.dispose);
      expect(
        (await controller.openOnline(
          _history(available: false),
          'account',
        )).failure,
        ReplayFailureViewCode.unavailable,
      );
      expect(network.userId, isNull);
      network.failure = StateError('offline');
      expect(
        (await controller.openOnline(_history(), 'account')).failure,
        ReplayFailureViewCode.incompatible,
      );
      expect(controller.state, isA<ReplayFailure>());
    },
  );
}

MatchHistoryEntryView _history({bool available = true}) =>
    MatchHistoryEntryView(
      match: MultiplayerMatchView(
        matchId: 'completed',
        mapId: 'aonw2_starter',
        mapHash: 'a' * 64,
        rulesetId: 'aonw-standard',
        rulesetHash: 'b' * 64,
        phase: MultiplayerMatchPhase.finished,
        hostPlayerId: 'player-1',
        startedAt: DateTime.utc(2026),
        revision: 3,
        eventOffset: 3,
      ),
      playerId: 'player-2',
      turn: 3,
      replayAvailable: available,
    );

final class _NetworkReplay implements NetworkReplaySessionPort {
  _NetworkReplay(this.session);
  final _ReplaySession session;
  Completer<ReplayFrameView>? pending;
  Object? failure;
  String? userId;
  MapAssetPaths? assets;
  @override
  Future<ReplayFrameView> openNetworkReplay({
    required String userId,
    required String matchId,
    required String mapHash,
    required String rulesetHash,
    required MapAssetPaths assets,
  }) async {
    this.userId = userId;
    this.assets = assets;
    if (failure case final error?) throw error;
    return pending?.future ?? session._frame(0);
  }
}
