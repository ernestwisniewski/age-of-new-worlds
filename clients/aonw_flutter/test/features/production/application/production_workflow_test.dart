import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_session_port.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('loads exact options and correlates one production command', () async {
    final city = testCityView();
    final session = FakeGameSession.success(
      testMapScene(cities: [city]),
      cityInspection: testCityInspectionView(),
      productionOverviewResults: [_overview(), _overview(revision: 1)],
      productionResult: ProductionCommandResultView.accepted(
        player: _player(revision: 1, city: city),
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);

    await controller.load();
    controller.select(city.center);
    await pumpEventQueue();
    expect(session.productionOverviewCalls, 1);
    expect(
      (controller.state as GameSessionReady)
          .interaction
          .production
          ?.options
          ?.buildings
          .single
          .cost,
      15,
    );

    const action = StartBuildingActionView(
      cityId: 'preview-city',
      building: 'workshop',
    );
    controller.executeProductionAction(action);
    controller.executeProductionAction(action);
    await pumpEventQueue();

    expect(session.productionCommandCalls, 1);
    expect(session.lastProductionExpectedRevision, 0);
    expect(session.lastProductionAction, same(action));
    expect(session.productionOverviewCalls, 2);
    final ready = controller.state as GameSessionReady;
    expect(ready.recipient.stamp.revision, 1);
    expect(ready.interaction.production?.options?.stamp.revision, 1);
  });

  test('keeps a production rejection typed without client fallback', () async {
    final city = testCityView();
    final session = FakeGameSession.success(
      testMapScene(cities: [city]),
      cityInspection: testCityInspectionView(),
      productionOverviewResults: [_overview()],
      productionResult: const ProductionCommandResultView.rejected(
        rejectionCode: ProductionRejectionCodeView.buildingNotAvailable,
      ),
    );
    final controller = _controller(session);
    addTearDown(controller.dispose);

    await controller.load();
    controller.select(city.center);
    await pumpEventQueue();
    controller.executeProductionAction(
      const StartBuildingActionView(
        cityId: 'preview-city',
        building: 'workshop',
      ),
    );
    await pumpEventQueue();

    final production =
        (controller.state as GameSessionReady).interaction.production!;
    expect(production.failure?.code, ProductionFailureCode.rejected);
    expect(
      production.failure?.rejectionCode,
      ProductionRejectionCodeView.buildingNotAvailable,
    );
    expect((controller.state as GameSessionReady).recipient.stamp.revision, 0);
  });
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

ProductionOverviewFixture _overview({int revision = 0}) => (
  options: ProductionOptionsView(
    stamp: testSessionStamp(revision: revision),
    cityId: 'preview-city',
    currentTarget: revision == 0
        ? null
        : const BuildingProductionTargetView('workshop'),
    investedProduction: 0,
    productionOverflow: 1,
    buildings: const [
      ProductionOptionView(
        target: BuildingProductionTargetView('workshop'),
        cost: 15,
        blocker: null,
      ),
    ],
    units: const [],
    projects: const [],
    wonders: const [],
    specializations: const [],
  ),
  resources: StrategicResourceProjectionView(
    stamp: testSessionStamp(revision: revision),
    playerId: 'preview-player',
    output: const [],
    sources: const [],
  ),
);

PlayerMapView _player({required int revision, required CityView city}) =>
    PlayerMapView.preview(
      actorPlayerId: 'preview-player',
      stamp: testSessionStamp(revision: revision, stateDigest: 'd' * 64),
      turn: 1,
      pendingAction: null,
      units: const [],
      cities: [city],
    );
