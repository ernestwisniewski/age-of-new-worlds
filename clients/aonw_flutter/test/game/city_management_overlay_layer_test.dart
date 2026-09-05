import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/city_management_overlay_layer.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'renders recipient-safe worked and expansion hex overlays',
    AonwFlameGame.new,
    (game) async {
      final city = testCityView();
      final scene = testMapScene(cols: 4, rows: 3, cities: [city]);
      final inspection = testCityInspectionView();
      final workedState = CityState(
        cityId: city.id,
        inspection: inspection,
        managementMode: CityManagementMode.workedHexes,
      );

      game.replaceScene(_snapshot(scene, workedState));
      await game.ready();
      final layer = game.world.cityManagementOverlayLayer;

      expect(layer.priority, 55);
      expect(layer.isVisible, isTrue);
      expect(layer.debugCoordinates, const [(col: 1, row: 0)]);
      expect(layer.debugKinds, const [MapCityManagementHexKind.workedAuto]);
      expect(layer.debugTileYields, const [null]);
      expect(layer.debugGeometryBuildCount, 1);

      game.replaceScene(_snapshot(scene, workedState));
      expect(layer.debugGeometryBuildCount, 1);

      final expansionState = workedState.copyWith(
        managementMode: CityManagementMode.expansion,
      );
      game.replaceScene(_snapshot(scene, expansionState));
      expect(layer.debugCoordinates, const [(col: 2, row: 1)]);
      expect(layer.debugKinds, const [
        MapCityManagementHexKind.growthRecommended,
      ]);
      expect(layer.debugTileYields.single?.food, 2);
      expect(layer.debugTileYields.single?.production, 1);
      expect(layer.debugGeometryBuildCount, 2);

      final pendingState = expansionState.copyWith(
        inFlightAction: const SelectCityExpansionActionView(
          cityId: 'preview-city',
          target: (col: 2, row: 1),
        ),
      );
      game.replaceScene(_snapshot(scene, pendingState));
      expect(layer.debugDimmed, isTrue);

      final hiddenPlayer = _withFog(
        scene.player,
        MapFogView(
          enabled: true,
          discoveredHexes: const [],
          visibleHexes: const [],
        ),
      );
      game.replaceScene(_snapshot(scene, expansionState, player: hiddenPlayer));
      expect(layer.isVisible, isFalse);
      expect(layer.debugHexCount, 0);
    },
  );
}

MapRenderSnapshot _snapshot(
  MapScene scene,
  CityState city, {
  PlayerMapView? player,
}) => MapRenderSnapshot(
  map: scene.map,
  interaction: MapInteractionState(
    selected: const (col: 1, row: 1),
    city: city,
  ),
  reference: scene.reference,
  player: player ?? scene.player,
);

PlayerMapView _withFog(PlayerMapView source, MapFogView fog) => PlayerMapView(
  actorPlayerId: source.actorPlayerId,
  stamp: source.stamp,
  turnMode: source.turnMode,
  participants: source.participants,
  fog: fog,
  economy: source.economy,
  research: source.research,
  victory: source.victory,
  turnView: source.turnView,
  diplomacy: source.diplomacy,
  units: source.units,
  cities: source.cities,
  artifacts: source.artifacts,
  fieldImprovements: source.fieldImprovements,
  roads: source.roads,
  cityFoundingDraft: source.cityFoundingDraft,
);
