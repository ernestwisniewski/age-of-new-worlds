part of 'game_lobby_endpoint_smoke.dart';

void lobbyPresenceCases(TestSessionBuilder sessions) {
  test('presence requires authentication and active membership', () async {
    final lobby = await _PresenceLobby.create(sessions);
    await expectLater(
      lobby.endpoint.watchLobby(sessions.build(), lobby.id),
      emitsError(isA<game.GameException>()),
    );
    final outsider = _authenticated(sessions, 'presence-outsider').build();
    await expectLater(
      lobby.endpoint.watchLobby(outsider, lobby.id),
      emitsError(isA<game.GameException>()),
    );
    expect(await game.GameLobbyConnection.db.count(lobby.owner), 0);
  });

  test(
    'live connections gate start independently of seats and readiness',
    () async {
      final lobby = await _PresenceLobby.create(sessions);
      await lobby.endpoint.setReady(lobby.owner, lobby.id, true);
      await lobby.endpoint.setReady(lobby.guest, lobby.id, true);
      final before = await lobby.persisted();
      var view = await lobby.read();
      expect(view.participants.every((p) => p.isClaimed && p.isReady), isTrue);
      expect(view.participants.every((p) => !p.isConnected), isTrue);
      expect(view.canStart, isFalse);

      final oldOwner = await watchTestLobby(
        lobby.endpoint.watchLobby(lobby.owner, lobby.id),
      );
      final newOwner = await watchTestLobby(
        lobby.endpoint.watchLobby(lobby.owner, lobby.id),
      );
      final guest = await watchTestLobby(
        lobby.endpoint.watchLobby(lobby.guest, lobby.id),
      );
      view = await lobby.read();
      expect(view.canStart, isTrue);
      expect(view.participants.every((p) => p.isConnected), isTrue);
      await oldOwner.cancel();
      expect((await lobby.read()).canStart, isTrue);
      await guest.cancel();
      view = await lobby.read();
      expect(view.canStart, isFalse);
      expect(view.participants.last.isConnected, isFalse);
      expect(view.participants.last.isReady, isTrue);
      expect(view.participants.last.isClaimed, isTrue);
      await expectLater(
        lobby.endpoint.startMatch(lobby.owner, lobby.id),
        throwsA(
          isA<game.GameException>().having(
            (e) => e.code,
            'code',
            'lobby_not_ready',
          ),
        ),
      );
      final after = await lobby.persisted();
      expect(after.canonicalStateJson, before.canonicalStateJson);
      expect(after.revision, before.revision);
      expect(after.eventOffset, before.eventOffset);
      await watchTestLobby(lobby.endpoint.watchLobby(lobby.guest, lobby.id));
      expect(
        (await lobby.endpoint.startMatch(lobby.owner, lobby.id)).match.state,
        'running',
      );
      await newOwner.cancel();
    },
  );

  test(
    'expired and previous membership leases cannot restore presence',
    () async {
      final lobby = await _PresenceLobby.create(sessions);
      final match = await lobby.persisted();
      final participant = (await game.GameParticipant.db.findFirstRow(
        lobby.owner,
        where: (table) =>
            table.matchId.equals(match.id!) & table.playerId.equals('player-2'),
      ))!;
      final now = DateTime.now().toUtc();
      final expired = await game.GameLobbyConnection.db.insertRow(
        lobby.owner,
        game.GameLobbyConnection(
          matchId: match.id!,
          participantId: participant.id!,
          userIdentifier: participant.userIdentifier,
          joinedAt: participant.joinedAt,
          expiresAt: now.subtract(const Duration(seconds: 1)),
        ),
      );
      expect((await lobby.read()).participants.last.isConnected, isFalse);
      await game.GameLobbyConnection.db.updateRow(
        lobby.owner,
        expired.copyWith(expiresAt: now.add(const Duration(minutes: 1))),
      );
      expect((await lobby.read()).participants.last.isConnected, isTrue);
      await lobby.endpoint.leaveLobby(lobby.guest, lobby.id);
      expect((await lobby.read()).participants.last.isConnected, isFalse);
      await lobby.endpoint.joinMatch(
        lobby.guest,
        game.GameJoinMatchRequest(matchId: lobby.id, playerId: 'player-2'),
      );
      final reclaimed = (await lobby.read()).participants.last;
      expect(reclaimed.isClaimed, isTrue);
      expect(reclaimed.isConnected, isFalse);
      expect(reclaimed.isReady, isFalse);
      await watchTestLobby(lobby.endpoint.watchLobby(lobby.guest, lobby.id));
      expect((await lobby.read()).participants.last.isConnected, isTrue);
    },
  );

  test('running phase reaches subscribers and releases their leases', () async {
    final lobby = await _PresenceLobby.create(sessions);
    final frames = <game.GameLobbyView>[];
    final complete = Completer<void>();
    final connected = Completer<void>();
    late final StreamSubscription<game.GameLobbyView> owner;
    owner = lobby.endpoint
        .watchLobby(lobby.owner, lobby.id)
        .listen(
          (frame) {
            frames.add(frame);
            if (!connected.isCompleted) {
              owner.pause();
              connected.complete();
            }
          },
          onError: complete.completeError,
          onDone: complete.complete,
        );
    addTearDown(owner.cancel);
    await connected.future;
    await watchTestLobby(lobby.endpoint.watchLobby(lobby.guest, lobby.id));
    await lobby.endpoint.setReady(lobby.owner, lobby.id, true);
    await lobby.endpoint.setReady(lobby.guest, lobby.id, true);
    await lobby.endpoint.startMatch(lobby.owner, lobby.id);
    owner.resume();
    await complete.future;
    expect(frames.first.match.state, 'lobby');
    expect(frames.last.match.state, 'running');
    final lease = await game.GameLobbyConnection.db.findFirstRow(
      lobby.owner,
      where: (table) => table.userIdentifier.equals('presence-owner'),
    );
    expect(lease, isNull);
  });
}

final class _PresenceLobby {
  _PresenceLobby(this.endpoint, this.owner, this.guest, this.id);
  final GameEndpoint endpoint;
  final Session owner;
  final Session guest;
  final String id;

  Future<game.GameLobbyView> read() => endpoint.lobby(owner, id);

  Future<game.GameMatch> persisted() async => (await game.GameMatch.db
      .findFirstRow(owner, where: (table) => table.publicId.equals(id)))!;

  static Future<_PresenceLobby> create(TestSessionBuilder sessions) async {
    addTearDown(shutdownAonwGameNativeHost);
    final owner = _authenticated(sessions, 'presence-owner').build();
    final guest = _authenticated(sessions, 'presence-guest').build();
    final endpoint = GameEndpoint();
    final created = await endpoint.createMatch(
      owner,
      game.GameCreateMatchRequest(
        mapId: 'postgres-ai-owner-map',
        mapDocument: _mapDocument(),
        scenarioDocument: _scenarioDocument(),
        rulesetId: 'aonw-standard',
        matchIdentityJson: _matchIdentityDocument(aiOwner: false),
        fogEnabled: true,
        creatorPlayerId: 'player-1',
      ),
    );
    await endpoint.joinMatch(
      guest,
      game.GameJoinMatchRequest(matchId: created.matchId, playerId: 'player-2'),
    );
    return _PresenceLobby(endpoint, owner, guest, created.matchId);
  }
}
