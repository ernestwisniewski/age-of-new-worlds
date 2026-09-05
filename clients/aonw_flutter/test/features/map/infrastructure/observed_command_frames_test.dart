import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/observed_command_frames.dart';
import 'package:aonw_flutter/features/map/infrastructure/player_map_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('projects the shared public AI sequence for its fixed recipient', () {
    final fixture = _Fixture();
    final observed = fixture.observe();
    final frames = observed.frames.toList();
    expect(frames.map((frame) => frame.player.stamp.revision), [1, 2, 3]);
    expect(
      frames.map((frame) => frame.player.actorPlayerId),
      everyElement('human'),
    );
    expect(
      observed.finalPlayer.stamp.stateDigest,
      fixture.ai.stamp.stateDigest,
    );
    expect(observed.finalPlayer.research.activeTechnologyId, isNull);
    for (final frame in frames) {
      expect(frame.player.units.map((unit) => unit.id), [
        'human-unit',
        'visible-ai',
      ]);
      expect(frame.player.units.last.coordinate, (col: 1, row: 0));
      expect(frame.player.recentFeedback, isEmpty);
    }
  });

  test('retains feedback order across independent lazy traversals', () {
    final fixture = _Fixture();
    final commands = [
      for (final command in fixture.ai.commands)
        _withEvents(command, [
          ...command.events,
          const AonwTechnologyResearchedEvent(
            playerId: 'human',
            technology: AonwTechnologyId.agriculture,
          ),
        ]),
    ];
    final observed = fixture.observe(commands: commands);
    final first = observed.frames.iterator;
    final second = observed.frames.iterator;
    expect(first.moveNext(), isTrue);
    expect(first.current.player.recentFeedback.single.identity, (
      revision: 1,
      eventIndex: 1,
    ));
    expect(first.moveNext(), isTrue);
    expect(second.moveNext(), isTrue);
    expect(second.current.player.stamp.revision, 1);
    expect(first.current.player.stamp.revision, 2);
    expect(second.current.player.recentFeedback, hasLength(1));
    expect(observed.finalPlayer.recentFeedback.map((cue) => cue.identity), [
      (revision: 1, eventIndex: 1),
      (revision: 2, eventIndex: 0),
      (revision: 3, eventIndex: 0),
    ]);
    expect(
      () => observed.finalPlayer.recentFeedback.clear(),
      throwsUnsupportedError,
    );
    commands.clear();
    expect(
      observed.frames.length,
      3,
      reason: 'Caller cannot mutate the retained batch.',
    );
  });

  test('empty, rejected and unchanged commands preserve previous feedback', () {
    final fixture = _Fixture();
    final previous = fixture.player(
      recentFeedback: const [
        MapParticleCueView(
          identity: (revision: 0, eventIndex: 0),
          coordinate: (col: 0, row: 0),
          kind: MapParticleKindView.technologyResearched,
          colorValue: 0xff68a7e8,
        ),
      ],
    );
    final empty = fixture.observe(
      initialPlayer: previous,
      commands: const [],
      finalStamp: fixture.initial.stamp,
    );
    expect(empty.frames, isEmpty);
    expect(empty.lastFrame, isNull);
    expect(empty.finalPlayer, same(previous));
    final unchanged = fixture.observe(
      initialPlayer: previous,
      commands: [
        _unchanged(fixture.initial),
        _unchanged(fixture.initial, rejected: true),
      ],
      finalStamp: fixture.initial.stamp,
    );
    expect(unchanged.frames.map((frame) => frame.player.stamp.revision), [
      0,
      0,
    ]);
    expect(
      unchanged.finalPlayer.recentFeedback.single,
      same(previous.recentFeedback.single),
    );
  });

  test(
    'rejects a wrong recipient or a broken command chain before presentation',
    () {
      final fixture = _Fixture();
      expect(() => fixture.observe(recipient: 'ai'), throwsFormatException);
      expect(
        () => fixture.observe(commands: fixture.ai.commands.reversed.toList()),
        throwsFormatException,
      );
      expect(
        () => fixture.observe(commands: fixture.ai.commands.take(2).toList()),
        throwsFormatException,
      );
      expect(
        () => fixture.observe(
          initialPlayer: fixture.observe().frames.first.player,
        ),
        throwsFormatException,
      );
    },
  );

  test('validates a malformed final patch before exposing any frames', () {
    final fixture = _Fixture();
    final commands =
        _response('observed_ai_turn_response.json')['commands']
            as List<dynamic>;
    final firstPatch =
        (commands.first as Map<String, dynamic>)['viewPatch']
            as Map<String, dynamic>;
    final unit =
        (firstPatch['upsertedUnits'] as List<dynamic>).single
            as Map<String, dynamic>;
    unit['coordinate'] = {'col': 12, 'row': 0};
    final last = commands.last as Map<String, dynamic>;
    (last['viewPatch'] as Map<String, dynamic>)['upsertedUnits'] = [unit];
    expect(
      () => fixture.observe(
        commands: [
          ...fixture.ai.commands.take(2),
          AonwCommandResult.fromJson(last),
        ],
      ),
      throwsFormatException,
    );
  });

  test('compares every component of the final stamp', () {
    final fixture = _Fixture();
    final stamp = fixture.ai.stamp;
    for (final field in ['revision', 'digest', 'map', 'rules']) {
      final changed = AonwSessionStamp(
        revision: field == 'revision' ? stamp.revision + 1 : stamp.revision,
        stateDigest: field == 'digest' ? 'a' * 64 : stamp.stateDigest,
        mapHash: field == 'map' ? 'b' * 64 : stamp.mapHash,
        rulesetHash: field == 'rules' ? 'c' * 64 : stamp.rulesetHash,
      );
      expect(
        () => fixture.observe(finalStamp: changed),
        throwsFormatException,
        reason: field,
      );
    }
  });
}

final class _Fixture {
  _Fixture() {
    final replay = _response('observed_replay_frame_response.json');
    final snapshot = replay['snapshot'] as Map<String, dynamic>;
    (snapshot['stamp'] as Map<String, dynamic>)
      ..['revision'] = 0
      ..['stateDigest'] = 'a' * 64;
    final units = snapshot['units'] as List<dynamic>;
    (units.last as Map<String, dynamic>)['coordinate'] = {'col': 2, 'row': 0};
    initial = AonwPlayerViewSnapshot.fromJson(snapshot);
    ai = AonwAiTurnAdvancedResponse.fromJson(
      _response('observed_ai_turn_response.json'),
    );
  }

  late final AonwPlayerViewSnapshot initial;
  late final AonwAiTurnAdvancedResponse ai;
  late final map = testMapScene(
    cols: 12,
    rows: 5,
    contentHash: initial.stamp.mapHash,
  ).map;

  PlayerMapView player({List<MapFeedbackCueView> recentFeedback = const []}) =>
      const PlayerMapViewMapper().fromWire(
        initial,
        map: map,
        actorPlayerId: 'human',
        recentFeedback: recentFeedback,
      );

  ObservedCommandFrames observe({
    PlayerMapView? initialPlayer,
    String recipient = 'human',
    List<AonwCommandResult>? commands,
    AonwSessionStamp? finalStamp,
  }) => ObservedCommandFrames(
    initialSnapshot: initial,
    initialPlayer: initialPlayer ?? player(),
    map: map,
    recipientPlayerId: recipient,
    commands: commands ?? ai.commands,
    finalStamp: finalStamp ?? ai.stamp,
  );
}

Map<String, dynamic> _response(String name) {
  final json =
      jsonDecode(
            File(
              '../../tests/fixtures/client_protocol/$name',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return (json['outcome'] as Map<String, dynamic>)['response']
      as Map<String, dynamic>;
}

AonwCommandResult _withEvents(
  AonwCommandResult command,
  List<AonwClientEvent> events,
) => AonwCommandResult(
  stamp: command.stamp,
  outcome: command.outcome,
  events: events,
  evidence: command.evidence,
  viewPatch: command.viewPatch,
);

AonwCommandResult _unchanged(
  AonwPlayerViewSnapshot snapshot, {
  bool rejected = false,
}) => AonwCommandResult(
  stamp: snapshot.stamp,
  outcome: rejected
      ? const AonwCommandRejected(AonwCommandRejectionCode.staleRevision)
      : const AonwCommandAccepted(),
  events: const [],
  evidence: null,
  viewPatch: AonwPlayerViewPatch(
    fromRevision: snapshot.stamp.revision,
    toRevision: snapshot.stamp.revision,
    turn: snapshot.turn,
    turnMode: snapshot.turnMode,
    turnLifecycle: null,
    outcome: null,
    pendingAction: null,
    cityFoundingDraft: null,
    diplomacy: null,
    upsertedUnits: const [],
    removedUnitIds: const [],
    upsertedCities: const [],
    removedCityIds: const [],
    upsertedArtifacts: const [],
    removedArtifactIds: const [],
    upsertedFieldImprovements: const [],
    removedFieldImprovementCoordinates: const [],
    upsertedRoads: const [],
    removedRoadCoordinates: const [],
  ),
);
