import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_route_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/route_animation_test_fixture.dart';
import '../support/stored_route_test_fixture.dart';

void main() {
  testWidgets('saved routes survive refresh and yield to explicit previews', (
    tester,
  ) async {
    final scene = storedRouteScene();
    final cache = MapStaticRenderCache.build(scene.map);
    final layer = MapRouteLayerComponent();
    addTearDown(layer.clearLayer);
    await tester.runAsync(() async {
      layer.applyRoute(
        cache,
        null,
        scene.player,
        selectedUnitId: 'preview-commander',
      );
      await layer.debugLoadGhost();
    });
    expect(layer.debugSegmentCount, 7);
    expect(layer.debugBoundaryCount, 0);
    expect(layer.debugTraversedSegmentCount, 0);
    final builds = layer.debugPathBuildCount;
    layer.applyRoute(
      cache,
      null,
      storedRouteScene().player,
      selectedUnitId: 'preview-commander',
    );
    expect(layer.debugPathBuildCount, builds);
    layer.applyRoute(
      cache,
      routeAnimationPlan([(col: 2, row: 2), (col: 3, row: 2)]),
      scene.player,
      selectedUnitId: 'preview-commander',
    );
    expect(layer.debugSegmentCount, 1);
    layer.applyRoute(
      cache,
      null,
      scene.player,
      selectedUnitId: 'preview-commander',
    );
    expect(layer.debugSegmentCount, 7);
    layer.applyRoute(cache, null, scene.player);
    expect(layer.isVisible, isFalse);
    layer.applyRoute(
      cache,
      null,
      storedRouteScene(owner: 'foreign').player,
      selectedUnitId: 'preview-commander',
    );
    expect(layer.isVisible, isFalse);
  });

  testWidgets('merchant animation follows only its remaining visible route', (
    tester,
  ) async {
    final scene = storedRouteScene(merchant: true, current: 5);
    final cache = MapStaticRenderCache.build(scene.map);
    final layer = MapRouteLayerComponent();
    addTearDown(layer.clearLayer);
    await tester.runAsync(() async {
      layer.applyRoute(
        cache,
        null,
        scene.player,
        selectedUnitId: 'preview-commander',
      );
      await layer.debugLoadGhost();
    });
    expect(layer.debugTraversedSegmentCount, 5);
    expect(
      layer
          .debugSegmentBounds(5)
          .inflate(1)
          .contains(layer.debugGhostPosition!),
      isTrue,
    );
    layer.setViewportActive(true);
    layer.applyViewport(layer.debugSegmentBounds(0).inflate(1));
    layer.update(1);
    expect(layer.debugActiveUpdateCount, 0);
    layer.applyViewport(layer.debugSegmentBounds(6).inflate(1));
    layer.update(1);
    expect(layer.debugActiveUpdateCount, 1);
    layer.setReducedMotion(true);
    layer.update(1);
    expect(layer.debugActiveUpdateCount, 1);
    layer.setReducedMotion(false);
    layer.setAnimations(false);
    layer.update(1);
    expect(layer.debugActiveUpdateCount, 1);
    layer.applyRoute(
      cache,
      null,
      storedRouteScene(merchant: true, current: 7).player,
      selectedUnitId: 'preview-commander',
    );
    expect(layer.debugTraversedSegmentCount, 7);
    expect(layer.debugGhostPosition, isNull);
    expect(layer.debugGhostFrameId, isNull);
  });

  testWidgets('renders saved queue and partially traversed merchant route', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xff20313e), ui.BlendMode.src);
    for (var row = 0; row < 2; row++) {
      final scene = storedRouteScene(merchant: row == 1, current: row * 3);
      final layer = MapRouteLayerComponent();
      await tester.runAsync(() async {
        layer.applyRoute(
          MapStaticRenderCache.build(scene.map),
          null,
          scene.player,
          selectedUnitId: 'preview-commander',
        );
        await layer.debugLoadGhost();
      });
      canvas.save();
      canvas.translate(-120, row * 200.0 - 40);
      layer.render(canvas);
      canvas.restore();
      layer.clearLayer();
    }
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(960, 400));
    picture.dispose();
    await expectLater(
      image!,
      matchesGoldenFile('goldens/map_stored_route.png'),
    );
    image.dispose();
  });
}
