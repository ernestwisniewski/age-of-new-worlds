import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/map/map_sprite_catalog.dart';
import 'package:aonw_flutter/game/map/map_unit_sprite_animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'idle cycles pause once and selection clears the remaining pause',
    () async {
      final sprite = MapUnitSpriteAnimation(
        kind: VisibleUnitKind.commander,
        onLoaded: () {},
        idlePauseDuration: () => 0.8,
      );
      addTearDown(sprite.dispose);
      await sprite.load();
      for (var frame = 1; frame <= 6; frame++) {
        sprite.advance(sprite.frameDuration);
        expect(sprite.index, frame % 6);
      }
      expect(sprite.idleFrameDelay, closeTo(0.8 + 1.82 / 6, 1e-9));
      sprite.advance(0.5);
      expect(sprite.index, 0);
      expect(sprite.idleFrameDelay, closeTo(0.3 + 1.82 / 6, 1e-9));
      sprite.setIdlePausesEnabled(false);
      expect(sprite.idleFrameDelay, closeTo(1.82 / 6, 1e-9));
      sprite.advance(sprite.frameDuration * 7);
      expect(sprite.index, 1);
      sprite.playWalkToward(ui.Offset.zero, const ui.Offset(1, 0));
      sprite.setIdlePausesEnabled(true);
      sprite.advance(0.14 * 7);
      expect(sprite.index, 1, reason: 'cycle pauses apply only to idle');
      sprite.playIdle();
      expect(sprite.idleFrameDelay, closeTo(1.82 / 6, 1e-9));
    },
  );

  test(
    'loads authored timing and keeps walk time across direction changes',
    () async {
      final sprite = MapUnitSpriteAnimation(
        kind: VisibleUnitKind.commander,
        onLoaded: () {},
      );
      addTearDown(sprite.dispose);
      await sprite.load();
      expect(sprite.frameDuration, 1.82 / 6);
      sprite.advance(sprite.frameDuration);
      expect(sprite.frame!.id.value, 'unit.commander.idle.1');
      sprite.playWalkToward(ui.Offset.zero, const ui.Offset(-1, 0));
      sprite.advance(0.14);
      expect(sprite.frame!.id.value, 'unit.commander.walk.1');
      expect(sprite.mirrored, isTrue);
      sprite.playWalkToward(ui.Offset.zero, const ui.Offset(0, 1));
      sprite.advance(0.14);
      expect(sprite.index, 2);
      expect(sprite.mirrored, isTrue);
      sprite.playWalkToward(ui.Offset.zero, const ui.Offset(1, 0));
      expect(sprite.index, 2);
      expect(sprite.mirrored, isFalse);
      sprite.advance(0.56);
      expect(sprite.index, 0);
      sprite.playIdle();
      expect(sprite.frame!.id.value, 'unit.commander.idle.0');
    },
  );

  test(
    'late loads cannot overwrite a replacement kind or a disposed sprite',
    () async {
      var loaded = 0;
      final sprite = MapUnitSpriteAnimation(
        kind: VisibleUnitKind.commander,
        onLoaded: () => loaded++,
      );
      final first = sprite.load();
      sprite.setKind(VisibleUnitKind.worker);
      await first;
      await sprite.load();
      expect(sprite.frame!.id.value, 'unit.worker.idle.0');
      expect(loaded, 1);
      final pending = MapUnitSpriteAnimation(
        kind: VisibleUnitKind.tank,
        onLoaded: () => loaded++,
      );
      final completion = pending.load();
      pending.dispose();
      await completion;
      expect(pending.frame, isNull);
      expect(loaded, 1);
      sprite.dispose();
    },
  );

  test('renders aligned march frames in both directions', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
    final kinds = [
      VisibleUnitKind.commander,
      VisibleUnitKind.archer,
      VisibleUnitKind.tank,
      VisibleUnitKind.worker,
    ];
    for (var row = 0; row < kinds.length; row++) {
      final sprite = MapUnitSpriteAnimation(kind: kinds[row], onLoaded: () {});
      await sprite.load();
      for (var column = 0; column < 6; column++) {
        sprite.playWalkToward(
          ui.Offset.zero,
          ui.Offset(column < 3 ? 1 : -1, 0),
        );
        sprite.paint(
          canvas,
          ui.Rect.fromCenter(
            center: ui.Offset(column * 88 + 42, row * 100 + 50),
            width: MapSpriteCatalog.unitMetrics(kinds[row]).width,
            height: MapSpriteCatalog.unitMetrics(kinds[row]).height,
          ),
        );
        sprite.advance(0.14);
      }
      sprite.dispose();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(528, 400);
    await expectLater(image, matchesGoldenFile('goldens/map_unit_march.png'));
    image.dispose();
    picture.dispose();
  });
}
