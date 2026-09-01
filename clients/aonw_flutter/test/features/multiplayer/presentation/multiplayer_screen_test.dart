import 'dart:ui' as ui;

import 'package:aonw_flutter/features/multiplayer/application/multiplayer_coordinator.dart';
import 'package:aonw_flutter/features/multiplayer/application/multiplayer_session_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/multiplayer_controller.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/multiplayer_screen.dart';
import 'package:aonw_flutter/features/multiplayer/read_model/multiplayer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';

void main() {
  testWidgets('creates a match and exposes an accessible turn action', (
    tester,
  ) async {
    MultiplayerProjectionView? openedProjection;
    final coordinator = MultiplayerCoordinator(
      session: _Session(),
      documents: const _Documents(),
    );
    final controller = MultiplayerController(coordinator);
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(
      LocalizedTestApp(
        home: MultiplayerScreen(
          controller: controller,
          onOpenGame: (projection) async => openedProjection = projection,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('multiplayer-create-match')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('multiplayer-start-match')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('multiplayer-ready')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('multiplayer-start-match')));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('multiplayer-submit-turn'));
    expect(submit, findsOneWidget);
    final semantics = tester.getSemantics(submit);
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, ui.Tristate.isTrue);

    await tester.tap(find.byKey(const ValueKey('multiplayer-open-game')));
    await tester.pump();
    expect(openedProjection, same(_projection));
  });
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

final class _Session implements MultiplayerSessionPort {
  var _lobby = _matchLobby();

  @override
  Future<MultiplayerAccountView?> restoreAccount() async =>
      const MultiplayerAccountView(userId: 'account-1');

  @override
  Future<List<MultiplayerMatchView>> listMatches() async => const [];

  @override
  Future<MultiplayerMatchLobbyView> createMatch(
    MultiplayerMatchDocuments documents,
  ) async => _lobby;

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
  Future<MultiplayerMatchLobbyView> lobby(String matchId) async => _lobby;

  @override
  Future<MultiplayerMatchLobbyView> setReady({
    required String matchId,
    required bool ready,
  }) async {
    _lobby = _matchLobby(ready: ready);
    return _lobby;
  }

  @override
  Future<MultiplayerMatchLobbyView> startMatch(String matchId) async {
    _lobby = _matchLobby(ready: true, running: true);
    return _lobby;
  }

  @override
  Future<void> reconnect() => throw UnsupportedError('Not used by this test.');

  @override
  Future<MultiplayerProjectionView> resync(String matchId) async => _projection;

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
  Future<void> close() async {}
}

MultiplayerMatchLobbyView _matchLobby({
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

final class _Documents implements MultiplayerMatchDocumentSource {
  const _Documents();

  @override
  Future<MultiplayerMatchDocuments> load() async =>
      const MultiplayerMatchDocuments(
        mapId: 'map-1',
        mapDocument: '{}',
        scenarioDocument: '{}',
        rulesetId: 'ruleset-1',
        matchIdentityDocument: '{}',
        fogEnabled: true,
        creatorPlayerId: 'player-1',
      );
}
