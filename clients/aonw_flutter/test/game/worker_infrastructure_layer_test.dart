import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'batches connected legacy roads and joins visible city centers',
    AonwFlameGame.new,
    (game) async {
      final city = testCityView(center: (col: 2, row: 0));
      final scene = testMapScene(
        cities: [city],
        roads: const [
          RoadView(
            coordinate: (col: 0, row: 0),
            condition: TransportConditionView.operational,
          ),
          RoadView(
            coordinate: (col: 1, row: 0),
            condition: TransportConditionView.operational,
          ),
        ],
      );
      game.replaceScene(_snapshot(scene));
      await game.ready();

      final layer = game.world.workerInfrastructureLayer;
      expect(layer.debugRoadCount, 2);
      expect(layer.debugOperationalRoadCount, 2);
      expect(layer.debugRoadPathMetricCount, 2);
      expect(layer.debugCityConnectionCount, 1);
      expect(layer.debugRoadGeometryBuildCount, 1);
      expect(layer.children, isEmpty);
      expect(layer.isVisible, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'reconciles improvements and road conditions by coordinate',
    AonwFlameGame.new,
    (game) async {
      const improvement = FieldImprovementView(
        coordinate: (col: 0, row: 0),
        improvement: FieldImprovementKind.farm,
      );
      const roadCoordinate = (col: 1, row: 0);
      final initial = testMapScene(
        fieldImprovements: const [improvement],
        roads: const [
          RoadView(
            coordinate: roadCoordinate,
            condition: TransportConditionView.operational,
          ),
        ],
      );
      game.replaceScene(_snapshot(initial));
      await game.ready();
      final layer = game.world.workerInfrastructureLayer;
      final stableImprovement = layer.debugImprovementAt(
        improvement.coordinate,
      );
      expect(layer.debugOperationalRoadCount, 1);
      expect(layer.debugRoadPathMetricCount, 1);
      expect(layer.children, hasLength(1), reason: 'roads are batched');

      final pillaged = testMapScene(
        fieldImprovements: const [improvement],
        roads: const [
          RoadView(
            coordinate: roadCoordinate,
            condition: TransportConditionView.pillaged,
          ),
        ],
      );
      game.replaceScene(_snapshot(pillaged));

      expect(
        layer.debugImprovementAt(improvement.coordinate),
        same(stableImprovement),
      );
      expect(
        layer.debugRoadAt(roadCoordinate)?.condition,
        TransportConditionView.pillaged,
      );
      expect(layer.debugOperationalRoadCount, 0);
      expect(layer.debugRoadPathMetricCount, 0);
      expect(layer.debugCreatedCount, 2);
      expect(layer.debugUpdatedCount, 1);
      expect(layer.debugSharedPaintCount, 7);

      game.replaceScene(
        _snapshot(testMapScene(fieldImprovements: const [improvement])),
      );
      expect(layer.debugRoadCount, 0);
      expect(layer.debugRemovedCount, 1);
    },
  );
}

MapRenderSnapshot _snapshot(MapScene scene) => MapRenderSnapshot(
  map: scene.map,
  interaction: const MapInteractionState(),
  reference: scene.reference,
  player: scene.player,
);
