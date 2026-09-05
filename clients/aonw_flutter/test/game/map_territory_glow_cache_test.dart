import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/city_territory_style.dart';
import 'package:aonw_flutter/game/map/territory_glow_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('retains strategic glow gradients across camera zooms', () async {
    final cache = MapTerritoryGlowCache();
    addTearDown(cache.clear);
    final path = ui.Path()
      ..moveTo(30, 20)
      ..lineTo(90, 20)
      ..lineTo(90, 70)
      ..lineTo(55, 50)
      ..lineTo(30, 70)
      ..close();
    final style = MapCityTerritoryStyle(
      const ui.Color(0xff009bff),
      strategicView: true,
    );
    for (final paint in [
      style.borderGlowPaint,
      style.strategicCenterGlowPaint,
    ]) {
      for (final zoom in [0.2, 0.5, 1.0, 2.0, 5.0]) {
        final actual = await _render(
          zoom,
          (canvas) => cache.draw(canvas, path, paint.color),
        );
        final expected = await _render(
          zoom,
          (canvas) => canvas.drawPath(path, paint),
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
        // Resampling only affects diffuse gradients: mean channel error < 0.3%.
        expect(total / (a.length * 255), lessThan(0.003), reason: 'zoom $zoom');
        expect(maximum, lessThanOrEqualTo(14), reason: 'zoom $zoom');

        actual.dispose();
        expected.dispose();
      }
    }
    expect(cache.debugImageCount, 2);
    expect(cache.debugBuildCount, 2);
  });

  test('bounds pixel memory and releases textures on clear', () {
    final cache = MapTerritoryGlowCache();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const color = ui.Color(0x82009bff);
    for (var i = 0; i < 20; i++) {
      cache.draw(
        canvas,
        ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 500, 500)),
        color,
      );
    }
    expect(cache.debugPixelCount, lessThanOrEqualTo(2 * 1024 * 1024));
    expect(cache.debugImageCount, inInclusiveRange(1, 19));
    final retainedPixels = cache.debugPixelCount;
    cache.draw(
      canvas,
      ui.Path()..addRect(const ui.Rect.fromLTWH(0, 0, 5000, 5000)),
      color,
    );
    expect(cache.debugPixelCount, retainedPixels);
    recorder.endRecording().dispose();
    cache.clear();
    expect(cache.debugImageCount, 0);
    expect(cache.debugPixelCount, 0);
  });
}

Future<ui.Image> _render(double zoom, void Function(ui.Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff808080), ui.BlendMode.src)
    ..scale(zoom)
    ..translate(0.3, 0.7);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (120 * zoom).toInt(),
    (100 * zoom).toInt(),
  );
  picture.dispose();
  return image;
}
