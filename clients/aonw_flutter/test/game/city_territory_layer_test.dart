import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/city_territory_style.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'batches recipient-safe organic territories and selected empires',
    AonwFlameGame.new,
    (game) async {
      final selected = testCityView(
        id: 'selected-city',
        center: (col: 0, row: 0),
        visibleControlledHexes: const [(col: 1, row: 0)],
      );
      final sameEmpire = testCityView(
        id: 'same-empire-city',
        center: (col: 3, row: 0),
        visibleControlledHexes: const [(col: 3, row: 1)],
      );
      final foreign = testCityView(
        id: 'foreign-city',
        ownerPlayerId: 'foreign-player',
        center: (col: 0, row: 2),
        visibleControlledHexes: const [(col: 1, row: 2)],
        owned: false,
      );
      final scene = testMapScene(
        cols: 5,
        rows: 4,
        cities: [selected, sameEmpire, foreign],
      );
      final interaction = MapInteractionState(
        city: CityState(cityId: selected.id),
        viewMode: MapViewMode.tile,
      );
      game.replaceScene(_snapshot(scene, interaction));
      await game.ready();

      final layer = game.world.cityTerritoryLayer;
      expect(layer.debugTerritoryCount, 3);
      expect(layer.debugBoundaryMetricCount, 3);
      expect(layer.debugGeometryBuildCount, 3);
      expect(layer.debugBoundaryCacheCount, 3);
      expect(layer.debugSelectedCityId, selected.id);
      expect(layer.debugHighlightedPlayerId, selected.ownerPlayerId);
      expect(layer.debugHighlightedTerritoryCount, 2);
      expect(layer.debugStrategicView, isTrue);
      expect(layer.children, isEmpty);
      expect(layer.debugHexesForCity(selected.id), [
        selected.center,
        const (col: 1, row: 0),
      ]);

      game.replaceScene(_snapshot(scene, interaction));
      expect(layer.debugSyncCount, 1);
      expect(layer.debugGeometryBuildCount, 3);

      game.replaceScene(
        _snapshot(
          scene,
          MapInteractionState(
            city: CityState(cityId: foreign.id),
            viewMode: MapViewMode.tile,
          ),
        ),
      );
      expect(layer.debugSyncCount, 2);
      expect(layer.debugGeometryBuildCount, 3);
      expect(layer.debugSelectedCityId, foreign.id);
      expect(layer.debugHighlightedTerritoryCount, 1);

      final changed = testCityView(
        id: selected.id,
        center: selected.center,
        visibleControlledHexes: const [(col: 0, row: 1)],
      );
      final changedScene = testMapScene(
        cols: 5,
        rows: 4,
        cities: [changed, sameEmpire, foreign],
      );
      game.replaceScene(_snapshot(changedScene, interaction));

      expect(layer.debugSyncCount, 3);
      expect(layer.debugGeometryBuildCount, 4);
      expect(layer.debugBoundaryCacheCount, 3);
      expect(layer.debugHexesForCity(selected.id), [
        selected.center,
        const (col: 0, row: 1),
      ]);
    },
  );

  testWithGame<AonwFlameGame>(
    'updates a stable city marker for equal-sized territory and growth',
    AonwFlameGame.new,
    (game) async {
      final initial = testCityView(
        visibleControlledHexes: const [(col: 1, row: 0)],
      );
      final scene = testMapScene(cols: 4, rows: 3, cities: [initial]);
      game.replaceScene(_snapshot(scene, const MapInteractionState()));
      await game.ready();
      final layer = game.world.cityLayer;
      final component = layer.debugComponentForCity(initial.id)!;

      final changed = testCityView(
        visibleControlledHexes: const [(col: 2, row: 1)],
        population: 6,
      );
      final changedScene = testMapScene(cols: 4, rows: 3, cities: [changed]);
      game.replaceScene(_snapshot(changedScene, const MapInteractionState()));

      expect(layer.debugComponentForCity(initial.id), same(component));
      expect(component.debugCity.visibleControlledHexes, [(col: 2, row: 1)]);
      expect(component.debugCity.ownedDetails?.population, 6);
      expect(layer.debugUpdatedCount, 1);
    },
  );

  test('matches legacy territory zoom emphasis thresholds', () {
    final layer = AonwWorld().cityTerritoryLayer;

    expect(layer.setZoom(0.95), isFalse);
    expect(layer.debugZoomEmphasis, 0);
    expect(layer.setZoom(0.65), isTrue);
    expect(layer.debugZoomEmphasis, closeTo(0.5, 1e-9));
    expect(layer.setZoom(0.35), isTrue);
    expect(layer.debugZoomEmphasis, 1);
    expect(layer.setZoom(0.2), isFalse);
    expect(territoryEmphasizedAlpha(42, 150, 0), 42);
    expect(territoryEmphasizedAlpha(42, 150, 0.5), 96);
    expect(territoryEmphasizedAlpha(42, 150, 1), 150);
  });
}

MapRenderSnapshot _snapshot(MapScene scene, MapInteractionState interaction) =>
    MapRenderSnapshot(
      map: scene.map,
      interaction: interaction,
      reference: scene.reference,
      player: scene.player,
    );
