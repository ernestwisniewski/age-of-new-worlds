import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_sprite_shadow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'shares two shadow textures and preserves their soft gradients at every zoom',
    () async {
      final cache = MapSpriteShadowCache();
      addTearDown(cache.clear);
      for (final compact in [false, true]) {
        for (final zoom in [0.5, 1.0, 2.0, 5.0]) {
          final actual = await _render(
            zoom,
            (canvas) => cache.paintUnit(
              canvas,
              center: const ui.Offset(50.3, 30.7),
              compact: compact,
            ),
          );
          final expected = await _render(
            zoom,
            (canvas) => MapSpriteShadow.paintUnit(
              canvas,
              center: const ui.Offset(50.3, 30.7),
              compact: compact,
            ),
          );
          final a = (await actual.toByteData())!.buffer.asUint8List();
          final b = (await expected.toByteData())!.buffer.asUint8List();
          var total = 0;
          var maximum = 0;
          for (var i = 0; i < a.length; i++) {
            final delta = (a[i] - b[i]).abs();
            total += delta;
            maximum = math.max(maximum, delta);
          }
          expect(total / a.length, lessThan(0.2));
          expect(maximum, lessThanOrEqualTo(8));
          actual.dispose();
          expected.dispose();
        }
      }
      expect(cache.debugImageCount, 2);
      cache.clear();
      expect(cache.debugImageCount, 0);
      final rebuilt = await _render(
        1,
        (canvas) => cache.paintUnit(
          canvas,
          center: const ui.Offset(50, 30),
          compact: false,
        ),
      );
      expect(cache.debugImageCount, 1);
      rebuilt.dispose();
    },
  );
}

Future<ui.Image> _render(double zoom, void Function(ui.Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xffffffff), ui.BlendMode.src)
    ..scale(zoom);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (100 * zoom).toInt(),
    (80 * zoom).toInt(),
  );
  picture.dispose();
  return image;
}
