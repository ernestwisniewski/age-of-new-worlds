import 'dart:ui' as ui;

import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/game/map/city_territory_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'culls distant territories while preserving edge glow and selection dimming',
    () async {
      final scene = testMapScene(
        cols: 20,
        rows: 20,
        cities: [
          testCityView(id: 'near', center: (col: 2, row: 2)),
          testCityView(id: 'far', center: (col: 15, row: 15)),
        ],
      );
      final cache = MapStaticRenderCache.build(scene.map);
      final center = cache.projection.hexTopFaceCenter((col: 2, row: 2));
      final clip = ui.Rect.fromCenter(
        center: ui.Offset(center.x, center.y),
        width: 200,
        height: 160,
      );
      for (final mode in MapViewMode.values) {
        final layer = MapCityTerritoryLayerComponent()
          ..applySnapshot(
            MapRenderSnapshot(
              map: scene.map,
              reference: scene.reference,
              player: scene.player,
              interaction: MapInteractionState(
                city: const CityState(cityId: 'far'),
                viewMode: mode,
              ),
            ),
            cache,
          );
        final actual = await _render(layer, clip, cull: true);
        expect(layer.debugRenderedTerritoryCount, 1);
        final expected = await _render(layer, clip, cull: false);
        expect(layer.debugRenderedTerritoryCount, 2);
        expect(
          (await actual.toByteData())!.buffer.asUint8List(),
          (await expected.toByteData())!.buffer.asUint8List(),
        );
        actual.dispose();
        expected.dispose();
        final outside = await _render(
          layer,
          const ui.Rect.fromLTWH(-500, -500, 200, 160),
          cull: true,
        );
        expect(layer.debugRenderedTerritoryCount, 0);
        outside.dispose();
      }
    },
  );
}

Future<ui.Image> _render(
  MapCityTerritoryLayerComponent layer,
  ui.Rect clip, {
  required bool cull,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff808080), ui.BlendMode.src)
    ..translate(-clip.left, -clip.top);
  if (cull) canvas.clipRect(clip);
  layer.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(200, 160);
  picture.dispose();
  return image;
}
