import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_cloud_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  testWidgets('renders cloud puffs only inside discovered hexes', (
    tester,
  ) async {
    final map = testMapScene(cols: 8, rows: 6).map;
    final cache = MapStaticRenderCache.build(map);
    final layer = MapCloudLayerComponent(
      random: math.Random(7),
      initialDelaySeconds: 0,
      durationSeconds: (min: 40, max: 40),
    );
    addTearDown(layer.clearLayer);
    final fog = MapFogView(
      enabled: true,
      discoveredHexes: [
        for (final tile in map.tiles)
          if (tile.coordinate.col != 4) tile.coordinate,
      ],
      visibleHexes: const [],
    );
    layer.applyFog(cache, fog, actorPlayerId: 'viewer');
    layer.setViewportActive(true);
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer.debugActiveCloudCount, inInclusiveRange(1, 3));
    expect(layer.debugActivePuffCount, inInclusiveRange(8, 33));
    layer.update(20);
    for (final tile in map.tiles) {
      final center = cache.projection.hexCenter(tile.coordinate);
      expect(
        layer.debugIsDiscovered(ui.Offset(center.x, center.y)),
        tile.coordinate.col != 4,
      );
    }
    final image = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src)
        ..translate(24, 24)
        ..drawPath(
          cache.gridPath,
          ui.Paint()
            ..color = const ui.Color(0xff45454b)
            ..style = ui.PaintingStyle.stroke,
        );
      layer.render(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(800, 500);
      picture.dispose();
      return image;
    });
    await expectLater(image!, matchesGoldenFile('goldens/map_clouds.png'));
    image.dispose();
  });

  testWidgets('wakes Flame for bounded groups and sleeps during spawn gaps', (
    tester,
  ) async {
    final layer = MapCloudLayerComponent(
      random: _ClusterRandom(),
      initialDelaySeconds: 2,
      spawnGapSeconds: (min: 5, max: 5),
      durationSeconds: (min: 4, max: 4),
    );
    final game = AonwFlameGame(world: AonwWorld(cloudLayer: layer));
    final scene = testMapScene();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget<AonwFlameGame>(game: game),
      ),
    );
    game.replaceScene(
      MapRenderSnapshot(
        map: scene.map,
        reference: scene.reference,
        player: scene.player,
        interaction: const MapInteractionState(),
      ),
    );
    await tester.runAsync(game.ready);
    layer.applyFog(
      game.world.debugStaticRenderCache!,
      _knownFog(),
      actorPlayerId: scene.player.actorPlayerId,
    );
    game.setViewportActive(true);
    expect(game.paused, isTrue);
    expect(layer.debugSpawnScheduled, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(layer.debugActiveUpdateCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(game.paused, isFalse);
    expect(layer.debugActiveCloudCount, 3);
    expect(layer.debugActivePuffCount, 33);
    game.setContinuousRendering(true);
    layer.update(10);
    expect(layer.debugActiveCloudCount, 0);
    expect(game.paused, isFalse, reason: 'another frame source stays active');
    game.setContinuousRendering(false);
    expect(game.paused, isTrue);
    final updates = layer.debugActiveUpdateCount;
    await tester.pump(const Duration(seconds: 4));
    expect(layer.debugActiveUpdateCount, updates);
    await tester.pump(const Duration(seconds: 1));
    expect(layer.debugActiveCloudCount, 3);
    expect(game.paused, isFalse);
    game.setViewportActive(false);
    expect(game.paused, isTrue);
    expect(layer.debugActiveCloudCount, 0);
    expect(layer.debugSpawnScheduled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer.debugSpawnScheduled, isFalse);
  });

  testWidgets('clears weather for reduced motion recipients and disabled fog', (
    tester,
  ) async {
    final cache = MapStaticRenderCache.build(testMapScene().map);
    final layer = MapCloudLayerComponent(initialDelaySeconds: 0);
    addTearDown(layer.clearLayer);
    layer.applyFog(cache, _knownFog(), actorPlayerId: 'first');
    layer.setViewportActive(true);
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer.debugActiveCloudCount, greaterThan(0));
    final builds = layer.debugClipBuildCount;
    layer.applyFog(cache, _knownFog(), actorPlayerId: 'first');
    expect(layer.debugClipBuildCount, builds);
    layer.setReducedMotion(true);
    expect(layer.debugActiveCloudCount, 0);
    expect(layer.debugSpawnScheduled, isFalse);
    layer.setReducedMotion(false);
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer.debugActiveCloudCount, greaterThan(0));
    layer.applyFog(cache, _knownFog(), actorPlayerId: 'second');
    expect(layer.debugActiveCloudCount, 0);
    expect(layer.debugClipBuildCount, builds + 1);
    await tester.pump(const Duration(milliseconds: 1));
    layer.applyFog(cache, MapFogView.disabled(), actorPlayerId: 'second');
    expect(layer.debugActiveCloudCount, 0);
    expect(layer.debugSpawnScheduled, isFalse);
    layer.applyFog(
      cache,
      MapFogView(
        enabled: true,
        discoveredHexes: const [],
        visibleHexes: const [],
      ),
      actorPlayerId: 'second',
    );
    expect(layer.debugSpawnScheduled, isFalse);
    layer.applyFog(cache, _knownFog(), actorPlayerId: 'second');
    layer.clearLayer();
    await tester.pump(const Duration(milliseconds: 1));
    expect(layer.debugSpawnScheduled, isFalse);
    expect(layer.debugActiveCloudCount, 0);
  });
}

MapFogView _knownFog() => MapFogView(
  enabled: true,
  discoveredHexes: const [(col: 0, row: 0), (col: 1, row: 0)],
  visibleHexes: const [(col: 0, row: 0)],
);

final class _ClusterRandom implements math.Random {
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}
