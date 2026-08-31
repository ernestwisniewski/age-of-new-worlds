import 'dart:async';

import 'package:aonw_flutter/features/artifacts/application/artifact_session_port.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/application/combat_session_port.dart';
import 'package:aonw_flutter/features/combat/read_model/combat_view.dart';
import 'package:aonw_flutter/features/diplomacy/application/diplomacy_session_port.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/logistics/application/unit_logistics_session_port.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_session_port.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:aonw_flutter/features/unit_actions/application/action_deck_state.dart';
import 'package:aonw_flutter/features/unit_actions/application/unit_action_session_port.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_session_port.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';
import '../../../support/unsupported_city_session.dart';

void main() {
  test('loads ready state and keeps interaction local', () async {
    final session = FakeGameSession.success(testMapScene());
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(
        session,
        cities: const UnsupportedCitySession(),
      ),
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.state, isA<GameSessionReady>());

    controller.hover((col: 1, row: 1));
    controller.select((col: 2, row: 1));
    controller.toggleReference();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient, same(ready.scene.player));
    expect(ready.turnPresentations.active?.turn, 1);
    expect(controller.hovered, (col: 1, row: 1));
    expect(ready.interaction.selected, (col: 2, row: 1));
    expect(ready.interaction.referenceVisible, isFalse);

    controller.completeTurnPresentation();
    expect(
      (controller.state as GameSessionReady).turnPresentations.active,
      isNull,
    );

    controller.select((col: 9, row: 9));
    expect((controller.state as GameSessionReady).interaction.selected, isNull);
  });

  test('exposes a typed session failure', () async {
    final session = FakeGameSession.failure(
      const MapLoadException(code: 'invalid_map', message: 'Bad map'),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();

    final failure = controller.state as GameSessionFailure;
    expect(failure.code, MapLoadFailureViewCode.mapUnavailable);
  });

  test('a slower old load cannot replace a newer result', () async {
    final session = _CompletingGameSession();
    final controller = MapCoordinator(
      capabilities: GameSessionCapabilities(
        map: session,
        movement: session,
        combat: session,
        cities: const UnsupportedCitySession(),
        logistics: session,
        workers: session,
        production: session,
        artifacts: session,
        research: session,
        diplomacy: session,
        unitActions: session,
        turns: session,
      ),
    );
    addTearDown(controller.dispose);

    final firstLoad = controller.load();
    final secondLoad = controller.load();
    session.requests[1].complete(testMapScene(mapId: 'new-map'));
    await secondLoad;
    session.requests[0].complete(testMapScene(mapId: 'old-map'));
    await firstLoad;

    final ready = controller.state as GameSessionReady;
    expect(ready.scene.map.mapId, 'new-map');
  });

  test(
    'keeps public errors stable and reports technical diagnostics',
    () async {
      final diagnostics =
          <({String code, Object error, StackTrace stackTrace})>[];
      final cause = FormatException('raw decoder details');
      final session = FakeGameSession.failure(
        MapLoadException(
          code: 'invalid_map',
          message: 'The map could not be opened.',
          diagnosticCause: cause,
          diagnosticStackTrace: StackTrace.current,
        ),
      );
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(session),
        diagnosticReporter: (code, error, stackTrace) =>
            diagnostics.add((code: code, error: error, stackTrace: stackTrace)),
      );
      addTearDown(controller.dispose);

      await controller.load();

      final failure = controller.state as GameSessionFailure;
      expect(failure.code, MapLoadFailureViewCode.mapUnavailable);
      expect(diagnostics.single.code, 'invalid_map');
      expect(diagnostics.single.error, same(cause));
    },
  );

  test(
    'selects a unit, previews a Rust route, and confirms movement',
    () async {
      final unit = testVisibleUnit();
      final scene = testMapScene(units: [unit]);
      final movedPlayer = PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1),
        turn: 1,
        pendingAction: null,
        units: [
          testVisibleUnit(coordinate: (col: 1, row: 0), movementUnits: 8),
        ],
      );
      final session = FakeGameSession.success(
        scene,
        reachableResult: testReachableView(),
        routeResult: testRoutePlanView(),
        moveResult: MoveUnitResultView.accepted(
          player: movedPlayer,
          execution: testMoveUnitExecutionView(),
        ),
      );
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.select((col: 0, row: 0));
      await pumpEventQueue();

      var ready = controller.state as GameSessionReady;
      expect(ready.interaction.selectedUnitId, unit.id);
      expect(ready.interaction.reachable?.tileAt((col: 1, row: 0)), isNotNull);
      expect(session.selectionRequestOrder.take(2), ['reachable', 'logistics']);

      controller.select((col: 1, row: 0));
      await pumpEventQueue();
      ready = controller.state as GameSessionReady;
      expect(ready.interaction.route?.destination, (col: 1, row: 0));

      controller.confirmMove();
      await pumpEventQueue();
      ready = controller.state as GameSessionReady;
      expect(ready.scene.player.stamp.revision, 1);
      expect(ready.scene.player.units.single.coordinate, (col: 1, row: 0));
      expect(ready.interaction.selected, (col: 1, row: 0));
      expect(ready.interaction.selectedUnitId, isNull);
      expect(ready.interaction.route, isNull);
      expect(
        ready.interaction.lastMovementExecution?.events.single.unitId,
        unit.id,
      );
    },
  );

  test(
    'keeps a rejected move typed and leaves the snapshot unchanged',
    () async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      final session = FakeGameSession.success(
        scene,
        reachableResult: testReachableView(),
        routeResult: testRoutePlanView(),
        moveResult: const MoveUnitResultView.rejected(
          code: CommandRejectionCodeView.moveTargetOccupied,
        ),
      );
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.select((col: 0, row: 0));
      await pumpEventQueue();
      controller.select((col: 1, row: 0));
      await pumpEventQueue();
      controller.confirmMove();
      await pumpEventQueue();

      final ready = controller.state as GameSessionReady;
      expect(ready.scene.player, same(scene.player));
      expect(
        ready.interaction.movementError?.rejectionCode,
        CommandRejectionCodeView.moveTargetOccupied,
      );
      expect(ready.interaction.route, isNotNull);
    },
  );

  test('adopts a typed recipient resync after an invalid patch', () async {
    final scene = testMapScene(units: [testVisibleUnit()]);
    final resyncedPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
      turn: 2,
      pendingAction: null,
      units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
    );
    final session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      routeResult: testRoutePlanView(),
      moveFailure: MovementSessionException(
        code: 'recipient_resynchronized',
        message: 'Recipient projection was resynchronized.',
        resyncedPlayer: resyncedPlayer,
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select((col: 0, row: 0));
    await pumpEventQueue();
    controller.select((col: 1, row: 0));
    await pumpEventQueue();
    controller.confirmMove();
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient, same(resyncedPlayer));
    expect(ready.turnPresentations.active?.turn, 1);
    expect(ready.turnPresentations.pending.single.turn, 2);
    expect(
      ready.interaction.movementError?.code,
      MapMovementFailureViewCode.responseIncompatible,
    );
  });

  test(
    'executes one correlated unit action and adopts authoritative state',
    () async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      final fortified = VisibleUnitView(
        id: 'preview-commander',
        ownerPlayerId: 'preview-player',
        kind: VisibleUnitKind.commander,
        name: 'Commander',
        coordinate: (col: 0, row: 0),
        movementUnits: 12,
        posture: VisibleUnitPosture.fortified,
      );
      final player = PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
        turn: 1,
        pendingAction: null,
        units: [fortified],
      );
      final session = FakeGameSession.success(
        scene,
        reachableResult: testReachableView(),
        unitActionResult: UnitActionResultView.accepted(
          action: UnitActionKindView.fortify,
          unitId: fortified.id,
          player: player,
        ),
      );
      final controller = MapCoordinator(
        capabilities: testGameSessionCapabilities(session),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.select(fortified.coordinate);
      await pumpEventQueue();
      controller.executeUnitAction(UnitActionKindView.fortify);
      controller.executeUnitAction(UnitActionKindView.skip);
      await pumpEventQueue();

      final ready = controller.state as GameSessionReady;
      expect(session.unitActionCalls, 1);
      expect(session.lastUnitAction, UnitActionKindView.fortify);
      expect(session.lastUnitActionExpectedRevision, 0);
      expect(session.lastUnitActionUnitId, fortified.id);
      expect(ready.recipient, same(player));
      expect(
        ready.recipient.units.single.posture,
        VisibleUnitPosture.fortified,
      );
      expect(ready.interaction.actionDeck?.commandPending, isFalse);
      expect(ready.interaction.actionDeck?.failure, isNull);
      expect(ready.interaction.selectedUnitId, fortified.id);
      expect(ready.interaction.reachable, isNull);
    },
  );

  test('keeps rejected unit action typed without optimistic state', () async {
    final scene = testMapScene(units: [testVisibleUnit()]);
    final session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      unitActionResult: const UnitActionResultView.rejected(
        action: UnitActionKindView.skip,
        unitId: 'preview-commander',
        code: UnitActionRejectionCodeView.unitBusy,
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select((col: 0, row: 0));
    await pumpEventQueue();
    controller.executeUnitAction(UnitActionKindView.skip);
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient, same(scene.player));
    expect(
      ready.interaction.actionDeck?.failure?.rejectionCode,
      UnitActionRejectionCodeView.unitBusy,
    );
    expect(ready.interaction.actionDeck?.commandPending, isFalse);
  });

  test('adopts resynced recipient after invalid unit action patch', () async {
    final scene = testMapScene(units: [testVisibleUnit()]);
    final resyncedPlayer = PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1, stateDigest: 'd' * 64),
      turn: 2,
      pendingAction: null,
      units: [testVisibleUnit(movementUnits: 0)],
    );
    final session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      unitActionFailure: UnitActionSessionException(
        code: 'recipient_resynchronized',
        message: 'Recipient projection was resynchronized.',
        resyncedPlayer: resyncedPlayer,
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);

    await controller.load();
    controller.select((col: 0, row: 0));
    await pumpEventQueue();
    controller.executeUnitAction(UnitActionKindView.cancel);
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.recipient, same(resyncedPlayer));
    expect(ready.turnPresentations.pending.single.turn, 2);
    expect(
      ready.interaction.actionDeck?.failure?.code,
      UnitActionFailureViewCode.responseIncompatible,
    );
  });

  test('blocks every gameplay command after authoritative outcome', () async {
    final session = FakeGameSession.success(
      testMapScene(
        units: [testVisibleUnit()],
        outcome: GameOutcomeView(
          condition: GameOutcomeConditionView.score,
          winnerPlayerId: 'preview-player',
          scoreByPlayerId: const {'preview-player': 21, 'player-2': 18},
        ),
      ),
    );
    final controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
    addTearDown(controller.dispose);
    await controller.load();

    controller.select((col: 0, row: 0));
    controller.confirmMove();
    controller.executeUnitAction(UnitActionKindView.skip);
    controller.executeUnitLogistics(
      const AutoExploreActionView(unitId: 'preview-commander'),
    );
    controller.executeWorkerAction(
      const CancelWorkerJobActionView(unitId: 'preview-commander'),
    );
    controller.executeProductionAction(
      const StartBuildingActionView(cityId: 'city-1', building: 'granary'),
    );
    controller.executeArtifactAction(
      const StartArtifactExcavationActionView(unitId: 'preview-commander'),
    );
    controller.executeCityAction(
      const ToggleWorkedHexActionView(
        cityId: 'city-1',
        target: (col: 0, row: 0),
      ),
    );
    controller.selectTechnology(TechnologyIdView.agriculture);
    controller.executeDiplomacyAction(const DeclareWarActionView('player-2'));
    controller.confirmCombat();
    controller.endTurn();
    await pumpEventQueue();

    final ready = controller.state as GameSessionReady;
    expect(ready.interaction.selected, isNull);
    expect(session.unitActionCalls, 0);
    expect(session.logisticsCommandCalls, 0);
    expect(session.workerCommandCalls, 0);
    expect(session.productionCommandCalls, 0);
    expect(session.artifactCommandCalls, 0);
    expect(session.cityCommandCalls, 0);
    expect(session.researchCommandCalls, 0);
    expect(session.diplomacyCommandCalls, 0);
    expect(session.combatAttackCalls, 0);
    expect(session.endTurnCalls, 0);
  });
}

final class _CompletingGameSession
    implements
        MapSessionPort,
        MovementSessionPort,
        CombatSessionPort,
        UnitLogisticsSessionPort,
        WorkerSessionPort,
        ProductionSessionPort,
        ArtifactSessionPort,
        ResearchSessionPort,
        DiplomacySessionPort,
        TurnSessionPort,
        UnitActionSessionPort {
  final requests = <Completer<MapScene>>[];

  @override
  Future<MapScene> load(MapAssetPaths assets) {
    final request = Completer<MapScene>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) => throw UnimplementedError();

  @override
  Future<CombatPreviewView> combatPreview({
    required int expectedRevision,
    required String attackerUnitId,
    required MapHexCoordinate defender,
  }) => throw UnimplementedError();

  @override
  Future<CombatCommandResultView> attack({
    required int expectedRevision,
    required CombatAttackView attack,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsOptionsView> unitLogisticsOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<UnitLogisticsCommandResultView> executeUnitLogistics({
    required int expectedRevision,
    required UnitLogisticsActionView action,
  }) => throw UnimplementedError();

  @override
  Future<WorkerOptionsView> workerOptions({
    required int expectedRevision,
    required String unitId,
  }) => throw UnimplementedError();

  @override
  Future<WorkerCommandResultView> executeWorkerAction({
    required int expectedRevision,
    required WorkerActionView action,
  }) => throw UnimplementedError();

  @override
  Future<
    ({ProductionOptionsView options, StrategicResourceProjectionView resources})
  >
  productionOverview({required int expectedRevision, required String cityId}) =>
      throw UnimplementedError();

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ArtifactCommandResultView> executeArtifactAction({
    required int expectedRevision,
    required ArtifactActionView action,
  }) => throw UnimplementedError();

  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) async => testResearchOptionsView(revision: expectedRevision);

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) => throw UnimplementedError();

  @override
  Future<DiplomacyCommandResultView> executeDiplomacyAction({
    required int expectedRevision,
    required DiplomacyActionView action,
  }) => throw UnimplementedError();

  @override
  Future<UnitActionResultView> executeUnitAction({
    required int expectedRevision,
    required String unitId,
    required UnitActionKindView action,
  }) => throw UnimplementedError();

  @override
  Future<TurnCommandResultView> endTurn({required int expectedRevision}) =>
      throw UnimplementedError();

  @override
  Future<void> close() async {}
}
