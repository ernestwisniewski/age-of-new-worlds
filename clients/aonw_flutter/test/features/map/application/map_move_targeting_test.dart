import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/application/movement_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/delayed_movement_session.dart';
import '../../../support/map_test_fixture.dart';

void main() {
  for (final canStart in [true, false]) {
    test('selection and toggling use engine availability: $canStart', () async {
      final session = _session()
        ..reachableResult = testReachableView(canStartTargeting: canStart);
      final controller = await _select(session);
      expect(_interaction(controller).moveTargeting, canStart);
      expect(controller.canToggleMoveTargeting, canStart);
      if (canStart) controller.toggleMoveTargeting();
      expect(_interaction(controller).moveTargeting, isFalse);
      expect(_interaction(controller).selectedUnitId, 'preview-commander');
      controller.toggleMoveTargeting();
      expect(_interaction(controller).moveTargeting, canStart);
      expect(
        session.selectionRequestOrder.where((v) => v == 'reachable'),
        hasLength(1),
      );
    });
  }

  test(
    'standard cursor selects terrain and active cursor only hovers',
    () async {
      final session = _session();
      final controller = await _select(session);
      controller.moveMapCursor((col: 1, row: 0));
      expect(controller.hovered, (col: 1, row: 0));
      expect(_interaction(controller).selected, (col: 0, row: 0));
      expect(_interaction(controller).selectedUnitId, 'preview-commander');
      controller.toggleMoveTargeting();
      controller.moveMapCursor((col: 1, row: 0));
      expect(_interaction(controller).selected, (col: 1, row: 0));
      expect(_interaction(controller).selectedUnitId, isNull);
      expect(_interaction(controller).route, isNull);
      controller.moveMapCursor((col: 0, row: 0));
      expect(_interaction(controller).selected, (col: 0, row: 0));
      expect(_interaction(controller).selectedUnitId, isNull);
      controller.moveMapCursor((col: 99, row: 99));
      expect(_interaction(controller).selected, (col: 0, row: 0));
      expect(
        session.selectionRequestOrder.where((v) => v == 'reachable'),
        hasLength(1),
      );
      controller.select((col: 0, row: 0));
      await pumpEventQueue();
      expect(_interaction(controller).moveTargeting, isTrue);
    },
  );

  test('toggling cancels a route query and rejects its late reply', () async {
    final movement = DelayedMovementSession();
    final controller = await _select(_session(), movement: movement);
    controller.select((col: 1, row: 0));
    expect(_interaction(controller).movementPending, isTrue);
    controller.toggleMoveTargeting();
    expect(_interaction(controller).movementPending, isFalse);
    expect(_interaction(controller).moveTargeting, isFalse);
    expect(_interaction(controller).selectedUnitId, 'preview-commander');
    controller.toggleMoveTargeting();
    movement.requests.single.complete(testRoutePlanView());
    await pumpEventQueue();
    expect(_interaction(controller).moveTargeting, isTrue);
    expect(_interaction(controller).route, isNull);
  });

  test(
    'founding keeps movement disabled while preserving the founder',
    () async {
      final controller = await _select(_session());
      controller.openCityFounding();
      await pumpEventQueue();
      expect(_interaction(controller).moveTargeting, isFalse);
      expect(controller.canToggleMoveTargeting, isFalse);
      controller.toggleMoveTargeting();
      expect(_interaction(controller).city?.founderUnitId, 'preview-commander');
      controller.cancelInteraction();
      expect(_interaction(controller).selectedUnitId, 'preview-commander');
      expect(_interaction(controller).moveTargeting, isFalse);
      expect(controller.canToggleMoveTargeting, isTrue);
    },
  );

  for (final canRetain in [true, false]) {
    test(
      'accepted movement uses fresh retain availability: $canRetain',
      () async {
        final movement = _Movement();
        final controller = await _select(_session(), movement: movement);
        await _move(controller);
        expect(movement.revisions, [0, 1]);
        expect(_interaction(controller).selectedUnitId, 'preview-commander');
        expect(_interaction(controller).selected, (col: 1, row: 0));
        expect(_interaction(controller).moveTargeting, isFalse);
        movement.refresh.complete(
          testReachableView(
            revision: 1,
            canStartTargeting: false,
            canRetainTargeting: canRetain,
            availableMovementUnits: 0,
          ),
        );
        await pumpEventQueue();
        expect(_interaction(controller).moveTargeting, canRetain);
        expect(
          _interaction(controller).actionDeck?.unitId,
          'preview-commander',
        );
        expect(_interaction(controller).unitLogistics?.options, isNotNull);
        if (canRetain) controller.toggleMoveTargeting();
        expect(controller.canToggleMoveTargeting, isFalse);
        controller.toggleMoveTargeting();
        expect(_interaction(controller).moveTargeting, isFalse);
      },
    );
  }

  test('a submitted movement command cannot be toggled or cancelled', () async {
    final movement = _Movement();
    final controller = await _select(_session(), movement: movement);
    controller.select((col: 1, row: 0));
    await pumpEventQueue();
    controller.confirmMove();
    final pending = controller.state;
    expect(controller.canToggleMoveTargeting, isFalse);
    controller.toggleMoveTargeting();
    controller.cancelInteraction();
    expect(controller.state, same(pending));
    await pumpEventQueue();
    movement.refresh.complete(testReachableView(revision: 1));
    await pumpEventQueue();
    expect(_interaction(controller).moveTargeting, isTrue);
  });

  test('a late movement refresh cannot restore a cleared selection', () async {
    final movement = _Movement();
    final controller = await _select(_session(), movement: movement);
    await _move(controller);
    controller.cancelInteraction();
    movement.refresh.complete(testReachableView(revision: 1));
    await pumpEventQueue();
    expect(_interaction(controller).selectedUnitId, isNull);
    expect(_interaction(controller).reachable, isNull);
    expect(_interaction(controller).moveTargeting, isFalse);
  });

  test('a stale movement response cannot enable targeting', () async {
    final movement = _Movement();
    final controller = await _select(_session(), movement: movement);
    await _move(controller);
    movement.refresh.complete(testReachableView());
    await pumpEventQueue();
    expect(_interaction(controller).reachable, isNull);
    expect(_interaction(controller).moveTargeting, isFalse);
    expect(controller.canToggleMoveTargeting, isFalse);
  });

  test(
    'movement refresh adopts a resync without restoring targeting',
    () async {
      final movement = _Movement();
      final controller = await _select(_session(), movement: movement);
      await _move(controller);
      final player = PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 2),
        turn: 1,
        pendingAction: null,
        units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
      );
      movement.refresh.completeError(
        MovementSessionException(
          code: 'recipient_resynchronized',
          message: 'Projection resynchronized.',
          resyncedPlayer: player,
        ),
      );
      await pumpEventQueue();
      expect((controller.state as GameSessionReady).recipient, same(player));
      expect(_interaction(controller).moveTargeting, isFalse);
      expect(controller.canToggleMoveTargeting, isFalse);
    },
  );

  test('a late refresh cannot replace a new founding mode', () async {
    final movement = _Movement();
    final controller = await _select(_session(), movement: movement);
    await _move(controller);
    controller.openCityFounding();
    await pumpEventQueue();
    movement.refresh.complete(testReachableView(revision: 1));
    await pumpEventQueue();
    expect(_interaction(controller).city?.founderUnitId, 'preview-commander');
    expect(_interaction(controller).moveTargeting, isFalse);
  });

  test(
    'recipient changes invalidate targeting and cleared geometry ends it',
    () {
      final scene = testMapScene(units: [testVisibleUnit()]);
      final active = GameSessionReady.initial(scene).withInteraction(
        MapInteractionState(
          selectedUnitId: 'preview-commander',
          reachable: testReachableView(),
          moveTargeting: true,
        ),
      );
      expect(
        active.withRecipient(scene.player).interaction.moveTargeting,
        isTrue,
      );
      final changed = PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(stateDigest: 'd' * 64),
        turn: 1,
        pendingAction: null,
        units: scene.player.units,
      );
      expect(active.withRecipient(changed).interaction.moveTargeting, isFalse);
      expect(
        active.interaction.copyWith(clearReachable: true).moveTargeting,
        isFalse,
      );
      expect(
        active.interaction.copyWith(clearSelectedUnit: true).moveTargeting,
        isFalse,
      );
    },
  );
}

FakeGameSession _session() => FakeGameSession.success(
  testMapScene(units: [testVisibleUnit()]),
  reachableResult: testReachableView(),
  cityFoundingOptionsResult: testCityFoundingOptionsView(),
);

Future<MapCoordinator> _select(
  FakeGameSession session, {
  MovementSessionPort? movement,
}) async {
  final controller = MapCoordinator(
    capabilities: testGameSessionCapabilities(session, movement: movement),
  );
  addTearDown(controller.dispose);
  await controller.load();
  controller.selectUnit('preview-commander');
  await pumpEventQueue();
  return controller;
}

MapInteractionState _interaction(MapCoordinator controller) =>
    (controller.state as GameSessionReady).interaction;

Future<void> _move(MapCoordinator controller) async {
  controller.select((col: 1, row: 0));
  await pumpEventQueue();
  controller.confirmMove();
  await pumpEventQueue();
}

final class _Movement implements MovementSessionPort {
  final revisions = <int>[];
  final refresh = Completer<ReachableView>();
  @override
  Future<ReachableView> reachable({
    required int expectedRevision,
    required String unitId,
  }) async {
    revisions.add(expectedRevision);
    return revisions.length == 1 ? testReachableView() : refresh.future;
  }

  @override
  Future<RoutePlanView> routePlan({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async => testRoutePlanView();

  @override
  Future<MoveUnitResultView> moveUnit({
    required int expectedRevision,
    required String unitId,
    required MapHexCoordinate target,
  }) async => MoveUnitResultView.accepted(
    player: PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: 1),
      turn: 1,
      pendingAction: null,
      units: [testVisibleUnit(coordinate: target, movementUnits: 0)],
    ),
    execution: testMoveUnitExecutionView(),
  );
}
