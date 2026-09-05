import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/map_era_tint_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_era_test_fixture.dart';
import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'culls map regions while preserving the continuous era gradient',
    () async {
      final cache = MapStaticRenderCache.build(
        testMapScene(cols: 40, rows: 30).map,
      );
      final layer = MapEraTintLayerComponent()
        ..applySnapshot(eraSnapshot(PlayerTechnologyEraView.foundation), cache);
      expect(layer.debugRegionCount, 20);
      expect(layer.debugRegionContourCount, lessThan(cache.tilePaths.length));
      final center = cache.projection.hexCenter((col: 8, row: 8));
      final clip = ui.Rect.fromCenter(
        center: ui.Offset(center.x, center.y),
        width: 220,
        height: 180,
      );
      final actual = await _render(clip, layer.render);
      expect(layer.debugRenderedRegionCount, inInclusiveRange(1, 4));
      final bounds = cache.clipPath.getBounds();
      final paint = ui.Paint()
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          const [
            ui.Color(0x0cf6c365),
            ui.Color(0x22f6c365),
            ui.Color(0x13f6c365),
          ],
          const [0, 0.55, 1],
        );
      final expected = await _render(
        clip,
        (canvas) => canvas.drawPath(cache.gridPath, paint),
      );
      final actualBytes = (await actual.toByteData())!.buffer.asUint8List();
      final expectedBytes = (await expected.toByteData())!.buffer.asUint8List();
      var maximumDifference = 0;
      for (var index = 0; index < actualBytes.length; index++) {
        maximumDifference = math.max(
          maximumDifference,
          (actualBytes[index] - expectedBytes[index]).abs(),
        );
      }
      // Match the map goldens' tolerance for anti-aliasing roundoff.
      expect(maximumDifference, lessThanOrEqualTo(1));
      actual.dispose();
      expected.dispose();
      final outside = await _render(
        ui.Rect.fromLTWH(-500, -500, 220, 180),
        layer.render,
      );
      expect(layer.debugRenderedRegionCount, 0);
      outside.dispose();
    },
  );
}

Future<ui.Image> _render(ui.Rect clip, void Function(ui.Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff808080), ui.BlendMode.src)
    ..translate(-clip.left, -clip.top)
    ..clipRect(clip);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(clip.width.toInt(), clip.height.toInt());
  picture.dispose();
  return image;
}
