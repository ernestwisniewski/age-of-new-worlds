import 'dart:async';

import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/turns/application/pending_turn_navigation.dart';
import 'package:aonw_flutter/features/turns/application/turn_session_port.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'cycles authoritative order, wraps and follows each successful focus',
    () async {
      final h = _Harness();
      await h.navigate();
      await h.navigate();
      await h.navigate();
      await h.navigate();
      await h.navigate(step: -1);
      expect(h.focused, [h.unit, h.city, h.research, h.unit, h.research]);
      expect(h.session.pendingTurnActionsRevisions, [0, 0, 0, 0, 0]);
      expect(h.ends, 0);
    },
  );

  test('backward from missing selection starts at the last action', () async {
    final h = _Harness();
    await h.navigate(step: -1);
    expect(h.focused, [h.research]);
  });

  test('rapid inputs wait for focus before querying the next action', () async {
    final h = _Harness();
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    final first = h.navigate();
    final second = h.navigate();
    final third = h.navigate();
    await Future<void>.delayed(Duration.zero);
    expect(h.session.pendingTurnActionsRevisions, [0]);
    response.complete(h.work());
    await Future.wait([first, second, third]);
    expect(h.focused, [h.unit, h.city, h.research]);
  });

  test('external scope changes cancel all queued navigation', () async {
    final h = _Harness();
    final response = Completer<PendingTurnActionsView>();
    h.session.pendingTurnActionsHandler = (_) => response.future;
    final first = h.navigate();
    final second = h.navigate(endWhenEmpty: true);
    await Future<void>.delayed(Duration.zero);
    h.scope++;
    response.complete(h.work(actions: []));
    await Future.wait([first, second]);
    expect(h.session.pendingTurnActionsRevisions, [0]);
    expect(h.focused, isEmpty);
    expect(h.ends, 0);
    expect(h.failures, isEmpty);
  });

  test('empty bumpers do nothing; queued Starts end the turn once', () async {
    final h = _Harness();
    h.session.pendingTurnActionsResult = h.work(actions: []);
    await h.navigate();
    expect(h.ends, 0);
    await Future.wait([
      h.navigate(endWhenEmpty: true),
      h.navigate(endWhenEmpty: true),
    ]);
    expect(h.ends, 1);
    expect(h.session.pendingTurnActionsRevisions, [0, 0]);
  });

  test('Start focuses work without ending the turn', () async {
    final h = _Harness();
    await h.navigate(endWhenEmpty: true);
    expect(h.focused, [h.unit]);
    expect(h.ends, 0);
  });

  test('inactive response cannot end a turn or focus work', () async {
    final h = _Harness();
    h.session.pendingTurnActionsResult = h.work(
      actions: [],
      canActivate: false,
    );
    await h.navigate(endWhenEmpty: true);
    expect(h.ends, 0);
    expect(h.focused, isEmpty);
  });

  test(
    'query failure cancels queued Starts and a new press can retry',
    () async {
      final h = _Harness();
      h.session.pendingTurnActionsFailure = const TurnSessionException(
        code: 'offline',
        message: 'Unavailable',
      );
      await Future.wait([
        h.navigate(endWhenEmpty: true),
        h.navigate(endWhenEmpty: true),
      ]);
      expect(h.failures.single.code, 'offline');
      expect(h.ends, 0);
      expect(h.session.pendingTurnActionsRevisions, [0]);
      h.session.pendingTurnActionsFailure = null;
      await h.navigate();
      expect(h.focused, [h.unit]);
    },
  );

  test(
    'rejects incompatible actor and full stamp before ending a turn',
    () async {
      for (final work in [
        PendingTurnActionsView(
          stamp: testSessionStamp(),
          actorPlayerId: 'other',
          canActivate: true,
          actions: [],
        ),
        PendingTurnActionsView(
          stamp: testSessionStamp(stateDigest: 'd' * 64),
          actorPlayerId: 'preview-player',
          canActivate: true,
          actions: [],
        ),
      ]) {
        final h = _Harness();
        h.session.pendingTurnActionsResult = work;
        await h.navigate(endWhenEmpty: true);
        expect(h.failures.single.code, 'invalid_session_protocol');
        expect(h.ends, 0);
      }
    },
  );

  test(
    'input ownership and unavailable state suppress late responses',
    () async {
      for (final loseInput in [true, false]) {
        final h = _Harness();
        final response = Completer<PendingTurnActionsView>();
        h.session.pendingTurnActionsHandler = (_) => response.future;
        final navigation = h.navigate(endWhenEmpty: true);
        await Future<void>.delayed(Duration.zero);
        if (loseInput) {
          h.available = false;
        } else {
          h.ready = false;
        }
        response.complete(h.work(actions: []));
        await navigation;
        expect(h.ends, 0);
        expect(h.failures, isEmpty);
      }
    },
  );
}

final class _Harness {
  _Harness() {
    session.pendingTurnActionsResult = work();
    navigation = PendingTurnNavigation(
      session: session,
      readState: () => ready ? state : null,
      readScope: () => scope,
      focus: focus,
      endTurn: () => ends++,
      onFailure: failures.add,
    );
  }
  final session = FakeGameSession.success(testMapScene());
  var state = GameSessionReady.initial(testMapScene());
  var scope = 0;
  var ends = 0;
  var available = true;
  var ready = true;
  final failures = <TurnSessionException>[];
  final focused = <PendingTurnActionView>[];
  final unit = const PendingUnitTurnActionView(
    unitId: 'unit',
    coordinate: (col: 0, row: 0),
  );
  final city = const PendingCityProductionTurnActionView(
    cityId: 'city',
    coordinate: (col: 1, row: 1),
  );
  final research = const PendingResearchTurnActionView();
  late final PendingTurnNavigation navigation;

  PendingTurnActionsView work({
    List<PendingTurnActionView>? actions,
    bool canActivate = true,
  }) => PendingTurnActionsView(
    stamp: state.recipient.stamp,
    actorPlayerId: state.recipient.actorPlayerId,
    canActivate: canActivate,
    actions: actions ?? [unit, city, research],
  );
  Future<void> navigate({int step = 1, bool endWhenEmpty = false}) =>
      navigation.navigate(
        step: step,
        endWhenEmpty: endWhenEmpty,
        inputAvailable: () => available,
      );

  Future<bool> focus(PendingTurnActionView action) async {
    await Future<void>.delayed(Duration.zero);
    focused.add(action);
    final interaction = state.interaction;
    state = state.withInteraction(switch (action) {
      PendingUnitTurnActionView(:final unitId) => interaction.copyWith(
        researchFocused: false,
        selectedUnitId: unitId,
        clearCity: true,
      ),
      PendingCityProductionTurnActionView(:final cityId) =>
        interaction.copyWith(
          researchFocused: false,
          clearSelectedUnit: true,
          city: CityState(cityId: cityId),
        ),
      PendingResearchTurnActionView() => interaction.copyWith(
        researchFocused: true,
      ),
    });
    scope++;
    return true;
  }
}
