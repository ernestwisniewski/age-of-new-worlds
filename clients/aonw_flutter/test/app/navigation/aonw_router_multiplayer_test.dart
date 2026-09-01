import 'package:aonw_flutter/app/navigation/aonw_app.dart';
import 'package:aonw_flutter/app/navigation/aonw_router.dart';
import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/network_game_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_access_port.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_coordinator.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/multiplayer_access_controller.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/multiplayer_controller.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/map_test_fixture.dart';

void main() {
  testWidgets('checks multiplayer access before enabling the main menu', (
    tester,
  ) async {
    final mapController = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        FakeGameSession.success(testMapScene()),
      ),
    );
    final multiplayerController = MultiplayerController(
      MultiplayerCoordinator(
        session: _MultiplayerSession(),
        documents: const _MultiplayerDocuments(),
      ),
    );
    final accessController = MultiplayerAccessController(
      access: const _UpdateRequiredAccess(),
    );

    await tester.pumpWidget(
      AonwApp(
        mapController: mapController,
        multiplayerAccessController: accessController,
        multiplayerController: multiplayerController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('A newer version is ready'), findsAtLeast(1));
    final multiplayer = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('multiplayer')),
        matching: find.byType(InkWell),
      ),
    );
    expect(multiplayer.onTap, isNull);

    final singlePlayer = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('single-player')),
        matching: find.byType(InkWell),
      ),
    );
    expect(singlePlayer.onTap, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('opens an online match on the shared map route', (tester) async {
    final scene = testMapScene();
    final gameplay = FakeGameSession.success(scene);
    final network = _NetworkGameSession(scene);
    final multiplayerSession = _MultiplayerSession();
    final mapController = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        gameplay,
      ).withNetworkGame(network),
    );
    final multiplayerController = MultiplayerController(
      MultiplayerCoordinator(
        session: multiplayerSession,
        documents: const _MultiplayerDocuments(),
      ),
    );
    await multiplayerController.initialize();
    await multiplayerController.createMatch();
    await multiplayerController.setReady(true);
    await multiplayerController.startMatch();

    await tester.pumpWidget(
      AonwApp(
        mapController: mapController,
        multiplayerController: multiplayerController,
        initialRoute: AonwRoute.multiplayer,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('multiplayer-open-game')));
    await tester.pumpAndSettle();

    expect(network.setups.single.matchId, 'match-1');
    expect(network.setups.single.playerId, 'player-1');
    expect(find.byKey(const ValueKey('map-viewport')), findsOneWidget);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('map-viewport'))),
    ).pop();
    await tester.pumpAndSettle();
    expect(multiplayerSession.reconnectCalls, 1);
    expect(multiplayerSession.resyncCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

final class _UpdateRequiredAccess implements MultiplayerAccessPort {
  const _UpdateRequiredAccess();

  @override
  Future<MultiplayerAccessStatus> check() async =>
      MultiplayerAccessStatus.updateRequired;
}

final class _NetworkGameSession implements NetworkGameSessionPort {
  _NetworkGameSession(this.scene);

  final MapScene scene;
  final setups = <NetworkMatchSetupView>[];

  @override
  NetworkGameConnectionView get connection =>
      const NetworkGameConnectionView(NetworkGameConnectionPhase.ready);

  @override
  Stream<NetworkGameConnectionView> get connectionChanges =>
      const Stream.empty();

  @override
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup) async {
    setups.add(setup);
    return scene;
  }

  @override
  Future<MapScene> reconnectNetworkMatch() async => scene;
}

final class _MultiplayerSession implements MultiplayerSessionPort {
  var reconnectCalls = 0;
  var resyncCalls = 0;
  var lobbyView = _routerLobby();

  @override
  Future<MultiplayerAccountView?> restoreAccount() async =>
      const MultiplayerAccountView(userId: 'account-1');

  @override
  Future<List<MultiplayerMatchView>> listMatches() async => const [];

  @override
  Future<MultiplayerMatchLobbyView> createMatch(
    MultiplayerMatchDocuments documents,
  ) async => lobbyView;

  @override
  Future<void> close() async {}

  @override
  Future<void> reconnect() async => reconnectCalls += 1;

  @override
  Future<MultiplayerAccountView> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerMatchLobbyView> joinMatch({
    required String matchId,
    required String playerId,
  }) => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerMatchLobbyView> lobby(String matchId) async => lobbyView;

  @override
  Future<MultiplayerMatchLobbyView> setReady({
    required String matchId,
    required bool ready,
  }) async {
    lobbyView = _routerLobby(ready: ready);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchLobbyView> startMatch(String matchId) async {
    lobbyView = _routerLobby(ready: true, running: true);
    return lobbyView;
  }

  @override
  Future<MultiplayerMatchView> leaveLobby(String matchId) async =>
      lobbyView.match;

  @override
  Future<MultiplayerProjectionView> resync(String matchId) async {
    resyncCalls += 1;
    return _projection;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<MultiplayerAccountView> signIn({
    required String email,
    required String password,
  }) => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerCommandView> submitTurn({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerCommandView> kickParticipant({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
    required String targetPlayerId,
  }) => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerCommandView> resignMatch({
    required String matchId,
    required String clientCommandId,
    required int expectedRevision,
  }) => throw UnsupportedError('Not used by this test.');
}

final class _MultiplayerDocuments implements MultiplayerMatchDocumentSource {
  const _MultiplayerDocuments();

  @override
  Future<MultiplayerMatchDocuments> load(
    MultiplayerMatchSetupView setup,
  ) async => const MultiplayerMatchDocuments(
    mapId: 'map-1',
    mapDocument: '{}',
    scenarioDocument: '{}',
    rulesetId: 'ruleset-1',
    matchIdentityDocument: '{}',
    fogEnabled: true,
    creatorPlayerId: 'player-1',
  );
}

const _projection = MultiplayerProjectionView(
  matchId: 'match-1',
  playerId: 'player-1',
  revision: 7,
  stateDigest: 'digest-7',
  eventOffset: 10,
  turn: 1,
  ownTurnState: MultiplayerTurnStateView.active,
  ownSubmitted: false,
  requiredSubmissionCount: 2,
  submittedCount: 0,
  visibleUnitCount: 1,
  outcomeCondition: 'ongoing',
  winnerPlayerId: null,
);

MultiplayerMatchLobbyView _routerLobby({
  bool ready = false,
  bool running = false,
}) => MultiplayerMatchLobbyView(
  match: MultiplayerMatchView(
    matchId: 'match-1',
    mapId: 'map-1',
    mapHash: 'map-hash',
    rulesetId: 'ruleset-1',
    rulesetHash: 'ruleset-hash',
    phase: running
        ? MultiplayerMatchPhase.running
        : MultiplayerMatchPhase.lobby,
    hostPlayerId: 'player-1',
    startedAt: running ? DateTime.utc(2026) : null,
    revision: 7,
    eventOffset: 10,
  ),
  participants: [
    MultiplayerLobbyParticipantView(
      playerId: 'player-1',
      name: 'Player one',
      kind: 'human',
      isHost: true,
      isClaimed: true,
      isReady: ready,
      isCurrentUser: true,
    ),
    const MultiplayerLobbyParticipantView(
      playerId: 'player-2',
      name: 'Computer',
      kind: 'ai',
      isHost: false,
      isClaimed: false,
      isReady: true,
      isCurrentUser: false,
    ),
  ],
  canStart: !running && ready,
);
