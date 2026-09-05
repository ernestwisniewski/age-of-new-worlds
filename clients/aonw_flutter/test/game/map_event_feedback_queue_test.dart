import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_feedback_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<AonwFlameGame>(
    'starts an artifact pair together after occupied particle slots clear',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [for (var i = 0; i < 8; i++) particleCue(eventIndex: i)],
        ),
      );
      game.replaceScene(
        feedbackSnapshot(revision: 2, cues: _artifact(0, revision: 2)),
      );
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugTextCount, 0);
      expect(layer.debugPendingTextCount, 1);
      expect(layer.debugPendingBurstCount, 1);
      game.update(1.5);
      expect(layer.debugPendingTextCount, 0);
      expect(layer.debugPendingBurstCount, 0);
      expect(layer.debugParticleCount, 32);
      expect(layer.debugTextCount, 1);
      expect(layer.debugVisibleTextCount, 0);
      game.update(0.121);
      expect(layer.debugVisibleTextCount, 1);
    },
  );

  testWithGame<AonwFlameGame>(
    'holds paired particles until a text slot frees and retains queued labels',
    AonwFlameGame.new,
    (game) async {
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [for (var i = 0; i < 9; i++) ..._artifact(i)],
        ),
      );
      final layer = game.world.eventFeedbackLayer;
      expect(layer.debugParticleCount, 256);
      expect(layer.debugTextCount, 8);
      game.update(1.5);
      expect(layer.debugParticleCount, 0);
      expect(layer.debugTextCount, 8);
      expect(layer.debugPendingBurstCount, 1);
      expect(layer.debugPendingTextCount, 1);
      game.replaceScene(feedbackSnapshot(revision: 2));
      game.update(2.321);
      expect(layer.debugParticleCount, 32);
      expect(layer.debugTextCount, 1);
      expect(layer.debugPendingBurstCount, 0);
      expect(layer.debugPendingTextCount, 0);
      game.update(0.121);
      expect(layer.debugVisibleTextCount, 1);
      game.skipEffects();
      expect(layer.debugTextImageCount, 0);
      expect(game.paused, isTrue);
    },
  );
}

List<MapFeedbackCueView> _artifact(int index, {int revision = 1}) => [
  particleCue(
    revision: revision,
    eventIndex: index,
    kind: MapParticleKindView.technologyResearched,
  ),
  MapFloatingTextCueView(
    identity: (revision: revision, eventIndex: index),
    coordinate: (col: 1, row: 0),
    content: const MapMessageTextView(MapFeedbackMessageView.artifactCarried),
    colorValue: 0xffffd166,
    style: MapFloatingTextStyleView.bubble,
    delay: const Duration(milliseconds: 120),
  ),
];
