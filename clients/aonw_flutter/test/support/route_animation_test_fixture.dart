import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';

import 'map_test_fixture.dart';

MapRenderSnapshot routeAnimationSnapshot({
  bool reverse = false,
  bool showRoute = true,
  bool roads = true,
  String? mapId,
}) {
  const coordinates = [(col: 2, row: 2), (col: 3, row: 2), (col: 4, row: 2)];
  final points = reverse ? coordinates.reversed.toList() : coordinates;
  final scene = testMapScene(
    cols: 20,
    rows: 16,
    mapId: mapId,
    units: [testVisibleUnit(coordinate: points.first)],
    roads: roads
        ? [
            for (final coordinate in points)
              RoadView(
                coordinate: coordinate,
                condition: TransportConditionView.operational,
              ),
          ]
        : const [],
  );
  return MapRenderSnapshot(
    map: scene.map,
    reference: scene.reference,
    player: scene.player,
    interaction: MapInteractionState(
      route: showRoute ? routeAnimationPlan(points) : null,
    ),
  );
}

RoutePlanView routeAnimationPlan(List<MapHexCoordinate> points) =>
    RoutePlanView(
      stamp: testSessionStamp(),
      unitId: 'preview-commander',
      target: points.last,
      destination: points.last,
      totalCostUnits: 16,
      availableMovementUnits: 8,
      remainingMovementUnits: 0,
      estimatedTurns: 2,
      steps: [
        for (var index = 0; index < points.length; index++)
          MovementStepView(
            coordinate: points[index],
            enterCostUnits: index == 0 ? 0 : 8,
            cumulativeCostUnits: index * 8,
          ),
      ],
    );
