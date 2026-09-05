import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'reconciles stable unit IDs and keeps shared render resources',
    AonwFlameGame.new,
    (game) async {
      final stable = testVisibleUnit(id: 'stable');
      final changing = testVisibleUnit(
        id: 'changing',
        coordinate: (col: 1, row: 0),
      );
      final scene = testMapScene(units: [stable, changing]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final stableComponent = game.world.unitLayer.debugComponentForUnit(
        'stable',
      );
      final changingComponent = game.world.unitLayer.debugComponentForUnit(
        'changing',
      );

      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            units: [
              stable,
              testVisibleUnit(
                id: 'changing',
                coordinate: (col: 1, row: 0),
                movementUnits: 8,
              ),
            ],
          ),
          interaction: MapInteractionState(
            selected: (col: 1, row: 0),
            selectedUnitId: 'changing',
            reachable: testReachableView(unitId: 'changing'),
            route: testRoutePlanView(unitId: 'changing'),
          ),
        ),
      );

      expect(
        game.world.unitLayer.debugComponentForUnit('stable'),
        same(stableComponent),
      );
      expect(
        game.world.unitLayer.debugComponentForUnit('changing'),
        same(changingComponent),
      );
      expect(game.world.unitLayer.debugCreatedCount, 2);
      expect(game.world.unitLayer.debugUpdatedCount, 1);
      expect(game.world.unitLayer.debugSharedPaintCount, 8);
      expect(game.world.routeLayer.debugPathBuildCount, 1);
      expect(game.world.selectionLayer.debugUpdateCount, 2);
    },
  );

  testWithGame<AonwFlameGame>(
    'updates the cursor without diffing or publishing the scene',
    AonwFlameGame.new,
    (game) async {
      final units = [
        for (var index = 0; index < 500; index += 1)
          testVisibleUnit(id: 'unit-$index'),
      ];
      final scene = testMapScene(units: units);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final sceneWrites = game.world.debugSceneWriteCount;
      final unitUpdates = game.world.unitLayer.debugUpdatedCount;
      final selectionUpdates = game.world.selectionLayer.debugUpdateCount;
      final cursorUpdates = game.world.selectionLayer.debugCursorUpdateCount;

      game.replaceCursor((col: 1, row: 0));

      expect(game.world.debugSceneWriteCount, sceneWrites);
      expect(game.world.unitLayer.debugUpdatedCount, unitUpdates);
      expect(game.world.selectionLayer.debugUpdateCount, selectionUpdates);
      expect(
        game.world.selectionLayer.debugCursorUpdateCount,
        cursorUpdates + 1,
      );
      expect(game.world.selectionLayer.isVisible, isFalse);

      game.replaceCursor((col: 1, row: 0));
      expect(
        game.world.selectionLayer.debugCursorUpdateCount,
        cursorUpdates + 1,
      );
    },
  );

  testWithGame<AonwFlameGame>(
    'animates an accepted authoritative endpoint without emitting input',
    () {
      final intents = <Object>[];
      return AonwFlameGame(onHexIntent: intents.add)
        ..add(_IntentProbe(intents));
    },
    (game) async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      game.replaceScene(
        _snapshot(
          scene,
          player: scene.player,
          interaction: MapInteractionState(
            selected: (col: 0, row: 0),
            selectedUnitId: 'preview-commander',
            route: testRoutePlanView(),
            movementPending: true,
          ),
        ),
      );
      await game.ready();
      final unit = game.world.unitLayer.debugComponentForUnit(
        'preview-commander',
      )!;
      final start = unit.debugVisualCenter;

      game.setViewportActive(true);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
          interaction: const MapInteractionState(selected: (col: 1, row: 0)),
        ),
      );

      expect(game.world.effectHost.debugActiveEffectCount, 1);
      expect(game.debugEffectsActive, isTrue);
      expect(game.paused, isFalse);
      expect(unit.debugVisualCenter, start);

      game.world.effectHost.update(0.12);
      expect(unit.debugVisualCenter, isNot(start));
      game.world.effectHost.update(0.12);

      expect(game.world.effectHost.debugActiveEffectCount, 0);
      expect(game.world.effectHost.debugCompletedMovementCount, 1);
      expect(game.debugEffectsActive, isFalse);
      expect(game.paused, isTrue, reason: 'the world returns to idle');
      final expected = game.world.unitLayer.centerFor(
        game.world.debugStaticRenderCache!,
        (col: 1, row: 0),
      );
      expect(unit.debugVisualCenter.dx, closeTo(expected.dx, 0.00001));
      expect(unit.debugVisualCenter.dy, closeTo(expected.dy, 0.00001));
      final idleUpdateCount = game.world.effectHost.debugActiveUpdateCount;
      game.world.effectHost.update(1);
      expect(game.world.effectHost.debugActiveUpdateCount, idleUpdateCount);
      expect(game.children.whereType<_IntentProbe>().single.intents, isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'skip reduced motion and speed only alter presentation effects',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(units: [testVisibleUnit()]);
      game.replaceScene(
        _snapshot(
          scene,
          player: scene.player,
          interaction: const MapInteractionState(
            selectedUnitId: 'preview-commander',
            movementPending: true,
          ),
        ),
      );
      await game.ready();
      game.setEffectPlaybackSpeed(4);
      expect(game.world.effectHost.debugPlaybackSpeed, 4);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
        ),
      );
      expect(game.world.effectHost.debugActiveEffectCount, 1);
      game.skipEffects();
      expect(game.world.effectHost.debugActiveEffectCount, 0);

      game.setReducedMotion(true);
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 1,
            digest: 'd' * 64,
            units: [testVisibleUnit(coordinate: (col: 1, row: 0))],
          ),
          interaction: const MapInteractionState(
            selectedUnitId: 'preview-commander',
            movementPending: true,
          ),
        ),
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            revision: 2,
            digest: 'e' * 64,
            units: [testVisibleUnit(coordinate: (col: 2, row: 0))],
          ),
        ),
      );
      expect(game.world.effectHost.debugActiveEffectCount, 0);
      expect(game.world.effectHost.debugCompletedMovementCount, 2);
    },
  );

  testWithGame<AonwFlameGame>(
    '40 by 30 workload remains indexed by units rather than map cells',
    AonwFlameGame.new,
    (game) async {
      final units = [
        for (var index = 0; index < 120; index++)
          testVisibleUnit(
            id: 'unit-$index',
            coordinate: (col: index % 40, row: index ~/ 40),
          ),
      ];
      final scene = testMapScene(cols: 40, rows: 30, units: units);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();

      expect(game.world.unitLayer.debugUnitCount, 120);
      expect(game.world.unitLayer.children, hasLength(120));
      expect(game.world.unitLayer.debugCreatedCount, 120);
      expect(game.world.unitLayer.debugSharedPaintCount, 8);
      expect(game.world.children, hasLength(22));
    },
  );

  testWithGame<AonwFlameGame>(
    'keeps authored objective markers stable across recipient updates',
    AonwFlameGame.new,
    (game) async {
      const ruins = MapObjectiveView(
        id: 'ruins-1',
        type: MapObjectiveType.ruins,
        coordinate: (col: 1, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 3,
        goldPerTurn: 1,
      );
      const holySite = MapObjectiveView(
        id: 'holy-site-1',
        type: MapObjectiveType.holySite,
        coordinate: (col: 2, row: 1),
        requiredHoldTurns: 3,
        victoryPoints: 5,
        goldPerTurn: 0,
      );
      final scene = testMapScene(objectives: const [ruins, holySite]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final layer = game.world.objectiveLayer;
      final stable = layer.debugComponentForObjective(ruins.id);

      game.replaceScene(
        _snapshot(
          scene,
          player: _player(revision: 1, digest: 'd' * 64, units: const []),
        ),
      );

      expect(layer.debugObjectiveCount, 2);
      expect(layer.debugComponentForObjective(ruins.id), same(stable));
      expect(stable!.debugObjective, same(ruins));
      expect(layer.debugCreatedCount, 2);
      expect(layer.debugRemovedCount, 0);
      expect(layer.debugSharedPaintCount, 5);

      game.clearScene();
      game.update(0);
      expect(layer.debugObjectiveCount, 0);
      expect(layer.debugRemovedCount, 2);
      expect(layer.children, isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'reconciles stable city markers without rebuilding unchanged cities',
    AonwFlameGame.new,
    (game) async {
      final stable = testCityView(id: 'stable-city');
      final changing = testCityView(
        id: 'changing-city',
        center: (col: 2, row: 1),
      );
      final scene = testMapScene(cities: [stable, changing]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final stableComponent = game.world.cityLayer.debugComponentForCity(
        stable.id,
      );

      final changed = testCityView(
        id: changing.id,
        name: 'Changed City',
        center: changing.center,
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(units: const [], cities: [stable, changed]),
        ),
      );

      expect(
        game.world.cityLayer.debugComponentForCity(stable.id),
        same(stableComponent),
      );
      expect(game.world.cityLayer.debugCityCount, 2);
      expect(game.world.cityLayer.debugCreatedCount, 2);
      expect(game.world.cityLayer.debugUpdatedCount, 1);
      expect(game.world.cityLayer.debugSharedPaintCount, 5);
    },
  );

  testWithGame<AonwFlameGame>(
    'reconciles artifact markers across map excavation and carrying',
    AonwFlameGame.new,
    (game) async {
      const artifactId = 'artifact-crown';
      const coordinate = (col: 0, row: 0);
      final unit = testVisibleUnit();
      const onMap = WorldArtifactView(
        id: artifactId,
        kind: WorldArtifactKindView.ancientImperialCrown,
        location: MapArtifactLocationView(coordinate),
      );
      final scene = testMapScene(units: [unit], artifacts: const [onMap]);
      game.replaceScene(_snapshot(scene, player: scene.player));
      await game.ready();
      final stable = game.world.artifactLayer.debugComponentForArtifact(
        artifactId,
      );

      const excavation = WorldArtifactView(
        id: artifactId,
        kind: WorldArtifactKindView.ancientImperialCrown,
        location: ExcavationArtifactLocationView(
          unitId: 'preview-commander',
          coordinate: coordinate,
          remainingTurns: 2,
        ),
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            units: [testVisibleUnit(excavatingArtifactId: artifactId)],
            artifacts: const [excavation],
          ),
        ),
      );

      expect(
        game.world.artifactLayer.debugComponentForArtifact(artifactId),
        same(stable),
      );
      expect(
        stable!.debugArtifact.location,
        isA<ExcavationArtifactLocationView>(),
      );
      expect(game.world.artifactLayer.debugCreatedCount, 1);
      expect(game.world.artifactLayer.debugUpdatedCount, 1);
      expect(game.world.artifactLayer.debugSharedPaintCount, 3);

      const carried = WorldArtifactView(
        id: artifactId,
        kind: WorldArtifactKindView.ancientImperialCrown,
        location: CarriedArtifactLocationView('preview-commander'),
      );
      game.replaceScene(
        _snapshot(
          scene,
          player: _player(
            units: [testVisibleUnit(carriedArtifactId: artifactId)],
            artifacts: const [carried],
          ),
        ),
      );

      expect(game.world.artifactLayer.debugArtifactCount, 0);
      expect(game.world.artifactLayer.debugRemovedCount, 1);
      game.update(0);
      expect(game.world.artifactLayer.children, isEmpty);
    },
  );
}

final class _IntentProbe extends PositionComponent {
  _IntentProbe(this.intents);

  final List<Object> intents;
}

MapRenderSnapshot _snapshot(
  MapScene scene, {
  required PlayerMapView player,
  MapInteractionState interaction = const MapInteractionState(),
}) => MapRenderSnapshot(
  map: scene.map,
  interaction: interaction,
  reference: scene.reference,
  player: player,
);

PlayerMapView _player({
  int revision = 0,
  String? digest,
  required List<VisibleUnitView> units,
  List<CityView> cities = const [],
  List<WorldArtifactView> artifacts = const [],
  List<FieldImprovementView> fieldImprovements = const [],
  List<RoadView> roads = const [],
}) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: SessionStampView(
    revision: revision,
    stateDigest: digest ?? 'b' * 64,
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  turn: 1,
  pendingAction: null,
  units: units,
  cities: cities,
  artifacts: artifacts,
  fieldImprovements: fieldImprovements,
  roads: roads,
);
