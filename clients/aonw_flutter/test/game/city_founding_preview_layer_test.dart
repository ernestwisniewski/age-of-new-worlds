import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'renders the animated recipient-safe founding preview',
    AonwFlameGame.new,
    (game) async {
      final founder = testVisibleUnit(kind: VisibleUnitKind.settler);
      final scene = testMapScene(
        cols: 4,
        rows: 3,
        units: [founder],
        actorColorValue: 0xff315f9c,
      );
      final options = CityFoundingOptionsView(
        stamp: scene.player.stamp,
        founderUnitId: founder.id,
        center: founder.coordinate,
        selectedControlledHexes: const [],
        availableControlledHexes: const [
          (col: 1, row: 0),
          (col: 0, row: 1),
          (col: 1, row: 1),
        ],
        rankedAvailableControlledHexes: const [
          (col: 1, row: 1),
          (col: 0, row: 1),
          (col: 1, row: 0),
        ],
        requiredControlledHexes: 2,
        maximumRadius: 2,
      );
      final city = CityState(
        founderUnitId: founder.id,
        foundingOptions: options,
        foundingSelection: const [(col: 1, row: 0)],
      );

      game.replaceScene(_snapshot(scene, city));
      await game.ready();
      final layer = game.world.cityFoundingPreviewLayer;

      expect(layer.priority, 55);
      expect(layer.isVisible, isTrue);
      expect(layer.debugSelectedCoordinates, const [(col: 1, row: 0)]);
      expect(layer.debugCandidateCoordinates, const [
        (col: 1, row: 1),
        (col: 0, row: 1),
      ]);
      expect(layer.debugRecommendedCount, 1);
      expect(layer.debugLabel, '1/2');
      expect(layer.debugGeometryBuildCount, 1);

      game.setViewportActive(true);
      expect(game.paused, isFalse);
      layer.update(0.5);
      expect(layer.debugDashPhase, 11);

      game.replaceScene(
        _snapshot(
          scene,
          city.copyWith(
            foundingSelection: const [(col: 1, row: 0), (col: 0, row: 1)],
          ),
        ),
      );
      expect(layer.debugSelectedCount, 2);
      expect(layer.debugRecommendedCount, 0);
      expect(layer.debugLabel, '2/2');
      expect(layer.debugGeometryBuildCount, 2);

      game.replaceScene(_snapshot(scene, null));
      expect(layer.isVisible, isFalse);
      expect(game.paused, isTrue);
    },
  );
}

MapRenderSnapshot _snapshot(MapScene scene, CityState? city) =>
    MapRenderSnapshot(
      map: scene.map,
      interaction: MapInteractionState(
        selected: const (col: 0, row: 0),
        selectedUnitId: 'preview-commander',
        city: city,
      ),
      reference: scene.reference,
      player: scene.player,
    );
