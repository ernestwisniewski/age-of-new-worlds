import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:aonw_flutter/features/turns/read_model/recipient_turn_view.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final finished in [false, true]) {
    test(
      'viewer retains queries without targeting (finished: $finished)',
      () async {
        final scene = testMapScene(
          outcome: finished
              ? GameOutcomeView(
                  condition: GameOutcomeConditionView.score,
                  winnerPlayerId: 'player-1',
                  scoreByPlayerId: const {},
                )
              : null,
          units: [testVisibleUnit(id: 'worker', kind: VisibleUnitKind.worker)],
          cities: [testCityView(id: 'city')],
        );
        final session = FakeGameSession.success(scene);
        final capabilities = testGameSessionCapabilities(
          session,
        ).forViewer(map: session);
        final coordinator = MapCoordinator(capabilities: capabilities);
        addTearDown(coordinator.dispose);
        await coordinator.load();
        expect(coordinator.readOnly, isTrue);
        expect(capabilities.localGame, isNull);
        expect(capabilities.networkGame, isNull);
        expect(capabilities.save, isNull);
        coordinator.selectUnit('worker');
        await Future<void>.delayed(Duration.zero);
        final selected = coordinator.state as GameSessionReady;
        expect(selected.interaction.selectedUnitId, 'worker');
        expect(selected.interaction.moveTargeting, isFalse);
        expect(session.logisticsOptionCalls, 1);
        expect(session.workerOptionCalls, 1);
        coordinator.toggleMoveTargeting();
        expect(coordinator.canToggleMoveTargeting, isFalse);
        coordinator.cancelInteraction();
        expect(
          (coordinator.state as GameSessionReady).interaction.selectedUnitId,
          isNull,
        );
        coordinator.selectCity('city');
        await Future<void>.delayed(Duration.zero);
        expect(session.cityInspectionCalls, greaterThan(0));
        expect(session.productionOverviewCalls, greaterThan(0));
      },
    );
  }

  test(
    'viewer blocks gameplay commands before reaching session ports',
    () async {
      final session = FakeGameSession.success(testMapScene());
      final coordinator = MapCoordinator(
        capabilities: testGameSessionCapabilities(
          session,
        ).forViewer(map: session),
      );
      addTearDown(coordinator.dispose);
      await coordinator.load();
      coordinator.endTurn();
      coordinator.confirmMove();
      coordinator.confirmCombat();
      coordinator.openCityFounding();
      coordinator.confirmCityFounding();
      coordinator.executeCityAction(
        const ToggleWorkedHexActionView(
          cityId: 'city',
          target: (col: 1, row: 1),
        ),
      );
      coordinator.executeProductionAction(
        const StartBuildingActionView(cityId: 'city', building: 'granary'),
      );
      coordinator.executeWorkerAction(
        const CancelWorkerJobActionView(unitId: 'worker'),
      );
      coordinator.executeUnitLogistics(
        const AutoExploreActionView(unitId: 'worker'),
      );
      coordinator.executeArtifactAction(
        const StartArtifactExcavationActionView(unitId: 'worker'),
      );
      coordinator.executeDiplomacyAction(const DeclareWarActionView('other'));
      coordinator.executeUnitAction(UnitActionKindView.skip);
      coordinator.selectTechnology(TechnologyIdView.mining);
      coordinator.cancelResearchSelection();
      await Future<void>.delayed(Duration.zero);
      expect([
        session.endTurnCalls,
        session.combatAttackCalls,
        session.cityFoundingOptionCalls,
        session.cityCommandCalls,
        session.productionCommandCalls,
        session.workerCommandCalls,
        session.logisticsCommandCalls,
        session.artifactCommandCalls,
        session.diplomacyCommandCalls,
        session.unitActionCalls,
        session.researchCommandCalls,
        session.researchCancellationCalls,
      ], everyElement(0));
    },
  );
}
