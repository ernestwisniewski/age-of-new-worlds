import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/presentation/map_palette.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view_mode.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'terrain culling retains pixels across region boundaries and zoom levels',
    () async {
      final source = testMapScene(cols: 40, rows: 30).map;
      for (final map in [source, _uniform(source)]) {
        final cache = MapStaticRenderCache.build(map);
        final layer = MapTerrainLayerComponent()
          ..applyCache(cache)
          ..setViewMode(MapViewMode.tile);
        const center = (x: 512.0, y: 512.0);
        for (final zoom in [0.2, 0.5, 1.0, 2.75, 5.0]) {
          final clip = ui.Rect.fromCenter(
            center: ui.Offset(center.x + 0.3, center.y + 0.7),
            width: 240 / zoom,
            height: 180 / zoom,
          );
          final actual = await _render(clip, zoom, layer.render);
          expect(layer.debugRenderedRegionCount, inInclusiveRange(1, 16));
          final expected = await _render(clip, zoom, (canvas) {
            for (final entry in cache.terrainPaths.entries) {
              canvas.drawPath(
                entry.value,
                ui.Paint()..color = MapPalette.terrain(entry.key),
              );
            }
          });
          final a = (await actual.toByteData())!.buffer.asUint8List();
          final b = (await expected.toByteData())!.buffer.asUint8List();
          var maximumDifference = 0;
          var totalDifference = 0;
          var changed = 0;
          for (var i = 0; i < a.length; i++) {
            totalDifference += (a[i] - b[i]).abs();
            if ((a[i] - b[i]).abs() > 1) changed++;
            maximumDifference = math.max(
              maximumDifference,
              (a[i] - b[i]).abs(),
            );
          }
          // Path tessellation rounds coverage at edges differently after batching.
          // Keep mean channel error below 0.004% and limit larger differences
          // to fewer than 0.15% of channels, including at minimum zoom.
          expect(totalDifference / a.length, lessThan(0.01));
          expect(changed / a.length, lessThan(0.0015));
          expect(maximumDifference, lessThanOrEqualTo(26));
          actual.dispose();
          expected.dispose();
        }
        final outside = await _render(
          const ui.Rect.fromLTWH(-500, -500, 240, 180),
          1,
          layer.render,
        );
        expect(layer.debugRenderedRegionCount, 0);
        outside.dispose();
      }
    },
  );
}

Future<ui.Image> _render(
  ui.Rect clip,
  double zoom,
  void Function(ui.Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff808080), ui.BlendMode.src)
    ..scale(zoom)
    ..translate(-clip.left, -clip.top)
    ..clipRect(clip);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(240, 180);
  picture.dispose();
  return image;
}

MapView _uniform(MapView map) => MapView(
  mapId: map.mapId,
  contentHash: map.contentHash,
  gridLayout: map.gridLayout,
  cols: map.cols,
  rows: map.rows,
  defaultZoom: map.defaultZoom,
  objectives: map.objectives,
  tiles: [
    for (final tile in map.tiles)
      MapTileView(
        coordinate: tile.coordinate,
        displayTerrain: MapTerrain.values.first,
        yieldTerrain: tile.yieldTerrain,
        movementTerrains: tile.movementTerrains,
        terrainTags: tile.terrainTags,
        resources: tile.resources,
        height: tile.height,
      ),
  ],
);
