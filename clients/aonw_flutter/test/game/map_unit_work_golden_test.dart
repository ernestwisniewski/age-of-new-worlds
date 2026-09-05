import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/map_sprite_catalog.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders authored work frames for every civilian sprite', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
    const kinds = [
      VisibleUnitKind.worker,
      VisibleUnitKind.settler,
      VisibleUnitKind.merchant,
    ];
    for (var row = 0; row < kinds.length; row++) {
      final sprite = MapUnitSpriteAnimation(kind: kinds[row], onLoaded: () {});
      await sprite.load();
      final metrics = MapSpriteCatalog.unitMetrics(kinds[row]);
      sprite.playWork();
      expect(sprite.frameDuration, 0.22);
      for (var column = 0; column < 6; column++) {
        expect(sprite.index, column);
        sprite.paint(
          canvas,
          ui.Rect.fromCenter(
            center: ui.Offset(column * 70 + 35, row * 80 + 40),
            width: metrics.width * 0.72,
            height: metrics.height * 0.72,
          ),
        );
        sprite.advance(0.22);
      }
      expect(sprite.index, 0);
      sprite.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(420, 240);
    await expectLater(image, matchesGoldenFile('goldens/map_unit_work.png'));
    image.dispose();
    picture.dispose();
  });
}
