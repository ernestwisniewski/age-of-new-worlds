import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWithGame<AonwFlameGame>(
    'camera clips offscreen markers without relying on a parent canvas clip',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(
        cols: 40,
        rows: 30,
        units: [
          testVisibleUnit(id: 'near'),
          testVisibleUnit(id: 'far', coordinate: (col: 39, row: 29)),
        ],
      );
      game.onGameResize(Vector2(640, 360));
      game.replaceScene(
        MapRenderSnapshot(
          map: scene.map,
          reference: scene.reference,
          player: scene.player,
          interaction: const MapInteractionState(),
        ),
      );
      await game.ready();
      final near = game.world.unitLayer.debugComponentForUnit('near')!;
      final far = game.world.unitLayer.debugComponentForUnit('far')!;
      _renderCamera(game);
      expect(near.debugPaintCount, 1);
      expect(far.debugPaintCount, 0);
      game.mapCamera.centerOnHex((col: 39, row: 29));
      game.onGameResize(Vector2(320, 240));
      _renderCamera(game);
      expect(near.debugPaintCount, 1);
      expect(far.debugPaintCount, 1);
      final viewport = game.camera.viewport;
      expect(viewport.containsLocalPoint(Vector2(319, 239)), isTrue);
      expect(viewport.containsLocalPoint(Vector2(321, 239)), isFalse);
    },
  );

  testWithGame<AonwFlameGame>(
    'culls offscreen markers while keeping badges and glow at viewport edges',
    AonwFlameGame.new,
    (game) async {
      final scene = testMapScene(
        units: [testVisibleUnit()],
        cities: [testCityView(id: 'city')],
        fieldImprovements: const [
          FieldImprovementView(
            coordinate: (col: 1, row: 0),
            improvement: FieldImprovementKind.farm,
          ),
        ],
      );
      game.replaceScene(
        MapRenderSnapshot(
          map: scene.map,
          reference: scene.reference,
          player: scene.player,
          interaction: const MapInteractionState(selected: (col: 1, row: 0)),
        ),
      );
      await game.ready();
      final unit = game.world.unitLayer.debugComponentForUnit(
        'preview-commander',
      )!;
      final city = game.world.cityLayer.debugComponentForCity('city')!;
      final improvement = game.world.workerInfrastructureLayer
          .debugImprovementAt((col: 1, row: 0))!;
      final markers = [
        (
          component: unit,
          count: () => unit.debugPaintCount,
          edge: const ui.Rect.fromLTWH(0, -64, 48, 20),
        ),
        (
          component: city,
          count: () => city.debugPaintCount,
          edge: const ui.Rect.fromLTWH(-2, 10, 2, 20),
        ),
        (
          component: improvement,
          count: () => improvement.debugPaintCount,
          edge: const ui.Rect.fromLTWH(-15, 10, 10, 20),
        ),
      ];
      for (final marker in markers) {
        final count = marker.count();
        _renderClipped(
          marker.component,
          const ui.Rect.fromLTWH(1000, 1000, 10, 10),
        );
        expect(
          marker.count(),
          count,
          reason: 'offscreen marker emits no paint',
        );
        _renderClipped(marker.component, marker.edge);
        expect(
          marker.count(),
          count + 1,
          reason: 'visuals outside the body still paint',
        );
      }
      expect(
        game.world.unitLayer.debugComponentForUnit('preview-commander'),
        same(unit),
      );
      expect(game.world.cityLayer.debugComponentForCity('city'), same(city));
      expect(
        game.world.workerInfrastructureLayer.debugImprovementAt((
          col: 1,
          row: 0,
        )),
        same(improvement),
      );
    },
  );
}

void _renderCamera(AonwFlameGame game) {
  final recorder = ui.PictureRecorder();
  game.camera.renderTree(ui.Canvas(recorder));
  recorder.endRecording().dispose();
}

void _renderClipped(Component component, ui.Rect clip) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..clipRect(clip);
  component.render(canvas);
  recorder.endRecording().dispose();
}
