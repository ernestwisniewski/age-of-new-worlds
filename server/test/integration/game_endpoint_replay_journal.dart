part of 'game_endpoint_smoke.dart';

extension _GameEndpointReplayJournal on _GameEndpointJourney {
  Future<void> verifyReplayWriteRollback() async {
    final joined = await _createAndJoin();
    await game.GameReplayEntry.db.insertRow(
      databaseSession,
      game.GameReplayEntry(
        matchId: _initialMatch.id!,
        revision: _initialMatch.revision + 1,
        actorPlayerId: 'player-1',
        commandKind: 'player',
        commandJson: '{}',
        stateDigest: 'a' * 64,
        initialEventOffset: 0,
        finalEventOffset: 0,
      ),
    );
    await expectLater(
      joined.endpoint.submitTurn(
        ownerSession,
        game.GameSubmitTurnRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'replay-write-failure',
          expectedRevision: joined.created.revision,
        ),
      ),
      throwsA(isA<DatabaseQueryException>()),
    );
    final current = await game.GameMatch.db.findById(
      databaseSession,
      _initialMatch.id!,
    );
    expect(current!.revision, _initialMatch.revision);
    expect(current.canonicalStateJson, _initialMatch.canonicalStateJson);
    expect(current.eventOffset, 0);
    expect(
      await game.GameCommandLedger.db.find(
        databaseSession,
        where: (table) => table.matchId.equals(current.id!),
      ),
      isEmpty,
    );
    expect(
      await game.GameEvent.db.find(
        databaseSession,
        where: (table) => table.matchId.equals(current.id!),
      ),
      isEmpty,
    );
  }

  Future<void> _rememberReplayCheckpoint(game.GameMatchView created) async {
    _initialMatch = (await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(created.matchId),
    ))!;
    expect(_initialMatch.initialStateJson, _initialMatch.canonicalStateJson);
    expect(_initialMatch.initialRevision, created.revision);
    expect(
      _initialMatch.initialStateDigest,
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    expect(_initialMatch.replayBehaviorFingerprint, isNotEmpty);
    final protocol = jsonEncode(_initialMatch.toJsonForProtocol());
    for (final field in [
      'initialStateJson',
      'initialStateDigest',
      'initialRevision',
      'replayBehaviorFingerprint',
    ]) {
      expect(protocol, isNot(contains(field)));
    }
  }

  Future<void> _verifyReplayJournal(
    game.GameMatch current,
    List<String> commands,
  ) async {
    expect(current.initialStateJson, _initialMatch.initialStateJson);
    expect(current.initialStateDigest, _initialMatch.initialStateDigest);
    expect(current.initialRevision, _initialMatch.initialRevision);
    expect(
      current.replayBehaviorFingerprint,
      _initialMatch.replayBehaviorFingerprint,
    );
    final entries = await game.GameReplayEntry.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
      orderBy: (table) => table.revision,
    );
    expect(entries, hasLength(current.revision - current.initialRevision!));
    expect(
      entries.map((entry) => _object(jsonDecode(entry.commandJson))['type']),
      commands,
    );
    var offset = 0;
    var revision = current.initialRevision!;
    for (final entry in entries) {
      expect(entry.revision, ++revision);
      expect(entry.initialEventOffset, offset);
      expect(entry.stateDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        entry.commandKind,
        entry.actorPlayerId == null ? 'system' : 'player',
      );
      offset = entry.finalEventOffset;
    }
    expect(offset, current.eventOffset);
    final snapshot = await game.GameRecipientSnapshot.db.findFirstRow(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
    );
    final stamp = _object(_object(jsonDecode(snapshot!.snapshotJson))['stamp']);
    expect(entries.last.stateDigest, stamp['stateDigest']);
    expect(current.canonicalStateJson, isNot(current.initialStateJson));
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
