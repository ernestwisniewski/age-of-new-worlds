part of 'map_feedback_mapper_test.dart';

void soundMapperTests() {
  test(
    'rejected or unchanged commands are silent and later commands sound again',
    () {
      expect(_soundFeedback([_moved], accepted: false), isEmpty);
      expect(_soundFeedback([_moved], after: _snapshot(revision: 0)), isEmpty);
      expect(_soundFeedback([_moved]).single.identity.revision, 1);
      expect(
        _soundFeedback(
          [_moved],
          before: _snapshot(),
          after: _snapshot(revision: 2),
        ).single.identity.revision,
        2,
      );
    },
  );

  test('sounds each accepted kind once at its first audible event', () {
    final cues = _soundFeedback([
      _moved,
      _moved,
      _resolved('enemy'),
      _resolved('enemy'),
      ..._events,
      const AonwCityBuiltBuildingEvent(
        cityId: 'city',
        buildingType: AonwCityBuildingType.granary,
      ),
    ]);
    expect(cues.map((cue) => cue.sound), [
      MapSoundKindView.movement,
      MapSoundKindView.combat,
      MapSoundKindView.city,
    ]);
    expect(cues.map((cue) => cue.identity.eventIndex), [0, 2, 4]);
    expect(cues.last, isA<MapParticleCueView>());
  });

  test('foreign movement combat and production remain silent', () {
    final cues = _soundFeedback(
      [_moved, _resolved('enemy'), _events[1]],
      before: _snapshot(revision: 0, unitOwner: 'other', cityOwner: 'other'),
      after: _snapshot(unitOwner: 'other', cityOwner: 'other'),
    );
    expect(cues, isEmpty);
  });

  test('uses the previous owner of a defender removed after combat', () {
    final cues = _soundFeedback([
      _resolved('enemy'),
    ], after: _snapshot(hasUnit: false));
    expect(cues.single.sound, MapSoundKindView.combat);
    expect(cues.single.coordinate, (col: 0, row: 1));
  });

  test('anchors an owned attack on its disclosed attacker when needed', () {
    final cues = _soundFeedback(const [
      AonwCombatResolvedEvent(
        attackerUnitId: 'unit',
        target: AonwUnitCombatTarget(unitId: 'newly-visible'),
      ),
    ]);
    expect(cues.single.sound, MapSoundKindView.combat);
    expect(cues.single.coordinate, (col: 0, row: 1));
  });

  test('city combat never borrows ownership from a unit with the same id', () {
    const combat = AonwCombatResolvedEvent(
      attackerUnitId: 'enemy',
      target: AonwCityCombatTarget(cityId: 'unit'),
    );
    expect(_soundFeedback([combat]), isEmpty);
    expect(
      _soundFeedback(const [
        AonwCombatResolvedEvent(
          attackerUnitId: 'enemy',
          target: AonwCityCombatTarget(cityId: 'city'),
        ),
      ]).single.coordinate,
      (col: 1, row: 0),
    );
  });

  test(
    'capture sounds for both owners but production uses the current one',
    () {
      const capture = AonwCityCapturedEvent(
        attackerUnitId: 'enemy',
        target: AonwCityCombatTarget(cityId: 'city'),
      );
      for (final losing in [true, false]) {
        final cues = _soundFeedback(
          [capture],
          before: _snapshot(
            revision: 0,
            cityOwner: losing ? 'preview-player' : 'other',
          ),
          after: _snapshot(cityOwner: losing ? 'other' : 'preview-player'),
        );
        expect(cues.single.sound, MapSoundKindView.city);
      }
      expect(
        _soundFeedback([_events[1]], after: _snapshot(cityOwner: 'other')),
        isEmpty,
      );
      expect(
        _soundFeedback(
          [capture],
          before: _snapshot(revision: 0, cityOwner: 'other'),
          after: _snapshot(cityOwner: 'third'),
        ),
        isEmpty,
      );
    },
  );

  test('building and wonder completion sound without an extra particle', () {
    for (final event in const <AonwClientEvent>[
      AonwCityBuiltBuildingEvent(
        cityId: 'city',
        buildingType: AonwCityBuildingType.granary,
      ),
      AonwCityBuiltWonderEvent(
        cityId: 'city',
        ownerPlayerId: 'preview-player',
        wonderType: AonwWonderType.greatLibrary,
      ),
    ]) {
      final cue = _soundFeedback([event]).single;
      expect(cue, isA<MapSoundCueView>());
      expect(cue.sound, MapSoundKindView.city);
    }
    expect(_soundFeedback([_events[2], _events[3]]), isEmpty);
  });

  test('hidden and out of map events do not consume the audible kind', () {
    final cues = _soundFeedback(const [
      AonwUnitMovedEvent(
        unitId: 'unit',
        from: AonwCoordinate(col: 0, row: 1),
        to: AonwCoordinate(col: 20, row: 20),
      ),
      AonwUnitMovedEvent(
        unitId: 'unit',
        from: AonwCoordinate(col: 20, row: 20),
        to: AonwCoordinate(col: 1, row: 0),
      ),
      AonwUnitMovedEvent(
        unitId: 'unit',
        from: AonwCoordinate(col: 1, row: 0),
        to: AonwCoordinate(col: 2, row: 1),
      ),
    ], after: _snapshot(visible: const [AonwCoordinate(col: 2, row: 1)]));
    expect(cues.single.identity.eventIndex, 2);
    expect(cues.single.coordinate, (col: 2, row: 1));
  });
}

List<MapFeedbackCueView> _soundFeedback(
  List<AonwClientEvent> events, {
  AonwPlayerViewSnapshot? before,
  AonwPlayerViewSnapshot? after,
  bool accepted = true,
}) {
  final map = feedbackSnapshot().map;
  final snapshot = after ?? _snapshot();
  final previous = const PlayerMapViewMapper().fromWire(
    before ?? _snapshot(revision: 0),
    map: map,
    actorPlayerId: 'preview-player',
  );
  return mapCommandFeedback(
    command: _command(snapshot, events, accepted: accepted),
    snapshot: snapshot,
    previous: previous,
    map: map,
  ).where((cue) => cue.sound != null).toList();
}
