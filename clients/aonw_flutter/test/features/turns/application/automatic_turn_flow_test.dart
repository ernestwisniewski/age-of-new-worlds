import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/settings/application/client_automation_settings.dart';
import 'package:aonw_flutter/features/turns/application/automatic_turn_flow.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
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

void main() {
  test(
    'initial enabling primes research and disabling actions leaves ending independent',
    () {
      final h = _Harness();
      expect(h.canAdvance([_research]), isTrue);
      h.flow.configure(
        const ClientAutomationSettings(advanceActions: false, endTurn: true),
      );
      expect(h.canAdvance([_research]), isFalse);
      expect(h.canAdvance([]), isTrue);
    },
  );

  test(
    'manual deselection pauses unresolved work until explicitly selected again',
    () {
      final h = _Harness();
      expect(h.canAdvance([_unit, _research]), isTrue);
      h.select(const MapInteractionState(selectedUnitId: 'unit'));
      expect(h.canAdvance([_unit, _research]), isFalse);
      h.select(const MapInteractionState());
      expect(h.canAdvance([_unit, _research]), isFalse);
      h.select(const MapInteractionState(selectedUnitId: 'unit'));
      expect(h.canAdvance([_unit, _research]), isFalse);
      h.changeRevision(1);
      expect(h.canAdvance([_research]), isTrue);
    },
  );

  test(
    'a paused target resumes only when it leaves authoritative pending work',
    () {
      final h = _Harness();
      h.canAdvance([_unit, _research]);
      h.select(const MapInteractionState(selectedUnitId: 'unit'));
      h.select(const MapInteractionState());
      expect(h.canAdvance([_unit, _research]), isFalse);
      h.changeRevision(1);
      expect(h.canAdvance([_research]), isTrue);
    },
  );

  test(
    'selecting a resolved city is distinct from completing its production decision',
    () {
      final h = _Harness();
      h.canAdvance([_unit, _research]);
      h.select(const MapInteractionState(city: CityState(cityId: 'city')));
      expect(h.canAdvance([_unit, _research]), isFalse);
      h.select(const MapInteractionState());
      h.canAdvance([_unit, _city, _research]);
      h.select(const MapInteractionState(city: CityState(cityId: 'city')));
      expect(h.canAdvance([_unit, _city, _research]), isFalse);
      h.changeRevision(1);
      expect(h.canAdvance([_unit, _research]), isTrue);
      expect(h.canAdvance([_unit, _research]), isTrue);
    },
  );

  test(
    'closing manual city management can advance an already producing city',
    () {
      final h = _Harness();
      h.canAdvance([_unit]);
      h.select(
        const MapInteractionState(
          city: CityState(
            cityId: 'city',
            managementMode: CityManagementMode.workedHexes,
          ),
        ),
      );
      expect(h.canAdvance([_unit]), isFalse);
      h.select(const MapInteractionState(city: CityState(cityId: 'city')));
      expect(h.canAdvance([_unit]), isTrue);
      expect(h.canAdvance([_city, _unit]), isFalse);
    },
  );

  test(
    'enabling actions does not replay city completion while actions were disabled',
    () {
      for (final endTurn in [false, true]) {
        final h = _Harness();
        h.canAdvance([_city, _unit]);
        h.select(const MapInteractionState(city: CityState(cityId: 'city')));
        h.flow.configure(
          ClientAutomationSettings(advanceActions: false, endTurn: endTurn),
        );
        h.changeRevision(1);
        if (endTurn) expect(h.canAdvance([_unit]), isFalse);
        h.flow.configure(ClientAutomationSettings(endTurn: endTurn));
        expect(h.canAdvance([_unit]), isFalse);
      }
    },
  );

  test('closing research at the same revision suppresses reopening', () {
    final h = _Harness();
    h.canAdvance([_research]);
    h.select(const MapInteractionState(researchFocused: true));
    h.select(const MapInteractionState());
    expect(h.canAdvance([_research]), isFalse);
    h.flow.configure(const ClientAutomationSettings(advanceActions: false));
    expect(h.canAdvance([_research]), isFalse);
    h.flow.configure(const ClientAutomationSettings());
    expect(h.canAdvance([_research]), isTrue);
  });

  test('completed research and changed pending work clear its dismissal', () {
    final h = _Harness();
    h.canAdvance([_research]);
    h.select(const MapInteractionState(researchFocused: true));
    h.select(const MapInteractionState());
    expect(h.canAdvance([_research]), isFalse);
    h.changeRevision(1);
    expect(h.canAdvance([_unit, _research]), isTrue);
    expect(h.canAdvance([_research]), isTrue);
  });

  test('a command clearing research focus is not a manual dismissal', () {
    final h = _Harness();
    h.canAdvance([_research]);
    h.select(const MapInteractionState(researchFocused: true));
    h.changeRevision(1);
    expect(h.canAdvance([_research]), isTrue);
  });

  test('session and turn changes discard paused targets and priming', () {
    for (final newSession in [true, false]) {
      final h = _Harness();
      h.canAdvance([_unit]);
      h.select(const MapInteractionState(selectedUnitId: 'unit'));
      h.select(const MapInteractionState());
      expect(h.canAdvance([_unit]), isFalse);
      if (newSession) {
        h.session = Object();
      } else {
        h.state = _state(turn: 2);
      }
      h.observe();
      expect(h.canAdvance([_research]), isFalse);
      expect(h.canAdvance([_unit]), isTrue);
    }
  });

  test(
    'enabling automatic ending clears manual pause but retains research dismissal',
    () {
      final h = _Harness();
      h.canAdvance([_unit]);
      h.select(const MapInteractionState(selectedUnitId: 'unit'));
      h.select(const MapInteractionState());
      expect(h.canAdvance([_unit]), isFalse);
      h.flow.configure(const ClientAutomationSettings(endTurn: true));
      expect(h.canAdvance([_unit]), isTrue);
      h.canAdvance([_research]);
      h.select(const MapInteractionState(researchFocused: true));
      h.select(const MapInteractionState());
      expect(h.canAdvance([_research]), isFalse);
      expect(h.canAdvance([]), isTrue);
    },
  );
}

final class _Harness {
  _Harness() {
    observe();
    flow.configure(const ClientAutomationSettings());
  }
  final flow = AutomaticTurnFlow();
  var session = Object();
  var state = _state();

  void observe() => flow.observe(state, session: session);
  void select(MapInteractionState interaction) {
    state = state.withInteraction(interaction);
    observe();
  }

  void changeRevision(int revision) {
    state = state.withRecipient(_state(revision: revision).recipient);
    observe();
  }

  bool canAdvance(List<PendingTurnActionView> actions) {
    final work = PendingTurnActionsView(
      stamp: state.recipient.stamp,
      actorPlayerId: state.recipient.actorPlayerId,
      canActivate: true,
      actions: actions,
    );
    return flow.policyFor(work, state).canAdvance(work, state);
  }
}

GameSessionReady _state({int revision = 0, int turn = 1}) {
  final scene = testMapScene();
  return GameSessionReady.initial(
    scene.withPlayer(
      PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: revision),
        turn: turn,
        pendingAction: null,
        units: [testVisibleUnit(id: 'unit')],
        cities: [testCityView(id: 'city')],
      ),
    ),
  );
}
