import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/gameplay_map_layers.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'uses selected top face and intent-specific hover markers',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(
        cols: 4,
        units: [
          testVisibleUnit(),
          testVisibleUnit(
            id: 'foreign',
            ownerPlayerId: 'foreign-player',
            coordinate: (col: 2, row: 0),
          ),
        ],
      );
      final interaction = MapInteractionState(
        selected: const (col: 0, row: 0),
        selectedUnitId: 'preview-commander',
        reachable: testReachableView(
          tiles: const [
            ReachableTileView(
              coordinate: (col: 1, row: 0),
              costUnits: 4,
              exhaustsMovement: false,
            ),
          ],
        ),
      );
      game.replaceScene(_snapshot(scene, interaction));
      await game.ready();

      final cache = game.world.debugStaticRenderCache!;
      final selectedCenter =
          game.world.selectionLayer.debugSelectionBounds!.center;
      final topFace = cache.projection.hexTopFaceCenter((col: 0, row: 0));
      expect(selectedCenter.dx, closeTo(topFace.x, 0.00001));
      expect(selectedCenter.dy, closeTo(topFace.y, 0.00001));

      game.replaceCursor((col: 1, row: 0));
      expect(
        game.world.selectionLayer.debugHoverIntent,
        MapHoverMarkerKind.move,
      );

      game.replaceCursor((col: 2, row: 0));
      expect(
        game.world.selectionLayer.debugHoverIntent,
        MapHoverMarkerKind.attack,
      );

      game.replaceCursor((col: 3, row: 0));
      expect(game.world.selectionLayer.debugHoverIntent, isNull);
      expect(
        game.world.selectionLayer.isVisible,
        isTrue,
        reason: 'the selected top face remains visible without hover intent',
      );
    },
  );

  testWithGame<AonwFlameGame>(
    'separates current and future route segments and follows public roads',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(
        cols: 4,
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
      final route = RoutePlanView(
        stamp: testSessionStamp(),
        unitId: 'preview-commander',
        target: const (col: 3, row: 0),
        destination: const (col: 3, row: 0),
        totalCostUnits: 20,
        availableMovementUnits: 8,
        remainingMovementUnits: 0,
        estimatedTurns: 2,
        steps: const [
          MovementStepView(
            coordinate: (col: 0, row: 0),
            enterCostUnits: 0,
            cumulativeCostUnits: 0,
          ),
          MovementStepView(
            coordinate: (col: 1, row: 0),
            enterCostUnits: 4,
            cumulativeCostUnits: 4,
          ),
          MovementStepView(
            coordinate: (col: 2, row: 0),
            enterCostUnits: 8,
            cumulativeCostUnits: 12,
          ),
          MovementStepView(
            coordinate: (col: 3, row: 0),
            enterCostUnits: 8,
            cumulativeCostUnits: 20,
          ),
        ],
      );
      game.replaceScene(
        _snapshot(
          scene,
          MapInteractionState(
            selected: const (col: 3, row: 0),
            selectedUnitId: 'preview-commander',
            route: route,
          ),
        ),
      );
      await game.ready();

      expect(game.world.routeLayer.debugSegmentCount, 3);
      expect(game.world.routeLayer.debugCurrentTurnSegmentCount, 1);
      expect(game.world.routeLayer.debugFutureTurnSegmentCount, 2);
      expect(game.world.routeLayer.debugBoundaryCount, 1);
      expect(game.world.routeLayer.debugSegmentFollowsRoad(0), isTrue);
      expect(game.world.routeLayer.debugSegmentFollowsRoad(1), isFalse);
      expect(game.world.routeLayer.debugSegmentBounds(0).width, greaterThan(0));
    },
  );
}

MapRenderSnapshot _snapshot(MapScene scene, MapInteractionState interaction) =>
    MapRenderSnapshot(
      map: scene.map,
      interaction: interaction,
      reference: scene.reference,
      player: scene.player,
    );
