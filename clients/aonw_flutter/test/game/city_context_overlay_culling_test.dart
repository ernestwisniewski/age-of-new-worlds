import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'city_context_overlay_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Bold.ttf'))).load();
  });
  testWidgets('city context overlays retain fills, badges and dashes', (
    tester,
  ) async {
    final layers = [
      managementOverlay(),
      managementOverlay(expansion: true),
      managementOverlay(expansion: true, pending: true),
      foundingOverlay()..update(0.5),
      managementOverlay(expansion: true, largeYield: true),
    ];
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff24262b), ui.BlendMode.src);
    for (var i = 0; i < layers.length; i++) {
      canvas
        ..save()
        ..translate((i % 2) * 600.0, (i ~/ 2) * 400.0)
        ..scale(1.5);
      layers[i].render(canvas);
      canvas.restore();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1200, 1200);
    picture.dispose();
    try {
      await expectLater(
        image,
        matchesGoldenFile('goldens/city_context_overlays.png'),
      );
    } finally {
      image.dispose();
      for (final layer in layers) {
        layer.onRemove();
      }
    }
  });

  test('offscreen city overlays emit no paint and retain cached geometry', () {
    final management = managementOverlay(expansion: true);
    final founding = foundingOverlay();
    addTearDown(management.onRemove);
    addTearDown(founding.onRemove);
    final outside = const ui.Rect.fromLTWH(10000, 10000, 1, 1);
    _record(management.render, clip: outside).dispose();
    _record(founding.render, clip: outside).dispose();
    expect(management.debugRenderedHexCount, 0);
    expect(founding.debugRenderedHexCount, 0);
    _record(management.render).dispose();
    _record(founding.render).dispose();
    expect(management.debugRenderedHexCount, 1);
    expect(founding.debugRenderedHexCount, 4);
    expect(management.debugGeometryBuildCount, 1);
    expect(founding.debugGeometryBuildCount, 1);
    management.clearLayer();
    expect(management.debugDisposedPictureCount, 1);
    management.clearLayer();
    expect(management.debugDisposedPictureCount, 1);
    founding.clearLayer();
    expect(founding.debugRenderedHexCount, 0);
  });

  test(
    'clipped edges retain the same pixels as the complete overlay',
    () async {
      for (final layer in <Component>[
        managementOverlay(),
        managementOverlay(expansion: true),
        managementOverlay(expansion: true, pending: true),
        managementOverlay(expansion: true, largeYield: true),
        foundingOverlay()..update(0.5),
      ]) {
        final complete = _record(layer.render);
        try {
          for (final zoom in [0.25, 1.0, 3.0]) {
            for (var x = -20.0; x < 330; x += 47) {
              final clip = ui.Rect.fromLTWH(x, x / 2 - 50, 45, 70);
              final expected = await _pixels(
                (canvas) => canvas.drawPicture(complete),
                clip,
                zoom,
              );
              final actual = await _pixels(layer.render, clip, zoom);
              expect(actual, expected, reason: '$clip at $zoom');
            }
          }
        } finally {
          complete.dispose();
          layer.onRemove();
        }
      }
    },
  );
}

ui.Picture _record(void Function(ui.Canvas) draw, {ui.Rect? clip}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (clip != null) canvas.clipRect(clip, doAntiAlias: false);
  draw(canvas);
  return recorder.endRecording();
}

Future<List<int>> _pixels(
  void Function(ui.Canvas) draw,
  ui.Rect clip,
  double zoom,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..scale(zoom)
    ..translate(-clip.left, -clip.top)
    ..clipRect(clip);
  draw(canvas);
  final cropped = recorder.endRecording();
  final image = await cropped.toImage(
    (clip.width * zoom).ceil(),
    (clip.height * zoom).ceil(),
  );
  cropped.dispose();
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}
