import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/unit_marker_details.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'keeps one marker while health selection and legacy status change',
    AonwFlameGame.new,
    (game) async {
      final working = testVisibleUnit(
        hitPoints: 3,
        maximumHitPoints: 10,
        posture: VisibleUnitPosture.fortified,
        carriedArtifactId: 'artifact-1',
        workerJob: const RoadConstructionJobView(
          target: (col: 0, row: 0),
          remainingTurns: 2,
          totalTurns: 3,
        ),
      );
      final scene = testMapScene(units: [working], actorColorValue: 0xff3f7a4b);
      game.replaceScene(
        _snapshot(
          scene,
          interaction: MapInteractionState(
            selected: working.coordinate,
            selectedUnitId: working.id,
          ),
        ),
      );
      await game.ready();
      final marker = game.world.unitLayer.debugComponentForUnit(working.id)!;

      expect(marker.debugOwnerColor, const Color(0xff3f7a4b));
      expect(marker.debugSelected, isTrue);
      expect(marker.debugHealthFraction, closeTo(0.3, 0.00001));
      expect(marker.debugStateBadge, MapUnitStateBadge.healing);
      expect(marker.debugWorkBadgeLabel, '2t');

      final exhausted = testVisibleUnit(
        movementUnits: 0,
        hitPoints: 10,
        maximumHitPoints: 10,
      );
      final next = testMapScene(
        units: [exhausted],
        actorColorValue: 0xff3f7a4b,
      );
      game.replaceScene(_snapshot(next));

      expect(
        game.world.unitLayer.debugComponentForUnit(working.id),
        same(marker),
      );
      expect(marker.debugSelected, isFalse);
      expect(marker.debugStateBadge, MapUnitStateBadge.exhausted);
      expect(marker.debugWorkBadgeLabel, isNull);
      expect(game.world.unitLayer.debugCreatedCount, 1);
      expect(game.world.unitLayer.debugUpdatedCount, 1);
    },
  );

  testWithGame<AonwFlameGame>(
    'places a city garrison and merchant on opposite legacy sides',
    AonwFlameGame.new,
    (game) async {
      const center = (col: 1, row: 1);
      final commander = testVisibleUnit(id: 'commander', coordinate: center);
      final merchant = testVisibleUnit(
        id: 'merchant',
        coordinate: center,
        kind: VisibleUnitKind.merchant,
      );
      final scene = testMapScene(
        units: [commander, merchant],
        cities: [testCityView(center: center)],
      );
      game.replaceScene(_snapshot(scene));
      await game.ready();

      final primary = game.world.unitLayer.debugComponentForUnit('commander')!;
      final companion = game.world.unitLayer.debugComponentForUnit('merchant')!;
      expect(primary.debugOnCity, isTrue);
      expect(companion.debugOnCity, isTrue);
      expect(primary.debugVisualCenter.dx - companion.debugVisualCenter.dx, 52);
      expect(primary.debugVisualCenter.dy, companion.debugVisualCenter.dy);
    },
  );

  testWithGame<AonwFlameGame>(
    'shows the recipient-owned skipped-turn badge',
    AonwFlameGame.new,
    (game) async {
      final unit = testVisibleUnit();
      final scene = testMapScene(
        units: [unit],
        pendingAction: PendingUnitTurnSkipView(
          unitId: unit.id,
          restoreMovementUnits: 12,
        ),
      );
      game.replaceScene(_snapshot(scene));
      await game.ready();

      expect(
        game.world.unitLayer.debugComponentForUnit(unit.id)!.debugStateBadge,
        MapUnitStateBadge.skippedTurn,
      );
    },
  );
}

MapRenderSnapshot _snapshot(
  MapScene scene, {
  MapInteractionState interaction = const MapInteractionState(),
}) => MapRenderSnapshot(
  map: scene.map,
  interaction: interaction,
  reference: scene.reference,
  player: scene.player,
);
