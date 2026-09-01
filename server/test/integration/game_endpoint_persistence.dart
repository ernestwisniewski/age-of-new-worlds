part of 'game_endpoint_smoke.dart';

extension _GameEndpointPersistence on _GameEndpointJourney {
  Future<void> _verifyTimeout(_JoinedMatch joined) async {
    final ownerTurn = await _submitOwner(joined, joined.created.revision);
    final persisted = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(persisted, isNotNull);
    expect(persisted!.turnDeadlineAt, isNotNull);
    final now = DateTime.now().toUtc();
    await game.GameMatch.db.updateRow(
      databaseSession,
      persisted.copyWith(
        turnDeadlineAt: now.subtract(const Duration(seconds: 1)),
      ),
    );

    final result = await const GameTurnTimeoutService(
      batchSize: 4,
    ).run(databaseSession, now: now);
    final retry = await const GameTurnTimeoutService(
      batchSize: 4,
    ).run(databaseSession, now: now);

    expect(result.candidates, 1);
    expect(result.finalized, 1);
    expect(result.failures, isEmpty);
    expect(result.backlogRemaining, isFalse);
    expect(retry.candidates, 0);
    expect(retry.finalized, 0);
    final current = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(current, isNotNull);
    expect(current!.revision, ownerTurn.nextRevision + 1);
    expect(current.turn, persisted.turn + 1);
    expect(current.turnDeadlineAt, isNotNull);
    expect(current.turnDeadlineAt!.isAfter(now), isTrue);
    final canonical = _object(jsonDecode(current.canonicalStateJson!));
    final lifecycle = _object(canonical['turnLifecycle']);
    expect(lifecycle['submittedPlayerIds'], isEmpty);
    expect(lifecycle['timeoutStreaksByPlayerId'], {'player-2': 1});
    expect(lifecycle['turnStartedAt'], now.toIso8601String());

    final events = await game.GameEvent.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
      orderBy: (table) => table.offset,
    );
    final timeoutEvents = events
        .map((event) => _object(jsonDecode(event.eventJson!)))
        .where((event) => event['type'] == 'playerTimedOut')
        .toList(growable: false);
    expect(timeoutEvents, hasLength(1));
    expect(timeoutEvents.single['playerId'], 'player-2');
    final ledgers = await game.GameCommandLedger.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
    );
    expect(ledgers, hasLength(1));
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
    );
    expect(snapshots.map((snapshot) => snapshot.eventOffset).toSet(), {
      current.eventOffset,
    });
  }

  Future<void> _verifyResignation(_JoinedMatch joined) async {
    final request = game.GameResignMatchRequest(
      matchId: joined.created.matchId,
      clientCommandId: 'owner-resign-1',
      expectedRevision: joined.created.revision,
    );
    final accepted = await joined.endpoint.resignMatch(ownerSession, request);
    final retry = await joined.endpoint.resignMatch(ownerSession, request);
    expect(accepted.duplicate, isFalse);
    expect(retry.duplicate, isTrue);
    expect(retry.outcomeJson, accepted.outcomeJson);
    expect(accepted.initialEventOffset, 0);
    expect(accepted.finalEventOffset, 2);

    final match = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(match, isNotNull);
    final current = match!;
    expect(current.state, 'finished');
    expect(current.endedAt, isNotNull);
    expect(current.turnDeadlineAt, isNull);
    expect(current.outcomeCondition, 'resignation');
    expect(current.winnerPlayerId, 'player-2');
    expect(current.revision, joined.created.revision + 1);
    expect(current.eventOffset, 2);
    final canonical = _object(jsonDecode(current.canonicalStateJson!));
    final lifecycle = _object(canonical['turnLifecycle']);
    expect(lifecycle['resignedPlayerIds'], ['player-1']);
    expect(lifecycle['kickedPlayerIds'], isEmpty);

    final resigning = await game.GameParticipant.db.findFirstRow(
      databaseSession,
      where: (table) =>
          (table.matchId.equals(current.id!)) &
          (table.playerId.equals('player-1')),
    );
    expect(resigning, isNotNull);
    expect(resigning!.resignedAt, isNotNull);
    expect(resigning.kickedAt, isNull);
    expect(resigning.leftAt, isNull);
    expect(await joined.endpoint.listMatches(ownerSession), isEmpty);
    await expectLater(
      joined.endpoint.resync(ownerSession, joined.created.matchId),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'not_participant',
        ),
      ),
    );

    final guest = await joined.endpoint.resync(
      guestSession,
      joined.created.matchId,
    );
    expect(guest.eventOffset, 2);
    expect(_object(jsonDecode(guest.snapshotJson))['outcome'], {
      'condition': 'resignation',
      'winnerPlayerId': 'player-2',
      'scoreByPlayerId': <String, Object?>{},
    });
    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
    );
    expect(snapshots, hasLength(2));
    expect(snapshots.map((snapshot) => snapshot.eventOffset).toSet(), {2});
    final events = await game.GameEvent.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
      orderBy: (table) => table.offset,
    );
    expect(
      events.map((event) => _object(jsonDecode(event.eventJson!))['type']),
      ['playerResigned', 'matchEnded'],
    );
  }

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

  Future<_KickResult> _verifyKick(
    _JoinedMatch joined,
    _PersistedMatch persisted,
  ) async {
    final request = game.GameKickParticipantRequest(
      matchId: joined.created.matchId,
      clientCommandId: 'owner-kick-guest-1',
      expectedRevision: persisted.row.revision,
      targetPlayerId: 'player-2',
    );
    await expectLater(
      joined.endpoint.kickParticipant(
        guestSession,
        game.GameKickParticipantRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'guest-kick-owner-1',
          expectedRevision: persisted.row.revision,
          targetPlayerId: 'player-1',
        ),
      ),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'host_required',
        ),
      ),
    );

    final accepted = await joined.endpoint.kickParticipant(
      ownerSession,
      request,
    );
    final retry = await joined.endpoint.kickParticipant(ownerSession, request);
    expect(accepted.duplicate, isFalse);
    expect(retry.duplicate, isTrue);
    expect(retry.outcomeJson, accepted.outcomeJson);
    expect(accepted.finalEventOffset, persisted.row.eventOffset + 1);
    final safeOutcome = _object(jsonDecode(accepted.outcomeJson));
    expect(_object(safeOutcome['recipient'])['recipientPlayerId'], 'player-1');

    final match = await game.GameMatch.db.findFirstRow(
      databaseSession,
      where: (table) => table.publicId.equals(joined.created.matchId),
    );
    expect(match, isNotNull);
    final current = match!;
    expect(current.eventOffset, accepted.finalEventOffset);
    expect(current.revision, persisted.row.revision + 1);
    final canonical = _object(jsonDecode(current.canonicalStateJson!));
    final lifecycle = _object(canonical['turnLifecycle']);
    expect(lifecycle['kickedPlayerIds'], ['player-2']);

    final target = await game.GameParticipant.db.findFirstRow(
      databaseSession,
      where: (table) =>
          (table.matchId.equals(current.id!)) &
          (table.playerId.equals('player-2')),
    );
    expect(target, isNotNull);
    expect(target!.kickedAt, isNotNull);
    expect(target.kickReason, 'host_removed');
    expect(await joined.endpoint.listMatches(guestSession), isEmpty);
    await expectLater(
      joined.endpoint.resync(guestSession, joined.created.matchId),
      throwsA(
        isA<game.GameException>().having(
          (error) => error.code,
          'code',
          'not_participant',
        ),
      ),
    );

    final snapshots = await game.GameRecipientSnapshot.db.find(
      databaseSession,
      where: (table) => table.matchId.equals(current.id!),
    );
    expect(snapshots, hasLength(2));
    expect(snapshots.map((snapshot) => snapshot.eventOffset).toSet(), {
      accepted.finalEventOffset,
    });
    await _expectEvents(current.id!, accepted.finalEventOffset);
    return _KickResult(
      persisted: _PersistedMatch(
        row: current,
        snapshots: {
          for (final snapshot in snapshots)
            snapshot.playerId: snapshot.snapshotJson,
        },
      ),
      outcome: accepted,
    );
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
