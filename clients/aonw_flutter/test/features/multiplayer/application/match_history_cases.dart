part of 'multiplayer_coordinator_test.dart';

void matchHistoryCases() {
  test('history preserves the active lobby and forwards pagination', () async {
    final session = _Session()..restored = _account;
    final cursors = <int?>[];
    session.historyRequest = (cursor) async {
      cursors.add(cursor);
      return MatchHistoryPageView(userId: _account.userId, entries: []);
    };
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.readMatchHistory();
    final lobby = coordinator.state;
    await coordinator.readMatchHistory(beforeParticipantId: 42);
    expect(cursors, [null, 42]);
    expect(coordinator.state, same(lobby));
    expect(session.commandIds, isEmpty);
  });

  test(
    'history rejects a foreign account and a result after sign-out',
    () async {
      final session = _Session()..restored = _account;
      final coordinator = _coordinator(session);
      addTearDown(coordinator.close);
      await coordinator.initialize();
      session.historyRequest = (_) async =>
          MatchHistoryPageView(userId: 'foreign', entries: []);
      final changed = isA<MultiplayerSessionException>().having(
        (error) => error.code,
        'code',
        'history_session_changed',
      );
      await expectLater(coordinator.readMatchHistory(), throwsA(changed));
      final response = Completer<MatchHistoryPageView>();
      session.historyRequest = (_) => response.future;
      final pending = expectLater(
        coordinator.readMatchHistory(),
        throwsA(changed),
      );
      await coordinator.signOut();
      response.complete(
        MatchHistoryPageView(userId: _account.userId, entries: []),
      );
      await pending;
      expect(coordinator.state, isA<MultiplayerSignedOut>());
    },
  );
}
