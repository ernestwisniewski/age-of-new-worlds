part of 'multiplayer_coordinator_test.dart';

void accountProfileCases() {
  test('profile rename preserves account and match lobby', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    final profile = await coordinator.readProfile();
    expect(profile.userId, _account.userId);
    expect(profile.displayName, 'Original');
    final lobby = coordinator.state as MultiplayerLobby;
    final renamed = await coordinator.updateDisplayName(' New name ');
    expect(renamed.displayName, 'New name');
    expect(renamed.userId, profile.userId);
    expect(coordinator.state, same(lobby));
    expect(lobby.matches.single.matchId, 'match-1');
    expect(session.commandIds, isEmpty);
  });

  test('profile cannot expose another account', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    session.profileRequest = () async =>
        const AccountProfileView(userId: 'other', displayName: 'Other');
    await expectLater(
      coordinator.readProfile(),
      throwsA(
        isA<MultiplayerSessionException>().having(
          (error) => error.code,
          'code',
          'invalid_profile_response',
        ),
      ),
    );
  });

  test('signing out invalidates a pending profile result', () async {
    final session = _Session()..restored = _account;
    final coordinator = _coordinator(session);
    addTearDown(coordinator.close);
    await coordinator.initialize();
    final response = Completer<AccountProfileView>();
    session.profileRequest = () => response.future;
    final pending = coordinator.readProfile();
    final rejected = expectLater(
      pending,
      throwsA(
        isA<MultiplayerSessionException>().having(
          (error) => error.code,
          'code',
          'profile_session_changed',
        ),
      ),
    );
    await coordinator.signOut();
    response.complete(
      AccountProfileView(userId: _account.userId, displayName: 'Old'),
    );
    await rejected;
    expect(coordinator.state, isA<MultiplayerSignedOut>());
  });
}
