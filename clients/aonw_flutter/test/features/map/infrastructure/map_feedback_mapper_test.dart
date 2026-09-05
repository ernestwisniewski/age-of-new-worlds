import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/map_feedback_mapper.dart';
import 'package:aonw_flutter/features/map/infrastructure/player_map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_feedback_test_fixture.dart';

part 'map_feedback_mapper_fixture.dart';
part 'map_feedback_text_mapper_tests.dart';

void main() {
  textMapperTests();
  test(
    'retains event order exact anchors and owner color through the view mapper',
    () {
      final previous = feedbackSnapshot();
      final snapshot = _snapshot();
      final cues = mapCommandFeedback(
        command: _command(snapshot, _events),
        snapshot: snapshot,
        previous: previous.player,
        map: previous.map,
      );
      expect(cues.map((cue) => cue.identity), [
        for (var index = 0; index < 4; index++)
          (revision: 1, eventIndex: index),
      ]);
      expect(
        cues.cast<MapParticleCueView>().map((cue) => cue.kind),
        MapParticleKindView.values,
      );
      expect(cues.map((cue) => cue.coordinate), [
        (col: 1, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 1),
        (col: 1, row: 0),
      ]);
      expect(
        cues.cast<MapParticleCueView>().map((cue) => cue.colorValue),
        everyElement(0xff68a7e8),
      );
      final player = const PlayerMapViewMapper().fromWire(
        snapshot,
        map: previous.map,
        actorPlayerId: previous.player.actorPlayerId,
        recentFeedback: cues,
      );
      expect(player.recentFeedback, cues);
      expect(() => player.recentFeedback.clear(), throwsUnsupportedError);
      expect(
        const PlayerMapViewMapper()
            .fromWire(
              snapshot,
              map: previous.map,
              actorPlayerId: previous.player.actorPlayerId,
            )
            .recentFeedback,
        isEmpty,
        reason: 'resync has no event history',
      );
    },
  );

  test(
    'filters missing hidden and unrelated recipients without guessing events',
    () {
      final previous = feedbackSnapshot();
      final snapshot = _snapshot(
        visible: const [AonwCoordinate(col: 2, row: 1)],
      );
      final cues = mapCommandFeedback(
        command: _command(snapshot, [
          ..._events,
          const AonwCityFoundedEvent(
            cityId: 'missing',
            ownerPlayerId: 'preview-player',
          ),
          const AonwCityFoundedEvent(cityId: 'city', ownerPlayerId: 'foreign'),
          const AonwTechnologyResearchedEvent(
            playerId: 'foreign',
            technology: AonwTechnologyId.strategy,
          ),
          const AonwCityClaimedHexEvent(
            cityId: 'city',
            coordinate: AonwCoordinate(col: 50, row: 50),
          ),
        ]),
        snapshot: snapshot,
        previous: previous.player,
        map: previous.map,
      );
      expect(cues, hasLength(1));
      expect(cues.single.identity.eventIndex, 2);
      expect(
        (cues.single as MapParticleCueView).kind,
        MapParticleKindView.hexClaimed,
      );
      final withoutEvents = mapCommandFeedback(
        command: _command(snapshot, []),
        snapshot: snapshot,
        previous: previous.player,
        map: previous.map,
      );
      expect(
        withoutEvents,
        isEmpty,
        reason: 'new entities in a snapshot do not imply a production event',
      );
    },
  );

  test('anchors completed research on an owned unit before the first city', () {
    final previous = feedbackSnapshot();
    final snapshot = _snapshot(cities: false);
    final cues = mapCommandFeedback(
      command: _command(snapshot, [_events.last]),
      snapshot: snapshot,
      previous: previous.player,
      map: previous.map,
    );
    expect(cues.single.coordinate, (col: 0, row: 1));
  });

  test(
    'keeps a bounded journal across commands without repeating no-op results',
    () {
      final first = feedbackSnapshot();
      final snapshot = _snapshot();
      final cues = mapCommandFeedback(
        command: _command(snapshot, [
          for (var index = 0; index < 70; index++) _events.first,
        ]),
        snapshot: snapshot,
        previous: first.player,
        map: first.map,
      );
      expect(cues, hasLength(64));
      expect(cues.first.identity, (revision: 1, eventIndex: 6));
      final previous = feedbackSnapshot(revision: 1, cues: cues);
      final second = _snapshot(revision: 2);
      final appended = mapCommandFeedback(
        command: _command(second, [_events.last]),
        snapshot: second,
        previous: previous.player,
        map: previous.map,
      );
      expect(appended, hasLength(64));
      expect(appended.first.identity, (revision: 1, eventIndex: 7));
      expect(appended.last.identity, (revision: 2, eventIndex: 0));
      for (final accepted in [true, false]) {
        final unchanged = mapCommandFeedback(
          command: _command(snapshot, [], accepted: accepted, fromRevision: 1),
          snapshot: snapshot,
          previous: previous.player,
          map: previous.map,
        );
        expect(unchanged, same(previous.player.recentFeedback));
      }
      expect(
        () => mapCommandFeedback(
          command: _command(_snapshot(revision: 8), _events),
          snapshot: _snapshot(revision: 8),
          previous: previous.player,
          map: previous.map,
        ),
        throwsFormatException,
      );
    },
  );
}
