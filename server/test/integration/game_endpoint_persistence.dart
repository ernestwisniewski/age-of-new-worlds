part of 'game_endpoint_smoke.dart';

extension _GameEndpointPersistence on _GameEndpointJourney {
  Future<_PersistedMatch> _verifyPersistedState(
    _JoinedMatch joined,
    game.GameCommandOutcome guestTurn,
  ) async {
    final match = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(match, isNotNull);
    final persisted = match!;
    expect(persisted.eventOffset, guestTurn.finalEventOffset);
    expect(persisted.state, 'running');
    expect(persisted.startedAt, isNotNull);
    expect(persisted.turn, greaterThanOrEqualTo(0));
    expect(persisted.endedAt, isNull);
    expect(persisted.outcomeCondition, isNull);
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(persisted.id!),
    );
    expect(snapshots, hasLength(2));
    expect(snapshots.map((snapshot) => snapshot.eventOffset).toSet(), {
      guestTurn.finalEventOffset,
    });
    await _expectEvents(persisted.id!, guestTurn.finalEventOffset);
    await _expectPublicStats();
    return _PersistedMatch(
      row: persisted,
      snapshots: {
        for (final snapshot in snapshots)
          snapshot.playerId: snapshot.snapshotJson,
      },
    );
  }

  Future<void> _expectEvents(int matchId, int finalOffset) async {
    final events = await game.GameEvent.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(matchId),
      orderBy: (table) => table.offset,
    );
    expect(
      events.map((event) => event.offset),
      List<int>.generate(finalOffset, (index) => index + 1),
    );
  }

  Future<void> _expectPublicStats() async {
    final stats = await PublicGameStatsService(
      cacheTtl: Duration.zero,
    ).snapshot(ServerpodPublicGameStatsStore(databaseSession));
    expect(stats.totals.activeSessions, greaterThanOrEqualTo(1));
    expect(stats.totals.matchesStarted, greaterThanOrEqualTo(1));
  }

  Future<void> _verifyRollback(
    _JoinedMatch joined,
    _PersistedMatch persisted,
    game.GameCommandOutcome guestTurn,
  ) async {
    await game.GameMatch.db.updateRow(
      databaseSession,
      persisted.row.copyWith(canonicalStateJson: '{}'),
    );
    await expectLater(
      GameEndpoint().submitTurn(
        ownerSession,
        game.GameSubmitTurnRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'must-roll-back',
          expectedRevision: persisted.row.revision,
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'invalid_canonical_state',
        ),
      ),
    );
    final ledgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.clientCommandId.equals('must-roll-back'),
    );
    expect(ledgers, isEmpty);
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(persisted.row.id!),
    );
    expect({
      for (final snapshot in snapshots)
        snapshot.playerId: snapshot.snapshotJson,
    }, persisted.snapshots);
    expect(guestTurn.finalEventOffset, persisted.row.eventOffset);
  }
}
