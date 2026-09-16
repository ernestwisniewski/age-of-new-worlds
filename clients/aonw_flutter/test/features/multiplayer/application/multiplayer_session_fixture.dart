part of 'multiplayer_coordinator_test.dart';

final class _Session
    implements MultiplayerSessionPort, AccountProfilePort, MatchHistoryPort {
  Future<MatchHistoryPageView> Function(int?)? historyRequest;
  @override
  Future<MatchHistoryPageView> readMatchHistory({
    int? beforeParticipantId,
  }) async => historyRequest == null
      ? MatchHistoryPageView(userId: _account.userId, entries: [])
      : await historyRequest!(beforeParticipantId);
  Future<AccountProfileView> Function()? profileRequest;
  String profileName = 'Original';
  @override
  Future<AccountProfileView> readProfile() async => profileRequest == null
      ? AccountProfileView(userId: _account.userId, displayName: profileName)
      : await profileRequest!();
  @override
  Future<AccountProfileView> updateDisplayName(String name) async {
    profileName = name.trim();
    return readProfile();
  }

  MultiplayerAccountView? restored;
  var projection = _projection();
  var submitFailures = 0;
  var kickFailures = 0;
  var resignFailures = 0;
  var commandRevisionIncrement = 1;
  var reconnectCount = 0;
  var resyncCount = 0;
  var leaveLobbyCount = 0;
  var leftLobby = false;
  Object? listFailure;
  final commandIds = <String>[];
  final kickCommandIds = <String>[];
  final resignCommandIds = <String>[];
  List<MultiplayerMatchView> get matches => [
    MultiplayerMatchView(
      matchId: 'match-1',
      mapId: 'map-1',
      mapHash: 'map-hash',
      rulesetId: 'ruleset-1',
      rulesetHash: 'ruleset-hash',
      phase: MultiplayerMatchPhase.running,
      hostPlayerId: 'player-1',
      startedAt: DateTime.utc(2026),
      revision: 7,
      eventOffset: 10,
    ),
  ];
  var lobbyView = _lobbyView(phase: MultiplayerMatchPhase.running, ready: true);

  @override
  Future<MultiplayerAccountView?> restoreAccount() async => restored;

  @override
  Future<MultiplayerAccountView> signIn({
    required String email,
    required String password,
  }) async => _account;

  @override
  Future<MultiplayerAccountView> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async => _account;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> reconnect() async {
    reconnectCount += 1;
  }

  @override
  Future<List<MultiplayerMatchView>> listMatches() async {
    if (listFailure case final error?) throw error;
    return leftLobby ? const [] : matches;
  }

  @override
  Future<MultiplayerMatchLobbyView> createMatch(
    MultiplayerMatchDocuments documents,
  ) async => lobbyView = _lobbyView();

  @override
  Future<MultiplayerMatchLobbyView> joinMatch({
    required String matchId,
    required String playerId,
  }) async => _lobbyView(currentPlayerId: playerId);

  @override
  Future<MultiplayerMatchLobbyView> lobby(String matchId) async => lobbyView;

  @override
  Future<MultiplayerMatchLobbyView> setReady({
    required String matchId,
    required bool ready,
  }) async {
    lobbyView = _lobbyView(ready: ready);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchLobbyView> startMatch(String matchId) async {
    lobbyView = _lobbyView(phase: MultiplayerMatchPhase.running, ready: true);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchView> leaveLobby(String matchId) async {
    leaveLobbyCount += 1;
    leftLobby = true;
    return lobbyView.match;
  }

  @override
  Future<MultiplayerProjectionView> resync(String matchId) async {
    resyncCount += 1;
    return projection;
  }

  @override
  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) async {
    commandIds.add(clientCommandId);
    if (submitFailures > 0) {
      submitFailures -= 1;
      throw const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Connection interrupted.',
        retryable: true,
      );
    }
    projection = _projection(
      revision: expectedRevision + commandRevisionIncrement,
      eventOffset: 11,
      submitted: true,
    );
    lobbyView = _lobbyView(
      phase: MultiplayerMatchPhase.running,
      ready: true,
      revision: projection.revision,
      eventOffset: projection.eventOffset,
    );
    return MultiplayerCommandView(
      clientCommandId: clientCommandId,
      initialEventOffset: 10,
      finalEventOffset: 11,
      duplicate: commandIds.length > 1,
      accepted: true,
      rejectionCode: null,
      projection: projection,
    );
  }

  @override
  Future<MultiplayerCommandView> kickParticipant({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  }) async {
    kickCommandIds.add(clientCommandId);
    if (kickFailures > 0) {
      kickFailures -= 1;
      throw const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Connection interrupted.',
        retryable: true,
      );
    }
    projection = _projection(revision: expectedRevision + 1, eventOffset: 11);
    lobbyView = _lobbyView(
      phase: MultiplayerMatchPhase.running,
      ready: true,
      revision: projection.revision,
      eventOffset: projection.eventOffset,
      guestKind: 'human',
      guestClaimed: false,
    );
    return MultiplayerCommandView(
      clientCommandId: clientCommandId,
      initialEventOffset: 10,
      finalEventOffset: 11,
      duplicate: kickCommandIds.length > 1,
      accepted: true,
      rejectionCode: null,
      projection: projection,
    );
  }

  @override
  Future<MultiplayerCommandView> resignMatch({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) async {
    resignCommandIds.add(clientCommandId);
    if (resignFailures > 0) {
      resignFailures -= 1;
      throw const MultiplayerSessionException(
        code: 'connection_interrupted',
        message: 'Connection interrupted.',
        retryable: true,
      );
    }
    projection = _projection(
      revision: expectedRevision + 1,
      eventOffset: 12,
      outcomeCondition: 'resignation',
      winnerPlayerId: 'player-2',
    );
    leftLobby = true;
    return MultiplayerCommandView(
      clientCommandId: clientCommandId,
      initialEventOffset: 10,
      finalEventOffset: 12,
      duplicate: resignCommandIds.length > 1,
      accepted: true,
      rejectionCode: null,
      projection: projection,
    );
  }

  @override
  Future<void> close() async {}
}

MultiplayerMatchLobbyView _lobbyView({
  MultiplayerMatchPhase phase = MultiplayerMatchPhase.lobby,
  bool ready = false,
  String currentPlayerId = 'player-1',
  int revision = 7,
  int eventOffset = 10,
  String guestKind = 'ai',
  bool guestClaimed = false,
}) => MultiplayerMatchLobbyView(
  match: MultiplayerMatchView(
    matchId: 'match-1',
    mapId: 'map-1',
    mapHash: 'map-hash',
    rulesetId: 'ruleset-1',
    rulesetHash: 'ruleset-hash',
    phase: phase,
    hostPlayerId: 'player-1',
    startedAt: phase == MultiplayerMatchPhase.lobby ? null : DateTime.utc(2026),
    revision: revision,
    eventOffset: eventOffset,
  ),
  participants: [
    MultiplayerLobbyParticipantView(
      country: 'poland',
      colorValue: 0xff8b2424,
      playerId: 'player-1',
      name: 'Player one',
      kind: 'human',
      isHost: true,
      isClaimed: true,
      isConnected: true,
      isReady: ready,
      isCurrentUser: currentPlayerId == 'player-1',
    ),
    MultiplayerLobbyParticipantView(
      country: 'germany',
      colorValue: 0xff24608b,
      playerId: 'player-2',
      name: guestKind == 'ai' ? 'Computer' : 'Player two',
      kind: guestKind,
      isHost: false,
      isClaimed: guestClaimed,
      isConnected: guestClaimed,
      isReady: true,
      isCurrentUser: currentPlayerId == 'player-2',
    ),
  ],
  canStart:
      phase == MultiplayerMatchPhase.lobby &&
      currentPlayerId == 'player-1' &&
      ready,
);
