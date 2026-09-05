import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'batches connected roads and joins visible city centers',
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
        eraColumn: 2,
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
      game.replaceScene(_snapshot(initial, selected: improvement.coordinate));
      await game.ready();
      final layer = game.world.workerInfrastructureLayer;
      final stableImprovement = layer.debugImprovementAt(
        improvement.coordinate,
      );
      expect(layer.debugOperationalRoadCount, 1);
      expect(layer.debugRoadPathMetricCount, 1);
      expect(layer.children, hasLength(1), reason: 'roads are batched');
      expect(stableImprovement?.debugEraColumn, 2);
      expect(stableImprovement?.debugSelected, isTrue);

      const modern = FieldImprovementView(
        coordinate: (col: 0, row: 0),
        improvement: FieldImprovementKind.farm,
        eraColumn: 3,
      );

      final pillaged = testMapScene(
        fieldImprovements: const [modern],
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
      expect(stableImprovement?.debugEraColumn, 3);
      expect(stableImprovement?.debugSelected, isFalse);
      expect(
        layer.debugRoadAt(roadCoordinate)?.condition,
        TransportConditionView.pillaged,
      );
      expect(layer.debugOperationalRoadCount, 0);
      expect(layer.debugRoadPathMetricCount, 0);
      expect(layer.debugCreatedCount, 2);
      expect(layer.debugUpdatedCount, 2);
      expect(layer.debugSharedPaintCount, 9);

      game.replaceScene(
        _snapshot(
          testMapScene(fieldImprovements: const [modern]),
          selected: modern.coordinate,
        ),
      );
      expect(layer.debugRoadCount, 0);
      expect(layer.debugRemovedCount, 1);
      expect(stableImprovement?.debugSelected, isTrue);
    },
  );
}

MapRenderSnapshot _snapshot(MapScene scene, {MapHexCoordinate? selected}) =>
    MapRenderSnapshot(
      map: scene.map,
      interaction: MapInteractionState(selected: selected),
      reference: scene.reference,
      player: scene.player,
    );
