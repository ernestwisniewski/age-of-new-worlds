import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/turns/application/turn_action_state.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'focuses unit, city production and dismissible local research',
    () async {
      final h = _Harness();
      addTearDown(h.controller.dispose);
      await h.controller.load();
      await h.navigate();
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
      expect(h.ready.interaction.moveTargeting, isTrue);
      await h.navigate();
      expect(h.ready.interaction.city?.cityId, 'preview-city');
      expect(h.ready.interaction.production, isNotNull);
      expect(h.ready.interaction.selected, (col: 1, row: 1));
      await h.navigate();
      expect(h.ready.interaction.researchFocused, isTrue);
      expect(h.ready.interaction.moveTargeting, isFalse);
      expect(h.ready.recipient.pendingAction, isNull);
      expect(h.ready.interaction.city?.cityId, 'preview-city');
      h.controller.closeTurnResearch();
      expect(h.ready.interaction.researchFocused, isFalse);
      await h.navigate();
      await h.navigate();
      expect(h.ready.interaction.selectedUnitId, 'preview-commander');
      expect(h.ready.interaction.researchFocused, isFalse);
    },
  );

  test('queued selections wait for their dependent queries', () async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    await h.controller.load();
    await Future.wait([h.navigate(), h.navigate(), h.navigate()]);
    expect(h.ready.interaction.researchFocused, isTrue);
    expect(h.session.pendingTurnActionsRevisions, [0, 0, 0]);
  });

  test('selection, reload and disposal invalidate a pending Start', () async {
    for (final change in ['selection', 'reload', 'dispose']) {
      final h = _Harness();
      final response = Completer<PendingTurnActionsView>();
      h.session.pendingTurnActionsHandler = (_) => response.future;
      await h.controller.load();
      final navigation = h.navigate(endWhenEmpty: true);
      await Future<void>.delayed(Duration.zero);
      switch (change) {
        case 'selection':
          h.controller.select((col: 2, row: 1));
        case 'reload':
          await h.controller.load();
        case 'dispose':
          h.controller.dispose();
      }
      response.complete(h.work([]));
      await navigation;
      expect(h.session.endTurnCalls, 0, reason: change);
      if (change != 'dispose') h.controller.dispose();
    }
  });

  test(
    'query error is presented and never falls through to end turn',
    () async {
      final h = _Harness();
      addTearDown(h.controller.dispose);
      await h.controller.load();
      h.session.pendingTurnActionsFailure = const TurnSessionException(
        code: 'offline',
        message: 'Unavailable',
      );
      await h.navigate(endWhenEmpty: true);
      expect(
        h.ready.turnAction.failure?.code,
        TurnFailureViewCode.requestFailed,
      );
      expect(h.session.endTurnCalls, 0);
      h.session.pendingTurnActionsFailure = null;
      h.session.pendingTurnActionsResult = h.work([
        const PendingResearchTurnActionView(),
      ]);
      await h.navigate();
      expect(h.ready.turnAction.failure, isNull);
      expect(h.ready.interaction.researchFocused, isTrue);
    },
  );

  test('empty Start delegates to the normal end turn workflow once', () async {
    final h = _Harness();
    addTearDown(h.controller.dispose);
    await h.controller.load();
    h.session.pendingTurnActionsResult = h.work([]);
    await Future.wait([
      h.navigate(endWhenEmpty: true),
      h.navigate(endWhenEmpty: true),
    ]);
    expect(h.session.endTurnCalls, 1);
    expect(h.session.lastEndTurnExpectedRevision, 0);
  });
}

final class _Harness {
  _Harness() {
    session = FakeGameSession.success(
      scene,
      reachableResult: testReachableView(),
      cityInspection: testCityInspectionView(),
      turnFailure: const TurnSessionException(
        code: 'offline',
        message: 'Unavailable',
      ),
    );
    session.pendingTurnActionsResult = work([
      const PendingUnitTurnActionView(
        unitId: 'preview-commander',
        coordinate: (col: 0, row: 0),
      ),
      const PendingCityProductionTurnActionView(
        cityId: 'preview-city',
        coordinate: (col: 1, row: 1),
      ),
      const PendingResearchTurnActionView(),
    ]);
    controller = MapCoordinator(
      capabilities: testGameSessionCapabilities(session),
    );
  }
  final scene = testMapScene(
    units: [testVisibleUnit()],
    cities: [testCityView()],
  );
  late final FakeGameSession session;
  late final MapCoordinator controller;
  GameSessionReady get ready => controller.state as GameSessionReady;
  PendingTurnActionsView work(List<PendingTurnActionView> actions) =>
      PendingTurnActionsView(
        stamp: scene.player.stamp,
        actorPlayerId: scene.player.actorPlayerId,
        canActivate: true,
        actions: actions,
      );
  Future<void> navigate({bool endWhenEmpty = false}) =>
      controller.navigateTurnActions(
        step: 1,
        endWhenEmpty: endWhenEmpty,
        inputAvailable: () => true,
      );
}
