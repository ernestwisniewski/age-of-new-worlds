import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_floating_text_pool.dart';
import 'package:aonw_flutter/game/map/static_map_layers.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_pl.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_feedback_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'delays unit anchors and stacks recent labels independently of cities',
    () {
      var unitPosition = const ui.Offset(130, 150);
      final pool = MapFloatingTextPool(unitPositionFor: (_) => unitPosition);
      addTearDown(pool.clear);
      final cues = [
        for (var i = 0; i < 4; i++)
          _cue(
            i,
            anchor: i == 2
                ? const MapCityTextAnchorView('city')
                : const MapUnitTextAnchorView('unit'),
            delay: const Duration(milliseconds: 120),
          ),
      ];
      final snapshot = feedbackSnapshot(revision: 1, cues: cues);
      final cache = MapStaticRenderCache.build(snapshot.map);
      pool.applyContext(cache, snapshot.player.fog, snapshot.feedbackLabels);
      pool.enqueue(cues[0]);
      pool.startPending();
      pool.update(0.119);
      expect(pool.visibleCount, 0);
      unitPosition = const ui.Offset(170, 150);
      pool.update(0.002);
      expect(pool.debugPositionFor(cues[0].identity), const ui.Offset(170, 68));
      pool.enqueue(cues[1]);
      pool.enqueue(cues[2]);
      pool.startPending();
      pool.update(0.121);
      expect(pool.debugPositionFor(cues[1].identity), const ui.Offset(170, 80));
      final center = cache.projection.hexTopFaceCenter(cues[2].coordinate);
      expect(
        pool.debugPositionFor(cues[2].identity),
        ui.Offset(center.x, center.y - 64),
      );
      pool.update(0.6);
      pool.enqueue(cues[3]);
      pool.startPending();
      pool.update(0.121);
      expect(pool.debugPositionFor(cues[3].identity), const ui.Offset(170, 68));
    },
  );

  testWithGame<AonwFlameGame>(
    'bounds text images and queues, then sleeps after skip',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      final cues = [for (var i = 0; i < 64; i++) _cue(i)];
      game.replaceScene(feedbackSnapshot(revision: 1, cues: cues));
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugTextCount, 8);
      expect(layer.debugTextImageCount, 8);
      expect(layer.debugPendingTextCount, 56);
      expect(game.paused, isFalse);
      game.setEffectPlaybackSpeed(2);
      game.update(1.851);
      expect(layer.debugPendingTextCount, 48);
      expect(layer.debugTextCount, 8);
      expect(layer.debugTextImageCount, 8);
      game.skipEffects();
      expect(layer.debugPendingTextCount, 0);
      expect(layer.debugTextImageCount, 0);
      expect(game.paused, isTrue);
      final updates = layer.debugActiveUpdateCount;
      game.update(1);
      expect(layer.debugActiveUpdateCount, updates);
    },
  );

  testWithGame<AonwFlameGame>(
    'keeps accessible text and localizes it without replaying',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.setReducedMotion(true);
      final cues = [particleCue(), _cue(1)];
      game.replaceScene(feedbackSnapshot(revision: 1, cues: cues));
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugParticleCount, 0);
      expect(layer.debugVisibleTextCount, 1);
      game.update(2.5);
      game.replaceScene(
        feedbackSnapshot(revision: 1, cues: cues, l10n: AonwLocalizationsPl()),
      );
      expect(layer.debugTextCount, 1);
      game.update(1.21);
      expect(layer.debugTextCount, 0);
      expect(game.paused, isTrue);
      game.clearScene();
      expect(layer.debugTextImageCount, 0);
    },
  );

  testWithGame<AonwFlameGame>(
    'clears active and queued text when visibility or recipient changes',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      final cues = [for (var i = 0; i < 10; i++) _cue(i)];
      final layer = game.world.eventFeedbackLayer;
      game.replaceScene(feedbackSnapshot(revision: 1, cues: cues));
      game.replaceScene(
        feedbackSnapshot(
          revision: 2,
          cues: cues,
          fog: MapFogView(
            enabled: true,
            discoveredHexes: const [(col: 1, row: 0)],
            visibleHexes: const [],
          ),
        ),
      );
      expect(layer.debugTextImageCount, 0);
      expect(layer.debugPendingTextCount, 0);
      expect(game.paused, isTrue);
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [_cue(0, revision: 3)]),
      );
      expect(layer.debugTextCount, 1);
      game.replaceScene(feedbackSnapshot(revision: 3, actor: 'other'));
      expect(layer.debugTextImageCount, 0);
      game.replaceScene(
        feedbackSnapshot(
          revision: 4,
          actor: 'other',
          cues: [_cue(0, revision: 4)],
        ),
      );
      game.replaceScene(feedbackSnapshot(revision: 2, actor: 'other'));
      expect(layer.debugTextImageCount, 0);
      game.replaceScene(
        feedbackSnapshot(
          revision: 3,
          actor: 'other',
          cues: [_cue(0, revision: 3)],
        ),
      );
      game.replaceScene(
        feedbackSnapshot(revision: 3, actor: 'other', contentHash: 'd' * 64),
      );
      expect(layer.debugTextImageCount, 0);
    },
  );
}

MapFloatingTextCueView _cue(
  int index, {
  int revision = 1,
  MapTextAnchorView anchor = const MapTileTextAnchorView(),
  Duration delay = Duration.zero,
}) => MapFloatingTextCueView(
  identity: (revision: revision, eventIndex: index),
  coordinate: (col: 1, row: 0),
  content: const MapMessageTextView(MapFeedbackMessageView.artifactCarried),
  colorValue: 0xffffd166,
  style: MapFloatingTextStyleView.bubble,
  anchor: anchor,
  delay: delay,
);
