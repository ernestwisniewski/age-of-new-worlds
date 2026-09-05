import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_era_tint_layer.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_era_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'renders six research eras as a diagonal gradient over map hexes',
    () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
      final layer = MapEraTintLayerComponent();
      final cache = MapStaticRenderCache.build(
        eraSnapshot(PlayerTechnologyEraView.foundation).map,
      );
      layer.setReducedMotion(true);
      for (final era in PlayerTechnologyEraView.values) {
        canvas.save();
        canvas.translate(
          20 + (era.index % 3) * 330,
          20 + (era.index ~/ 3) * 270,
        );
        canvas.drawPath(
          cache.gridPath,
          ui.Paint()..color = const ui.Color(0xff808080),
        );
        layer.applySnapshot(eraSnapshot(era), cache);
        layer.render(canvas);
        canvas.restore();
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1030, 570);
      picture.dispose();
      await expectLater(image, matchesGoldenFile('goldens/map_era_tints.png'));
      image.dispose();
    },
  );

  testWithGame<AonwFlameGame>(
    'reuses tint for research progress cursor updates and idle frames',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.foundation));
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eraTintLayer;
      expect(layer.debugTintColor, const ui.Color(0x22f6c365));
      final builds = layer.debugShaderBuildCount;
      game.replaceCursor((col: 1, row: 1));
      game.replaceScene(
        eraSnapshot(PlayerTechnologyEraView.foundation, revision: 1),
      );
      for (var frame = 0; frame < 120; frame++) {
        game.update(1 / 60);
      }
      expect(layer.debugShaderBuildCount, builds);
      expect(layer.debugActiveUpdateCount, 0);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'wakes Flame for a smooth transition then returns to idle',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.foundation));
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eraTintLayer;
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.industry));
      expect(game.paused, isFalse);
      expect(layer.debugTintColor, const ui.Color(0x22f6c365));
      game.update(0.325);
      expect(
        layer.debugTintColor,
        ui.Color.lerp(
          const ui.Color(0x22f6c365),
          const ui.Color(0x286d747c),
          0.5,
        ),
      );
      game.update(0.325);
      expect(layer.debugTintColor, const ui.Color(0x286d747c));
      expect(layer.debugActive, isFalse);
      expect(game.paused, isTrue);
      final updates = layer.debugActiveUpdateCount;
      game.update(1);
      expect(layer.debugActiveUpdateCount, updates);
    },
  );

  test(
    'retargets from the displayed tint and fades to transparent expansion',
    () {
      final layer = MapEraTintLayerComponent();
      final cache = MapStaticRenderCache.build(
        eraSnapshot(PlayerTechnologyEraView.foundation).map,
      );
      final activity = <bool>[];
      layer.onActivityChanged = activity.add;
      layer.applySnapshot(
        eraSnapshot(PlayerTechnologyEraView.foundation),
        cache,
      );
      layer.applySnapshot(eraSnapshot(PlayerTechnologyEraView.industry), cache);
      layer.update(0.2);
      final intermediate = layer.debugTintColor;
      layer.applySnapshot(
        eraSnapshot(PlayerTechnologyEraView.expansion),
        cache,
      );
      expect(layer.debugTintColor, intermediate);
      layer.update(0.325);
      expect(
        layer.debugTintColor,
        ui.Color.lerp(intermediate, const ui.Color(0x00000000), 0.5),
      );
      layer.update(0.325);
      expect(layer.debugTintColor, const ui.Color(0x00000000));
      expect(layer.isVisible, isFalse);
      expect(activity, [true, false]);
    },
  );

  testWithGame<AonwFlameGame>(
    'respects playback speed skip reduced motion and other frame sources',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.foundation));
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eraTintLayer;
      game.setEffectPlaybackSpeed(2);
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.settlement));
      game.update(0.325);
      expect(layer.debugTintColor, const ui.Color(0x14b9d88c));
      expect(game.paused, isTrue);
      game.setContinuousRendering(true);
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.strategy));
      game.skipEffects();
      expect(layer.debugTintColor, const ui.Color(0x24f0a24f));
      expect(layer.debugActive, isFalse);
      expect(game.paused, isFalse);
      game.setContinuousRendering(false);
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.specialization));
      game.setReducedMotion(true);
      expect(layer.debugTintColor, const ui.Color(0x1c78b7ff));
      expect(game.paused, isTrue);
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.industry));
      expect(layer.debugTintColor, const ui.Color(0x286d747c));
      expect(layer.debugActive, isFalse);
      for (final speed in [0.0, -1.0, double.nan, double.infinity]) {
        expect(() => layer.setPlaybackSpeed(speed), throwsArgumentError);
      }
    },
  );

  testWithGame<AonwFlameGame>(
    'resets tint on recipient map and scene changes and pauses when hidden',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.foundation));
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eraTintLayer;
      game.replaceScene(eraSnapshot(PlayerTechnologyEraView.industry));
      game.update(0.1);
      game.replaceScene(
        eraSnapshot(PlayerTechnologyEraView.strategy, actor: 'second'),
      );
      expect(layer.debugTintColor, const ui.Color(0x24f0a24f));
      expect(game.paused, isTrue);
      game.replaceScene(
        eraSnapshot(PlayerTechnologyEraView.industry, actor: 'second'),
      );
      game.setViewportActive(false);
      expect(game.paused, isTrue);
      game.setViewportActive(true);
      expect(game.paused, isFalse);
      game.replaceScene(
        eraSnapshot(
          PlayerTechnologyEraView.expansion,
          actor: 'second',
          contentHash: 'd' * 64,
        ),
      );
      expect(layer.isVisible, isFalse);
      expect(game.paused, isTrue);
      game.replaceScene(
        eraSnapshot(
          PlayerTechnologyEraView.industry,
          actor: 'second',
          contentHash: 'd' * 64,
        ),
      );
      expect(layer.debugActive, isTrue);
      game.clearScene();
      expect(layer.debugEra, isNull);
      expect(layer.isVisible, isFalse);
      expect(layer.debugActive, isFalse);
      expect(game.paused, isTrue);
    },
  );
}
