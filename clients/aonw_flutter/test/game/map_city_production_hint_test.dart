import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_city_production_hint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'renders owner accents rising and fading over the production period',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawColor(const ui.Color(0xff24252a), ui.BlendMode.src);
      final paint = ui.Paint()
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.1);
      for (var row = 0; row < 3; row++) {
        for (var column = 0; column < 5; column++) {
          canvas.save();
          canvas.translate(30 + column * 80.0, 25 + row * 95.0);
          canvas.scale(2);
          final hint = MapCityProductionHint(
            const ui.Offset(0, 40),
            [0xff68a7e8, 0xffc45e63, 0xff74b47c][row],
            0,
          );
          final now = 2 + column * 0.275;
          hint.advance(now);
          final drawn = hint.render(canvas, now, paint);
          expect(drawn, column < 4);
          canvas.restore();
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 285);
      picture.dispose();
      await expectLater(
        image,
        matchesGoldenFile('goldens/map_city_production_hints.png'),
      );
      image.dispose();
    },
  );

  test('culls outside the visible canvas and skips missed whole periods', () {
    final hint = MapCityProductionHint(
      const ui.Offset(100, 100),
      0xff68a7e8,
      0,
    );
    expect(hint.activeAt(1.999), isFalse);
    hint.advance(10.5);
    expect(hint.nextEmission, 12);
    expect(hint.activeAt(10.5), isTrue);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..clipRect(const ui.Rect.fromLTWH(0, 0, 20, 20));
    expect(hint.render(canvas, 10.5, ui.Paint()), isFalse);
    recorder.endRecording().dispose();
    expect(hint.activeAt(11.101), isFalse);
  });
}
