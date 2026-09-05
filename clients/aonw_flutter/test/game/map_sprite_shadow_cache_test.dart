import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_cinematic_projection.dart';
import 'package:aonw_flutter/game/map/map_sprite_shadow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final cinematic in [false, true]) {
    test(
      'retains two soft shadow textures at every zoom (cinematic: $cinematic)',
      () async {
        Future<ui.Image> render(double zoom, void Function(ui.Canvas) paint) =>
            _render(zoom, paint, cinematic: cinematic);
        final cache = MapSpriteShadowCache();
        addTearDown(cache.clear);
        for (final compact in [false, true]) {
          for (final zoom in [0.2, 0.5, 1.0, 2.0, 5.0]) {
            final actual = await render(
              zoom,
              (canvas) => cache.paintUnit(
                canvas,
                center: const ui.Offset(50.3, 30.7),
                compact: compact,
              ),
            );
            final expected = await render(
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
        final rebuilt = await render(
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
}

Future<ui.Image> _render(
  double zoom,
  void Function(ui.Canvas) paint, {
  required bool cinematic,
}) async {
  final projection = MapCinematicProjection()..resize(100 * zoom, 80 * zoom);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xffffffff), ui.BlendMode.src)
    ..transform(
      cinematic ? projection.matrix : (MapCinematicProjection().matrix),
    )
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
