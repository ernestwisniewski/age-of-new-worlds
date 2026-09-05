import 'dart:async';

import 'package:aonw_flutter/features/local_game/application/local_ai_turn_state.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/local_game/application/local_handoff_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_command_frame_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

part 'map_coordinator_observed_turn_tests.dart';

void main() {
  observedTurnTests();
  test('ends a local turn only after the accepted recipient patch', () async {
    final nextPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
      turn: 2,
      pendingAction: null,
      units: const [],
    );
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: TurnCommandResultView.accepted(
        player: nextPlayer,
        activities: const [
          TurnActivityView(
            identity: TurnActivityIdentityView(revision: 1, eventIndex: 0),
            kind: TurnActivityKindView.turnEnded,
          ),
        ],
        evidence: TurnKernelEvidenceView(
          processors: const ['movement'],
          foundedCityIds: const [],
          combatExecutionCount: 0,
          resetUnitIds: const [],
          movementExecutionCount: 0,
          invalidatedOrderUnitIds: const [],
          finishedAutoExploreUnitIds: const [],
        ),
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();

    controller.endTurn();
    controller.endTurn();
    await Future<void>.delayed(Duration.zero);

    final ready = controller.state as GameSessionReady;
    expect(session.endTurnCalls, 1);
    expect(session.lastEndTurnExpectedRevision, 0);
    expect(ready.recipient.turn, 2);
    expect(
      ready.turnPresentations.latestActivity?.kind,
      TurnActivityKindView.turnEnded,
    );
    expect(ready.turnAction.inFlight, isFalse);
  });

  test('keeps authoritative state after a rejected end turn', () async {
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: const TurnCommandResultView.rejected(
        code: TurnRejectionCodeView.playerNotActive,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.load();

    controller.endTurn();
    await Future<void>.delayed(Duration.zero);

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient.turn, 1);
    expect(
      ready.turnAction.failure?.rejectionCode,
      TurnRejectionCodeView.playerNotActive,
    );
  });

  test(
    'runs configured AI participants after an accepted human turn',
    () async {
      final humanEnded = PlayerMapView.preview(
        actorPlayerId: 'player-1',
        stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
        turn: 1,
        pendingAction: null,
        units: const [],
      );
      final nextHumanTurn = PlayerMapView.preview(
        actorPlayerId: 'player-1',
        stamp: testSessionStamp(revision: 4, stateDigest: 'e' * 64),
        turn: 2,
        pendingAction: null,
        units: const [],
      );
      final session = FakeGameSession.success(
        testMapScene(),
        turnResult: TurnCommandResultView.accepted(
          player: humanEnded,
          activities: const [],
          evidence: _turnEvidence,
        ),
        aiTurnResults: [
          LocalAiTurnExecutionView(
            aiPlayerId: 'player-2',
            executedCommands: 3,
            completedTurn: true,
            player: nextHumanTurn,
          ),
        ],
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);
      await controller.startLocalMatch(_localEntry, _localSetup());

      controller.endTurn();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final ready = controller.state as GameSessionReady;
      expect(session.endTurnCalls, 1);
      expect(session.aiTurnCalls, 1);
      expect(session.aiTurnRequests.single.aiPlayerId, 'player-2');
      expect(ready.recipient.turn, 2);
      expect(ready.localAiTurn.phase, LocalAiTurnPhase.idle);
    },
  );

  test(
    'keeps the resynced human view and blocks play after AI failure',
    () async {
      final humanEnded = PlayerMapView.preview(
        actorPlayerId: 'player-1',
        stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
        turn: 1,
        pendingAction: null,
        units: const [],
      );
      final resynced = PlayerMapView.preview(
        actorPlayerId: 'player-1',
        stamp: testSessionStamp(revision: 2, stateDigest: 'e' * 64),
        turn: 1,
        pendingAction: null,
        units: const [],
      );
      final session = FakeGameSession.success(
        testMapScene(),
        turnResult: TurnCommandResultView.accepted(
          player: humanEnded,
          activities: const [],
          evidence: _turnEvidence,
        ),
        aiTurnFailure: LocalGameSessionException(
          code: 'ai_turn_failed',
          message: 'AI failed.',
          resyncedPlayer: resynced,
        ),
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);
      await controller.startLocalMatch(_localEntry, _localSetup());

      controller.endTurn();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      controller.endTurn();

      final ready = controller.state as GameSessionReady;
      expect(ready.recipient.stamp.revision, 2);
      expect(ready.localAiTurn.phase, LocalAiTurnPhase.failed);
      expect(
        ready.localAiTurn.failure,
        LocalAiTurnFailureViewCode.requestFailed,
      );
      expect(session.endTurnCalls, 1);
    },
  );

  test('hides the next human view until that player confirms', () async {
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: TurnCommandResultView.accepted(
        player: _player('player-1', revision: 1),
        activities: const [],
        evidence: _turnEvidence,
      ),
      handoffPlayers: {'player-2': _player('player-2', revision: 1)},
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.startLocalMatch(
      _localEntry,
      _localSetup(secondControl: LocalPlayerControlView.human),
    );

    controller.endTurn();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    var ready = controller.state as GameSessionReady;
    expect(session.handoffRequests, ['player-2']);
    expect(ready.recipient.actorPlayerId, 'player-2');
    expect(ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);

    controller.endTurn();
    await Future<void>.delayed(Duration.zero);
    expect(session.endTurnCalls, 1);

    controller.confirmLocalHandoff();
    ready = controller.state as GameSessionReady;
    expect(ready.localHandoff.phase, LocalHandoffPhase.idle);
  });

  test('advances AI before privately handing off to the next human', () async {
    final returnedHuman = _player('player-1', revision: 4, turn: 2);
    final session = FakeGameSession.success(
      testMapScene(),
      turnResult: TurnCommandResultView.accepted(
        player: _player('player-1', revision: 1),
        activities: const [],
        evidence: _turnEvidence,
      ),
      aiTurnResults: [
        LocalAiTurnExecutionView(
          aiPlayerId: 'player-2',
          executedCommands: 3,
          completedTurn: true,
          player: returnedHuman,
        ),
      ],
      handoffPlayers: {'player-3': _player('player-3', revision: 4, turn: 2)},
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);
    await controller.startLocalMatch(_threePlayerEntry, _mixedSetup());

    controller.endTurn();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final ready = controller.state as GameSessionReady;
    expect(session.aiTurnRequests.single.aiPlayerId, 'player-2');
    expect(session.handoffRequests, ['player-3']);
    expect(ready.recipient.actorPlayerId, 'player-3');
    expect(ready.localHandoff.phase, LocalHandoffPhase.awaitingConfirmation);
  });
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

LocalMatchSetupView _localSetup({
  LocalPlayerControlView secondControl = LocalPlayerControlView.ai,
}) => LocalMatchSetupView(
  assets: const MapAssetPaths(
    document: 'map',
    bundleManifest: 'manifest',
    scenarioDocument: 'scenario',
    actorPlayerId: 'player-1',
  ),
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player',
      colorValue: 1,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: secondControl == LocalPlayerControlView.ai ? 'AI' : 'Player 2',
      colorValue: 2,
      country: LocalPlayerCountryView.japan,
      control: secondControl,
      ai: secondControl == LocalPlayerControlView.ai
          ? const LocalAiProfileView(seed: 7)
          : null,
    ),
  ],
  fogEnabled: true,
);

const _localEntry = LocalGameCatalogEntryView(
  id: LocalGameScenarioView.starterDuel,
  mapId: 'map',
  rulesetId: 'ruleset',
  columns: 7,
  rows: 7,
  maximumPlayers: 2,
  assets: MapAssetPaths(
    document: 'map',
    bundleManifest: 'manifest',
    scenarioDocument: 'scenario',
    actorPlayerId: 'player-1',
  ),
  participantIds: ['player-1', 'player-2'],
);

const _threePlayerEntry = LocalGameCatalogEntryView(
  id: LocalGameScenarioView.starterDuel,
  mapId: 'map',
  rulesetId: 'ruleset',
  columns: 7,
  rows: 7,
  maximumPlayers: 3,
  assets: MapAssetPaths(
    document: 'map',
    bundleManifest: 'manifest',
    scenarioDocument: 'scenario',
    actorPlayerId: 'player-1',
  ),
  participantIds: ['player-1', 'player-2', 'player-3'],
);

LocalMatchSetupView _mixedSetup() => LocalMatchSetupView(
  assets: _threePlayerEntry.assets,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player 1',
      colorValue: 1,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'AI',
      colorValue: 2,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 7),
    ),
    LocalParticipantSetupView(
      id: 'player-3',
      name: 'Player 3',
      colorValue: 3,
      country: LocalPlayerCountryView.france,
      control: LocalPlayerControlView.human,
    ),
  ],
  fogEnabled: true,
);

PlayerMapView _player(String actor, {required int revision, int turn = 1}) =>
    PlayerMapView.preview(
      actorPlayerId: actor,
      stamp: testSessionStamp(revision: revision),
      turn: turn,
      pendingAction: null,
      units: const [],
    );

final _turnEvidence = TurnKernelEvidenceView(
  processors: [],
  foundedCityIds: [],
  combatExecutionCount: 0,
  resetUnitIds: [],
  movementExecutionCount: 0,
  invalidatedOrderUnitIds: [],
  finishedAutoExploreUnitIds: [],
);
