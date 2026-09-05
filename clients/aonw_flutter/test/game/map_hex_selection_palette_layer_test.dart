import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_hex_selection_palette_intent.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_hex_selection_palette_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_hex_selection_palette_layer.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  final paletteIntents = <MapHexSelectionPaletteIntent>[];
  final hexIntents = <MapHexIntent>[];
  testWithGame<AonwFlameGame>(
    'keeps fan geometry and consumes target taps before the map',
    () => AonwFlameGame(
      onHexSelectionPaletteIntent: paletteIntents.add,
      onHexIntent: hexIntents.add,
    ),
    (game) async {
      paletteIntents.clear();
      hexIntents.clear();
      game.onGameResize(Vector2(900, 800));
      final scene = testMapScene(cols: 7, rows: 7, defaultZoom: 2);
      game.replaceScene(_snapshot(scene));
      game.setViewportActive(true);
      await game.ready();
      final viewportCenter = game.mapCamera.viewportCenter!;
      game.openHexSelectionPalette(
        _view(),
        anchorScreenPosition: (x: 0, y: viewportCenter.y),
      );

      final layer = game.world.hexSelectionPaletteLayer;
      final rects = layer.debugTargetRects;
      final center = _paletteCenter(game, _view().coordinate);
      expect(MapHexSelectionPaletteLayerComponent.extent, 276);
      expect(rects, hasLength(3));
      expect(layer.debugDirectionAngle, closeTo(0, 1e-9));
      expect(layer.debugScreenScale, closeTo(0.5, 1e-9));
      expect(rects.first.width * game.mapCamera.zoom, 48);
      expect(
        (rects.first.center.dx - center.dx) * game.mapCamera.zoom,
        closeTo(92, 1e-9),
      );
      expect(
        math.atan2(
          rects[1].center.dy - center.dy,
          rects[1].center.dx - center.dx,
        ),
        closeTo(-math.pi / 6, 1e-9),
      );

      final screen = game.mapCamera.debugTransform!.worldToScreen((
        x: rects[1].center.dx,
        y: rects[1].center.dy,
      ));
      game.handleViewportTap(Vector2(screen.x, screen.y));

      expect(paletteIntents, hasLength(1));
      expect(paletteIntents.single, isA<SelectUnitHexPaletteIntent>());
      expect(
        (paletteIntents.single as SelectUnitHexPaletteIntent).unitId,
        'unit-2',
      );
      expect(hexIntents, isEmpty);
      expect(layer.isVisible, isFalse);
    },
  );
}

MapHexSelectionPaletteView _view() => MapHexSelectionPaletteView(
  coordinate: const (col: 3, row: 3),
  targets: const [
    TerrainHexSelectionTargetView(
      coordinate: (col: 3, row: 3),
      label: 'Terrain',
      terrain: MapTerrain.plains,
    ),
    UnitHexSelectionTargetView(
      coordinate: (col: 3, row: 3),
      label: 'Warrior',
      unitId: 'unit-2',
      kind: VisibleUnitKind.warrior,
    ),
    CityHexSelectionTargetView(
      coordinate: (col: 3, row: 3),
      label: 'City',
      cityId: 'city-3',
    ),
  ],
);

MapRenderSnapshot _snapshot(MapScene scene) => MapRenderSnapshot(
  map: scene.map,
  interaction: const MapInteractionState(),
  reference: scene.reference,
  player: scene.player,
);

ui.Offset _paletteCenter(AonwFlameGame game, MapHexCoordinate coordinate) {
  final projected = game.world.debugStaticRenderCache!.projection
      .hexTopFaceCenter(coordinate);
  return ui.Offset(projected.x, projected.y);
}
