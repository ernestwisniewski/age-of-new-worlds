part of 'game_endpoint_smoke.dart';

extension _GameEndpointReplay on _GameEndpointJourney {
  Future<void> verifyReplayPages() async {
    final joined = await _createAndJoin();
    var revision = joined.created.revision;
    for (var index = 0; index < 260; index++) {
      final applied = await joined.endpoint.applyCommand(
        ownerSession,
        game.GamePlayerCommandRequest(
          matchId: joined.created.matchId,
          clientCommandId: 'replay-page-$index',
          commandJson: jsonEncode({
            'type': 'fortifyUnit',
            'expectedRevision': revision,
            'unitId': 'unit-1',
          }),
        ),
      );
      final outcome = _object(jsonDecode(applied.outcomeJson));
      expect(outcome['rejection'], isNull);
      revision = _nonNegativeInt(_object(outcome['stamp'])['revision']);
    }
    await joined.endpoint.resignMatch(
      ownerSession,
      game.GameResignMatchRequest(
        matchId: joined.created.matchId,
        clientCommandId: 'replay-page-finish',
        expectedRevision: revision,
      ),
    );
    for (final position in [0, 1, 255, 256, 257, 261]) {
      final response = await joined.endpoint.replayFrame(
        ownerSession,
        joined.created.matchId,
        position,
      );
      final frame = _object(jsonDecode(response.frameJson));
      expect(frame['entryCount'], 261);
      expect(frame['position'], position);
      final snapshot = _object(frame['snapshot']);
      expect(
        _object(snapshot['stamp'])['revision'],
        joined.created.revision + position,
      );
      if (position > 0) {
        final command = _object(frame['command']);
        expect(
          _object(command['viewPatch'])['fromRevision'],
          joined.created.revision + position - 1,
        );
      }
    }
  }

  Future<void> verifyReplayRead() async {
    final joined = await _createAndJoin();
    await _expectReplayError(
      joined.endpoint.replayFrame(ownerSession, joined.created.matchId, 0),
      'replay_unavailable',
    );
    await joined.endpoint.resignMatch(
      ownerSession,
      game.GameResignMatchRequest(
        matchId: joined.created.matchId,
        clientCommandId: 'replay-resignation',
        expectedRevision: joined.created.revision,
      ),
    );
    for (final (session, player) in [
      (ownerSession, 'player-1'),
      (guestSession, 'player-2'),
    ]) {
      await _verifyReplayRecipient(joined, session, player);
    }
    await _expectReplayError(
      joined.endpoint.replayFrame(databaseSession, joined.created.matchId, 0),
      'auth_required',
    );
    for (final position in [-1, 2]) {
      await _expectReplayError(
        joined.endpoint.replayFrame(
          ownerSession,
          joined.created.matchId,
          position,
        ),
        'invalid_replay_position',
      );
    }
    final history = await joined.endpoint.matchHistory(ownerSession);
    expect(history.entries.single.replayAvailable, isTrue);
    await _verifyReplayDrift(joined);
  }

  Future<void> _verifyReplayRecipient(
    _JoinedMatch joined,
    Session session,
    String player,
  ) async {
    final initial = await joined.endpoint.replayFrame(
      session,
      joined.created.matchId,
      0,
    );
    final initialFrame = _object(jsonDecode(initial.frameJson));
    expect(initial.playerId, player);
    expect(initialFrame['recipientPlayerId'], player);
    expect(initialFrame['position'], 0);
    expect(initialFrame['entryCount'], 1);
    expect(initialFrame['command'], isNull);
    final finalFrame = await joined.endpoint.replayFrame(
      session,
      joined.created.matchId,
      1,
    );
    final decoded = _object(jsonDecode(finalFrame.frameJson));
    final stored = await game.GameRecipientSnapshot.db.findFirstRow(
      databaseSession,
      where: (table) =>
          table.matchId.equals(_initialMatch.id!) &
          table.playerId.equals(player),
    );
    expect(decoded['snapshot'], jsonDecode(stored!.snapshotJson));
    expect(decoded['command'], isNotNull);
    for (final frame in [initialFrame, decoded]) {
      final snapshot = _object(frame['snapshot']);
      final units = snapshot['units'] as List<Object?>;
      for (final raw in units) {
        final unit = _object(raw);
        if (unit['ownerPlayerId'] != player) {
          expect(unit['ownedDetails'], isNull);
        }
      }
      expect(frame.keys.toSet(), {
        'type',
        'position',
        'entryCount',
        'recipientPlayerId',
        'snapshot',
        'command',
      });
    }
    final snapshot = _object(initialFrame['snapshot']);
    final stamp = _object(snapshot['stamp']);
    final query = await joined.endpoint.replayQuery(
      session,
      game.GamePlayerQueryRequest(
        matchId: joined.created.matchId,
        queryJson: jsonEncode({
          'type': 'cityPlanning',
          'expectedRevision': stamp['revision'],
        }),
      ),
      0,
    );
    final outcome = _object(jsonDecode(query.outcomeJson));
    expect(outcome['status'], 'success');
    final result = _object(outcome['result']);
    expect(result['type'], 'cityPlanning');
    expect(result['stamp'], stamp);
  }

  Future<void> _verifyReplayDrift(_JoinedMatch joined) async {
    final entry = (await game.GameReplayEntry.db.findFirstRow(
      databaseSession,
      where: (table) => table.matchId.equals(_initialMatch.id!),
    ))!;
    await game.GameReplayEntry.db.updateRow(
      databaseSession,
      entry.copyWith(stateDigest: '0' * 64),
    );
    await _expectReplayError(
      joined.endpoint.replayFrame(ownerSession, joined.created.matchId, 0),
      'replay_mismatch',
    );
    await game.GameReplayEntry.db.updateRow(databaseSession, entry);
    final match = (await game.GameMatch.db.findById(
      databaseSession,
      _initialMatch.id!,
    ))!;
    await game.GameMatch.db.updateRow(
      databaseSession,
      match.copyWith(initialStateJson: null),
    );
    await _expectReplayError(
      joined.endpoint.replayFrame(ownerSession, joined.created.matchId, 0),
      'replay_unavailable',
    );
    await game.GameMatch.db.updateRow(databaseSession, match);
    final owner = (await game.GameParticipant.db.findFirstRow(
      databaseSession,
      where: (table) =>
          table.matchId.equals(match.id!) & table.playerId.equals('player-1'),
    ))!;
    await game.GameParticipant.db.updateRow(
      databaseSession,
      owner.copyWith(userIdentifier: 'another-user'),
    );
    await _expectReplayError(
      joined.endpoint.replayFrame(ownerSession, joined.created.matchId, 0),
      'not_participant',
    );
  }
}

Future<void> _expectReplayError(Future<Object?> operation, String code) =>
    expectLater(
      operation,
      throwsA(
        isA<game.GameException>().having((error) => error.code, 'code', code),
      ),
    );
