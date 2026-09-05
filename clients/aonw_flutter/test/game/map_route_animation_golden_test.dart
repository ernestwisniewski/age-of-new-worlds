import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_route_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/route_animation_test_fixture.dart';

void main() {
  testWidgets(
    'renders straight and curved route ghosts across six walk frames',
    (tester) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xff20313e), ui.BlendMode.src);
      for (var row = 0; row < 2; row++) {
        final snapshot = routeAnimationSnapshot(
          reverse: row == 1,
          roads: row == 0,
        );
        final layer = MapRouteLayerComponent();
        await tester.runAsync(() async {
          layer.applyRoute(
            MapStaticRenderCache.build(snapshot.map),
            snapshot.interaction.route,
            snapshot.player,
          );
          await layer.debugLoadGhost();
        });
        layer.applyViewport(const ui.Rect.fromLTWH(0, 0, 1000, 1000));
        layer.setViewportActive(true);
        for (var column = 0; column < 6; column++) {
          canvas.save();
          canvas.translate(column * 320.0, row * 170.0);
          canvas.clipRect(const ui.Rect.fromLTWH(0, 0, 320, 170));
          canvas.translate(-180, -50);
          layer.render(canvas);
          canvas.restore();
          layer.update(0.14);
        }
        layer.clearLayer();
      }
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(1920, 340));
      picture.dispose();
      await expectLater(
        image!,
        matchesGoldenFile('goldens/map_route_animation.png'),
      );
      image.dispose();
    },
  );
}
