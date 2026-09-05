import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/game/aonw_flame_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_feedback_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<AonwFlameGame>(
    'sounds coalesced revisions once without keeping the game loop awake',
    AonwFlameGame.new,
    (game) async {
      final sounds = <MapSoundKindView>[];
      game.world.eventFeedbackLayer.onSound = sounds.add;
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.setReducedMotion(true);
      final snapshot = feedbackSnapshot(
        revision: 2,
        cues: [_sound(), _city(revision: 2)],
      );
      game.replaceScene(snapshot);
      expect(sounds, [MapSoundKindView.movement, MapSoundKindView.city]);
      expect(game.world.eventFeedbackLayer.debugParticleCount, 0);
      expect(game.paused, isTrue);
      game.replaceScene(snapshot);
      game.update(10);
      expect(sounds, hasLength(2));
      game.world.eventFeedbackLayer.onSound = null;
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [_sound(revision: 3)]),
      );
      expect(sounds, hasLength(2));
    },
  );

  testWithGame<AonwFlameGame>(
    'keeps audio with its particle while the presentation pool is full',
    AonwFlameGame.new,
    (game) async {
      final sounds = <MapSoundKindView>[];
      game.world.eventFeedbackLayer.onSound = sounds.add;
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [
            for (var index = 0; index < 8; index++)
              particleCue(eventIndex: index),
            _city(eventIndex: 8),
          ],
        ),
      );
      expect(sounds, isEmpty);
      expect(game.world.eventFeedbackLayer.debugPendingBurstCount, 1);
      game.update(1.5);
      expect(sounds, [MapSoundKindView.city]);
      expect(game.world.eventFeedbackLayer.debugActiveBurstCount, 1);
      game.update(1.5);
      expect(sounds, hasLength(1));
    },
  );

  testWithGame<AonwFlameGame>(
    'returning to the map discards queued and newly hidden sounds',
    AonwFlameGame.new,
    (game) async {
      final sounds = <MapSoundKindView>[];
      game.world.eventFeedbackLayer.onSound = sounds.add;
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [
            for (var index = 0; index < 8; index++)
              particleCue(eventIndex: index),
            _city(eventIndex: 8),
          ],
        ),
      );
      game.setViewportActive(false);
      game.replaceScene(
        feedbackSnapshot(revision: 2, cues: [_city(revision: 2)]),
      );
      game.setViewportActive(true);
      game.update(1.5);
      expect(sounds, isEmpty);
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [_sound(revision: 3)]),
      );
      expect(sounds, [MapSoundKindView.movement]);
    },
  );

  testWithGame<AonwFlameGame>(
    'fog changes discard the sound of a queued particle too',
    AonwFlameGame.new,
    (game) async {
      final sounds = <MapSoundKindView>[];
      game.world.eventFeedbackLayer.onSound = sounds.add;
      game.replaceScene(feedbackSnapshot());
      await game.ready();
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(
          revision: 1,
          cues: [
            for (var index = 0; index < 8; index++)
              particleCue(eventIndex: index),
            _city(eventIndex: 8),
          ],
        ),
      );
      game.replaceScene(
        feedbackSnapshot(
          revision: 2,
          fog: MapFogView(
            enabled: true,
            discoveredHexes: const [(col: 1, row: 0)],
            visibleHexes: const [],
          ),
        ),
      );
      game.update(1.5);
      expect(sounds, isEmpty);
      expect(game.world.eventFeedbackLayer.debugPendingBurstCount, 0);
    },
  );

  testWithGame<AonwFlameGame>(
    'mount seek recipient changes and resync never replay retained audio',
    AonwFlameGame.new,
    (game) async {
      final sounds = <MapSoundKindView>[];
      game.world.eventFeedbackLayer.onSound = sounds.add;
      game.setViewportActive(true);
      game.replaceScene(
        feedbackSnapshot(revision: 3, cues: [_sound(revision: 3)]),
      );
      await game.ready();
      game.replaceScene(feedbackSnapshot(revision: 7));
      game.replaceScene(
        feedbackSnapshot(revision: 8, cues: [_sound(revision: 3)]),
      );
      game.replaceScene(
        feedbackSnapshot(revision: 2, cues: [_sound(revision: 2)]),
      );
      game.replaceScene(
        feedbackSnapshot(
          revision: 3,
          actor: 'other',
          cues: [_sound(revision: 3)],
        ),
      );
      expect(sounds, isEmpty);
      game.replaceScene(
        feedbackSnapshot(
          revision: 4,
          actor: 'other',
          cues: [_sound(revision: 4)],
        ),
      );
      expect(sounds, [MapSoundKindView.movement]);
      game.clearScene();
      game.replaceScene(
        feedbackSnapshot(revision: 5, cues: [_sound(revision: 5)]),
      );
      expect(sounds, hasLength(1));
    },
  );
}

MapSoundCueView _sound({int revision = 1}) => MapSoundCueView(
  identity: (revision: revision, eventIndex: 0),
  coordinate: (col: 1, row: 0),
  sound: MapSoundKindView.movement,
);

MapParticleCueView _city({int revision = 1, int eventIndex = 0}) =>
    MapParticleCueView(
      identity: (revision: revision, eventIndex: eventIndex),
      coordinate: (col: 1, row: 0),
      kind: MapParticleKindView.cityFounded,
      colorValue: 0xff68a7e8,
      sound: MapSoundKindView.city,
    );
