import 'dart:convert';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_animation_adjustments.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_adjustment.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every authored adjustment names a packaged sprite frame', () async {
    final source =
        jsonDecode(
              await rootBundle.loadString(SpriteAnimationAdjustments.assetPath),
            )
            as Map;
    final manifest =
        jsonDecode(
              await rootBundle.loadString(
                'assets/runtime/sprites/sprite_manifest.json',
              ),
            )
            as Map;
    final frames = manifest['frames'] as Map;
    final adjustments = await SpriteAnimationAdjustments.load();
    expect(source['frames'], hasLength(300));
    for (final key in (source['frames'] as Map).keys.cast<String>()) {
      expect(frames.containsKey(key.replaceAll('|', '.')), isTrue, reason: key);
    }
    for (final key in (source['animations'] as Map).keys.cast<String>()) {
      expect(frames.containsKey('$key.0'), isTrue, reason: key);
      expect(adjustments.frameDuration(SpriteSequenceId(key), 0.9), 1.82 / 6);
    }
  });

  test('crop, expansion, scale and offset preserve atlas trimming', () async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xff112233), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    addTearDown(image.dispose);
    picture.dispose();
    final frame = SpriteFrame(
      id: const SpriteFrameId('unit.commander.walk.0'),
      image: image,
      source: const ui.Rect.fromLTWH(10, 20, 60, 70),
      originalSize: const ui.Size(100, 100),
      trimOffset: const ui.Offset(20, 10),
      pivot: const ui.Offset(50, 100),
      contentBounds: const ui.Rect.fromLTWH(20, 10, 60, 70),
      statusTop: 10,
    );
    const adjustment = SpriteFrameAdjustment(
      offset: ui.Offset(5, -3),
      crop: (left: 30, top: -10, right: -20, bottom: 20),
      scale: ui.Size(2, 1),
    );
    final result = adjustment.geometryFor(
      frame,
      baseSize: const ui.Size(100, 100),
      destination: const ui.Rect.fromLTWH(100, 200, 50, 50),
    );
    expect(result.source, const ui.Rect.fromLTWH(20, 20, 50, 70));
    expect(result.destination, const ui.Rect.fromLTWH(95, 203.5, 50, 35));
  });
}
