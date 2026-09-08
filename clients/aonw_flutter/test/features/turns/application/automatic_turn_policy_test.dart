import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/combat/application/combat_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/turns/application/automatic_turn_policy.dart';
import 'package:aonw_flutter/features/turns/application/turn_action_state.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:aonw_flutter/features/workers/application/worker_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

const _unit = PendingUnitTurnActionView(
  unitId: 'unit',
  coordinate: (col: 0, row: 0),
);
const _city = PendingCityProductionTurnActionView(
  cityId: 'city',
  coordinate: (col: 1, row: 1),
);
const _research = PendingResearchTurnActionView();
const _automatic = AutomaticTurnPolicy(primed: true, endTurn: true);

void main() {
  test('manual drafts block both action navigation and automatic end', () {
    final initial = GameSessionReady.initial(testMapScene());
    for (final interaction in [
      const MapInteractionState(moveTargeting: true),
      MapInteractionState(route: testRoutePlanView()),
      const MapInteractionState(city: CityState(founderUnitId: 'unit')),
      const MapInteractionState(
        city: CityState(
          cityId: 'city',
          managementMode: CityManagementMode.workedHexes,
        ),
      ),
      const MapInteractionState(
        city: CityState(
          cityId: 'city',
          managementMode: CityManagementMode.expansion,
        ),
      ),
      const MapInteractionState(
        worker: WorkerState(unitId: 'unit', actionsOpen: true),
      ),
      const MapInteractionState(
        worker: WorkerState(
          unitId: 'unit',
          previewedImprovement: FieldImprovementKind.farm,
        ),
      ),
      const MapInteractionState(
        combat: CombatState(
          attackerUnitId: 'unit',
          defenderCoordinate: (col: 1, row: 0),
        ),
      ),
    ]) {
      final state = initial.withInteraction(interaction);
      expect(_automatic.canAdvance(_work(state, [_unit]), state), isFalse);
      expect(_automatic.canAdvance(_work(state, []), state), isFalse);
    }
  });

  test(
    'pending manual decisions block navigation even with an empty work list',
    () {
      for (final pending in <PendingActionView>[
        const PendingCityWorkedHexSelectionView(cityId: 'city'),
        const PendingCityExpansionSelectionView(cityId: 'city'),
        const PendingWorkerActionSelectionView(
          unitId: 'unit',
          improvement: null,
        ),
        const PendingMerchantTradeRouteSelectionView(unitId: 'unit'),
        const PendingMerchantMoveToCitySelectionView(unitId: 'unit'),
        const PendingAttackTargetingView(unitId: 'unit', defender: null),
        const PendingCommanderMergeSelectionView(unitId: 'unit'),
      ]) {
        final state = GameSessionReady.initial(
          testMapScene(pendingAction: pending),
        );
        expect(_automatic.canAdvance(_work(state, [_unit]), state), isFalse);
        expect(_automatic.canAdvance(_work(state, []), state), isFalse);
      }
    },
  );

  test(
    'authoritative city founding draft blocks advancement without a local draft',
    () {
      final state = GameSessionReady.initial(
        testMapScene(
          cityFoundingDraft: CityFoundingDraftView(
            founderUnitId: 'unit',
            center: (col: 0, row: 0),
            controlledHexes: [],
          ),
        ),
      );
      expect(_automatic.canAdvance(_work(state, [_city]), state), isFalse);
      expect(_automatic.canAdvance(_work(state, []), state), isFalse);
    },
  );

  test('undoable unit skip permits the next authoritative action', () {
    final state = GameSessionReady.initial(
      testMapScene(
        pendingAction: const PendingUnitTurnSkipView(
          unitId: 'unit',
          restoreMovementUnits: 12,
        ),
      ),
    );
    expect(_automatic.canAdvance(_work(state, [_city]), state), isTrue);
    expect(_automatic.canAdvance(_work(state, []), state), isTrue);
  });

  test('canonical research must be present in work and not dismissed', () {
    final state = GameSessionReady.initial(
      testMapScene(pendingAction: const PendingResearchSelectionView()),
    );
    expect(_automatic.canAdvance(_work(state, [_research]), state), isTrue);
    expect(_automatic.canAdvance(_work(state, [_unit]), state), isFalse);
    expect(_automatic.canAdvance(_work(state, []), state), isFalse);
    expect(
      const AutomaticTurnPolicy(
        primed: true,
        researchDismissed: true,
      ).canAdvance(_work(state, [_research]), state),
      isFalse,
    );
  });

  test('paused manual target and dismissed research also prevent ending', () {
    final state = GameSessionReady.initial(testMapScene());
    for (final policy in [
      const AutomaticTurnPolicy(
        primed: true,
        endTurn: true,
        manualTargetPaused: true,
      ),
      const AutomaticTurnPolicy(
        primed: true,
        endTurn: true,
        researchDismissed: true,
      ),
    ]) {
      expect(policy.canAdvance(_work(state, [_unit]), state), isFalse);
      expect(policy.canAdvance(_work(state, []), state), isFalse);
    }
  });

  test('completed combat history permits advancement; active combat waits', () {
    final initial = GameSessionReady.initial(testMapScene());
    final completed = CombatState(
      attackerUnitId: 'unit',
      defenderCoordinate: (col: 1, row: 0),
      lastExecution: testCombatExecutionView(),
    );
    final state = initial.withInteraction(
      MapInteractionState(combat: completed),
    );
    expect(_automatic.canAdvance(_work(state, [_city]), state), isTrue);
    expect(_automatic.canAdvance(_work(state, []), state), isTrue);
    for (final combat in [
      completed.copyWith(loading: true),
      completed.copyWith(commandPending: true),
      completed.copyWith(
        failure: const CombatFailureView(CombatFailureCode.requestFailed),
      ),
    ]) {
      final busy = initial.withInteraction(MapInteractionState(combat: combat));
      expect(_automatic.canAdvance(_work(busy, []), busy), isFalse);
    }
  });

  test('selected pending work keeps its decision even when primed', () {
    final initial = GameSessionReady.initial(testMapScene());
    for (final interaction in [
      const MapInteractionState(selectedUnitId: 'unit'),
      const MapInteractionState(city: CityState(cityId: 'city')),
      const MapInteractionState(researchFocused: true),
    ]) {
      final state = initial.withInteraction(interaction);
      expect(
        _automatic.canAdvance(_work(state, [_unit, _city, _research]), state),
        isFalse,
      );
    }
  });

  test('resolved own unit can advance to research without initial priming', () {
    final initial = GameSessionReady.initial(
      testMapScene(units: [testVisibleUnit(id: 'unit')]),
    );
    final state = initial.withInteraction(
      const MapInteractionState(selectedUnitId: 'unit'),
    );
    const policy = AutomaticTurnPolicy();
    expect(policy.canAdvance(_work(initial, [_research]), initial), isFalse);
    expect(policy.canAdvance(_work(state, [_research]), state), isTrue);
    final unknown = initial.withInteraction(
      const MapInteractionState(selectedUnitId: 'unknown'),
    );
    expect(policy.canAdvance(_work(unknown, [_research]), unknown), isFalse);
  });

  test(
    'resolved city inspection waits unless its manual decision just completed',
    () {
      final state =
          GameSessionReady.initial(
            testMapScene(cities: [testCityView(id: 'city')]),
          ).withInteraction(
            const MapInteractionState(city: CityState(cityId: 'city')),
          );
      expect(_automatic.canAdvance(_work(state, [_unit]), state), isFalse);
      const completed = AutomaticTurnPolicy(resolvedCityCompleted: true);
      expect(completed.canAdvance(_work(state, [_unit]), state), isTrue);
      expect(
        completed.canAdvance(_work(state, [_city, _unit]), state),
        isFalse,
      );
      expect(_automatic.canAdvance(_work(state, []), state), isTrue);
    },
  );

  test(
    'inactive authoritative work and previous turn failures suppress automation',
    () {
      final state = GameSessionReady.initial(testMapScene());
      final inactive = PendingTurnActionsView(
        stamp: state.recipient.stamp,
        actorPlayerId: state.recipient.actorPlayerId,
        canActivate: false,
        actions: [],
      );
      expect(_automatic.canAdvance(inactive, state), isFalse);
      final failed = state.withTurnAction(
        const TurnActionState(
          failure: TurnActionFailureView.transport(
            TurnFailureViewCode.requestFailed,
          ),
        ),
      );
      expect(_automatic.canAdvance(_work(failed, []), failed), isFalse);
      expect(_automatic.canAdvance(_work(failed, [_unit]), failed), isFalse);
    },
  );
}

PendingTurnActionsView _work(
  GameSessionReady state,
  List<PendingTurnActionView> actions,
) => PendingTurnActionsView(
  stamp: state.recipient.stamp,
  actorPlayerId: state.recipient.actorPlayerId,
  canActivate: true,
  actions: actions,
);
