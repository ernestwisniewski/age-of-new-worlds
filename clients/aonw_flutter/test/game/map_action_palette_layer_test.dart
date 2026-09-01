import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_action_palette_intent.dart';
import 'package:aonw_flutter/features/map/presentation/input/map_viewport_intent.dart';
import 'package:aonw_flutter/features/map/presentation/map_action_palette_view.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_action_palette_layer.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  final movePaletteIntents = <MapActionPaletteIntent>[];
  final moveHexIntents = <MapHexIntent>[];
  testWithGame<AonwFlameGame>(
    'move pill consumes map input before selecting a hex',
    () => AonwFlameGame(
      onActionPaletteIntent: movePaletteIntents.add,
      onHexIntent: moveHexIntents.add,
    ),
    (game) async {
      movePaletteIntents.clear();
      moveHexIntents.clear();
      game.onGameResize(Vector2(900, 800));
      final scene = testMapScene(cols: 7, rows: 7);
      game.replaceScene(
        MapRenderSnapshot(
          map: scene.map,
          interaction: MapInteractionState(route: testRoutePlanView()),
          reference: scene.reference,
          player: scene.player,
          actionPalette: const MapMovePreviewPillView(
            coordinate: (col: 1, row: 0),
            enabled: true,
            label: 'Confirm · 1 turn',
            warning: false,
          ),
        ),
      );
      game.setViewportActive(true);
      await game.ready();

      final bounds = game.world.actionPaletteLayer.debugBounds!;
      expect(bounds.width, inInclusiveRange(58, 172));
      expect(bounds.height, 42);
      final screen = game.mapCamera.debugTransform!.worldToScreen((
        x: bounds.center.dx,
        y: bounds.center.dy,
      ));
      game.handleViewportTap(Vector2(screen.x, screen.y));

      expect(movePaletteIntents, hasLength(1));
      expect(movePaletteIntents.single, isA<ConfirmMapMovePaletteIntent>());
      expect(moveHexIntents, isEmpty);
    },
  );

  testWithGame<AonwFlameGame>(
    'worker palette keeps legacy geometry and emits typed choices',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene();
      final view = MapWorkerActionPaletteView(
        coordinate: (col: 1, row: 0),
        enabled: true,
        unitId: 'worker-1',
        options: [
          MapWorkerImprovementOptionView(
            improvement: FieldImprovementKind.farm,
            label: 'Farm',
            turnLabel: '2 turns',
          ),
          MapWorkerImprovementOptionView(
            improvement: FieldImprovementKind.mine,
            label: 'Mine',
            turnLabel: '3 turns',
          ),
          MapWorkerImprovementOptionView(
            improvement: FieldImprovementKind.pasture,
            label: 'Pasture',
            turnLabel: '2 turns',
          ),
        ],
        previewedImprovement: FieldImprovementKind.mine,
        confirmLabel: 'Confirm improvement · Mine',
      );
      game.replaceScene(
        MapRenderSnapshot(
          map: scene.map,
          interaction: const MapInteractionState(),
          reference: scene.reference,
          player: scene.player,
          actionPalette: view,
        ),
      );
      await game.ready();

      final layer = game.world.actionPaletteLayer;
      expect(layer.debugBounds?.width, 228);
      expect(layer.debugBounds?.height, 158);
      expect(layer.debugOptionRects, hasLength(3));
      expect(
        layer.debugOptionRects.first.width,
        MapActionPaletteLayerComponent.iconSize,
      );
      expect(
        layer.debugOptionRects[1].left - layer.debugOptionRects[0].right,
        MapActionPaletteLayerComponent.iconGap,
      );
      expect(layer.debugCtaRect, isNotNull);

      final preview = layer.handleTap(
        _point(layer.debugOptionRects.last.center),
      );
      expect(preview.consumed, isTrue);
      expect(preview.intent, isA<PreviewWorkerImprovementPaletteIntent>());
      expect(
        (preview.intent! as PreviewWorkerImprovementPaletteIntent).improvement,
        FieldImprovementKind.pasture,
      );
      final confirm = layer.handleTap(_point(layer.debugCtaRect!.center));
      expect(confirm.intent, isA<ConfirmWorkerImprovementPaletteIntent>());
    },
  );
}

({double x, double y}) _point(ui.Offset point) => (x: point.dx, y: point.dy);
