import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'loads exact city inspection and correlates one worked-hex command',
    () async {
      final city = testCityView();
      final session = FakeGameSession.success(
        testMapScene(cities: [city]),
        cityInspection: testCityInspectionView(),
        cityResult: CityCommandResultView.accepted(
          player: _player(revision: 1, cities: [city]),
        ),
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);

      await controller.load();
      controller.select(city.center);
      await pumpEventQueue();
      expect(session.cityInspectionCalls, 1);
      final inspection =
          (controller.state as GameSessionReady).interaction.city?.inspection;
      expect(inspection?.cityYield.total.food, 2);

      const action = ToggleWorkedHexActionView(
        cityId: 'preview-city',
        target: (col: 1, row: 0),
      );
      controller.executeCityAction(action);
      controller.executeCityAction(action);
      await pumpEventQueue();

      expect(session.cityCommandCalls, 1);
      expect(session.lastCityAction, same(action));
      expect(
        (controller.state as GameSessionReady).recipient.stamp.revision,
        1,
      );
    },
  );

  test(
    'keeps founding selection local and submits exact engine options once',
    () async {
      final unit = testVisibleUnit();
      final session = FakeGameSession.success(
        testMapScene(units: [unit]),
        reachableResult: testReachableView(),
        cityFoundingOptionsResult: testCityFoundingOptionsView(),
        cityResult: CityCommandResultView.accepted(
          player: _player(revision: 1, cities: const []),
        ),
      );
      final controller = _controller(session);
      addTearDown(controller.dispose);

      await controller.load();
      controller.select(unit.coordinate);
      await pumpEventQueue();
      controller.openCityFounding();
      await pumpEventQueue();
      expect(session.cityFoundingOptionCalls, 1);

      controller.toggleCityFoundingHex(const (col: 1, row: 0));
      controller.confirmCityFounding();
      controller.confirmCityFounding();
      await pumpEventQueue();

      expect(session.cityCommandCalls, 1);
      final action = session.lastCityAction as FoundCityActionView;
      expect(action.controlledHexes, const [(col: 1, row: 0)]);
      expect(
        (controller.state as GameSessionReady).interaction.selected,
        isNull,
      );
    },
  );
}

MapCoordinator _controller(FakeGameSession session) =>
    MapCoordinator(capabilities: testGameSessionCapabilities(session));

PlayerMapView _player({
  required int revision,
  required List<CityView> cities,
}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: testSessionStamp(revision: revision, stateDigest: 'd' * 64),
  turn: 1,
  pendingAction: null,
  units: const [],
  cities: cities,
);
