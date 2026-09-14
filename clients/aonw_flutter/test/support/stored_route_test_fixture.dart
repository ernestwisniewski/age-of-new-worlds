import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/map/read_model/stored_unit_route_view.dart';

import 'map_test_fixture.dart';

MapScene storedRouteScene({
  bool merchant = false,
  int current = 0,
  String owner = 'preview-player',
  List<int>? turns,
  List<int> roads = const [],
}) {
  final steps = [
    for (var index = 0; index < 8; index++)
      MovementStepView(
        coordinate: (col: index + 2, row: 2),
        enterCostUnits: index == 0 ? 0 : 8,
        cumulativeCostUnits: index * 8,
      ),
  ];
  final route = StoredUnitRouteView(
    kind: merchant ? StoredUnitRouteKind.merchant : StoredUnitRouteKind.queued,
    target: steps.last.coordinate,
    steps: steps,
    stepTurns:
        turns ??
        [
          for (var index = 0; index < steps.length; index++)
            if (index < current)
              0
            else if (index == current)
              1
            else
              2 + (index - current - 1) ~/ 2,
        ],
    roadStepIndices: roads,
    originCityId: merchant ? 'origin' : null,
    destinationCityId: merchant ? 'destination' : null,
  );
  return testMapScene(
    cols: 20,
    rows: 16,
    units: [
      VisibleUnitView(
        id: 'preview-commander',
        ownerPlayerId: owner,
        kind: VisibleUnitKind.commander,
        name: 'Commander',
        coordinate: steps[current].coordinate,
        movementUnits: 0,
        posture: VisibleUnitPosture.active,
        queuedRoute: merchant ? null : route,
        merchantRoute: merchant ? route : null,
      ),
    ],
  );
}
