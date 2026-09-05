import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:aonw_flutter/game/map/map_event_particles.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_feedback_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders founded produced claimed and research event bursts', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
    final expectedCounts = [36, 18, 24, 32];
    for (final kind in MapParticleKindView.values) {
      final burst = MapEventParticleBurst();
      burst.start(
        particleCue(kind: kind),
        ui.Offset(110 + 200 * kind.index.toDouble(), 110),
      );
      expect(burst.particleCount, expectedCounts[kind.index]);
      burst.update(0.3);
      burst.render(canvas);
      burst.update(2);
      expect(burst.active, isFalse);
      expect(burst.cue, isNull);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(820, 220);
    picture.dispose();
    await expectLater(
      image,
      matchesGoldenFile('goldens/map_event_particles.png'),
    );
    image.dispose();
  });

  testWithGame<AonwFlameGame>(
    'consumes coalesced revisions once and wakes only until bursts expire',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eventFeedbackLayer;
      expect(game.paused, isTrue);
      final cues = [
        particleCue(),
        particleCue(revision: 2, kind: MapParticleKindView.unitProduced),
      ];
      game.replaceScene(feedbackSnapshot(revision: 2, cues: cues));
      expect(layer.debugActiveBurstCount, 2);
      expect(layer.debugParticleCount, 54);
      expect(game.paused, isFalse);
      game.update(0.4);
      game.replaceScene(feedbackSnapshot(revision: 2, cues: cues));
      game.update(0.31);
      expect(
        layer.debugActiveBurstCount,
        1,
        reason: 'a duplicate scene does not restart a burst',
      );
      game.update(1);
      expect(layer.debugParticleCount, 0);
      expect(game.paused, isTrue);
      final count = layer.debugActiveUpdateCount;
      game.update(1);
      expect(layer.debugActiveUpdateCount, count);
    },
  );

  testWithGame<AonwFlameGame>(
    'bounds the pool queues remaining events and respects speed and skip',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eventFeedbackLayer;
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [
            for (var index = 0; index < 64; index++)
              particleCue(eventIndex: index),
          ],
        ),
      );
      expect(layer.debugActiveBurstCount, 8);
      expect(layer.debugPendingBurstCount, 56);
      expect(layer.debugParticleCount, 288);
      game.setEffectPlaybackSpeed(2);
      game.update(0.675);
      expect(layer.debugActiveBurstCount, 8);
      expect(layer.debugPendingBurstCount, 48);
      game.setContinuousRendering(true);
      game.skipEffects();
      expect(layer.debugPendingBurstCount, 0);
      expect(layer.debugParticleCount, 0);
      expect(game.paused, isFalse);
      game.setContinuousRendering(false);
      expect(game.paused, isTrue);
      for (final speed in [0.0, -1.0, double.nan, double.infinity]) {
        expect(() => layer.setPlaybackSpeed(speed), throwsArgumentError);
      }
    },
  );

  testWithGame<AonwFlameGame>(
    'clears effects for fog reduced motion map and recipient changes',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      final layer = game.world.eventFeedbackLayer;
      final cues = [particleCue()];
      game.replaceScene(feedbackSnapshot(revision: 1, cues: cues));
      final fog = MapFogView(
        enabled: true,
        discoveredHexes: const [(col: 1, row: 0)],
        visibleHexes: const [],
      );
      game.replaceScene(feedbackSnapshot(revision: 2, cues: cues, fog: fog));
      expect(layer.debugParticleCount, 0);
      game.replaceScene(
        feedbackSnapshot(
          revision: 3,
          cues: [particleCue(revision: 3)],
          fog: fog,
        ),
      );
      expect(layer.debugParticleCount, 0);
      game.setReducedMotion(true);
      game.replaceScene(
        feedbackSnapshot(revision: 4, cues: [particleCue(revision: 4)]),
      );
      expect(layer.debugParticleCount, 0);
      game.setReducedMotion(false);
      game.replaceScene(
        feedbackSnapshot(revision: 5, cues: [particleCue(revision: 5)]),
      );
      expect(layer.debugActiveBurstCount, 1);
      game.replaceScene(
        feedbackSnapshot(revision: 5, actor: 'other', cues: cues),
      );
      expect(layer.debugParticleCount, 0);
      game.replaceScene(
        feedbackSnapshot(
          revision: 6,
          actor: 'other',
          cues: [particleCue(revision: 6)],
        ),
      );
      game.replaceScene(
        feedbackSnapshot(revision: 7, actor: 'other', contentHash: 'd' * 64),
      );
      expect(layer.debugParticleCount, 0);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<AonwFlameGame>(
    'does not replay retained history on mount resync or backward seek',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [particleCue(revision: 3)]),
      );
      await game.ready();
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugParticleCount, 0);
      game.replaceScene(feedbackSnapshot(revision: 7));
      game.replaceScene(
        feedbackSnapshot(revision: 8, cues: [particleCue(revision: 3)]),
      );
      expect(layer.debugParticleCount, 0);
      game.replaceScene(
        feedbackSnapshot(revision: 9, cues: [particleCue(revision: 9)]),
      );
      expect(layer.debugParticleCount, 36);
      game.replaceScene(
        feedbackSnapshot(revision: 2, cues: [particleCue(revision: 2)]),
      );
      expect(layer.debugParticleCount, 0);
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [particleCue(revision: 3)]),
      );
      game.clearScene();
      expect(layer.debugParticleCount, 0);
      expect(layer.debugPendingBurstCount, 0);
    },
  );
}
