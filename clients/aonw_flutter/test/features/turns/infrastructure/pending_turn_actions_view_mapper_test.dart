import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/turns/infrastructure/pending_turn_actions_view_mapper.dart';
import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  final scene = testMapScene(
    units: [testVisibleUnit()],
    cities: [testCityView()],
  );
  const mapper = PendingTurnActionsViewMapper();
  PendingTurnActionsView map({
    AonwSessionStamp? stamp,
    List<AonwPendingTurnAction> actions = _actions,
    bool canActivate = true,
    int revision = 0,
  }) => mapper.fromWire(
    AonwPendingTurnActionsResult(
      stamp: stamp ?? _stamp(),
      canActivate: canActivate,
      actions: actions,
    ),
    map: scene.map,
    player: scene.player,
    expectedRevision: revision,
  );

  test('preserves engine order, recipient and immutable targets', () {
    final result = map();
    expect(result.actorPlayerId, scene.player.actorPlayerId);
    expect(result.stamp.stateDigest, scene.player.stamp.stateDigest);
    // Deliberately keep an engine-selected order instead of sorting in the mapper.
    expect(result.actions.first, isA<PendingResearchTurnActionView>());
    final city = result.actions[1] as PendingCityProductionTurnActionView;
    final unit = result.actions.last as PendingUnitTurnActionView;
    expect((city.cityId, city.coordinate), ('preview-city', (col: 1, row: 1)));
    expect(
      (unit.unitId, unit.coordinate),
      ('preview-commander', (col: 0, row: 0)),
    );
    expect(result.canActivate, isTrue);
    expect(() => result.actions.clear(), throwsUnsupportedError);
    final source = [...result.actions];
    final copy = PendingTurnActionsView(
      stamp: result.stamp,
      actorPlayerId: result.actorPlayerId,
      canActivate: false,
      actions: source,
    );
    source.clear();
    expect(copy.actions.length, 3);
    expect(copy.canActivate, isFalse);
    expect(map(canActivate: false).actions.length, 3);
    expect(map(actions: []).canActivate, isTrue);
  });

  test('rejects every mismatched stamp field and expected revision', () {
    for (final stamp in [
      _stamp(revision: 1),
      _stamp(digest: 'd' * 64),
      _stamp(map: 'd' * 64),
      _stamp(rules: 'd' * 64),
    ]) {
      expect(() => map(stamp: stamp), throwsFormatException);
    }
    expect(() => map(revision: 1), throwsFormatException);
    final wrongMap = testMapScene(contentHash: 'd' * 64).map;
    expect(
      () => mapper.fromWire(
        AonwPendingTurnActionsResult(
          stamp: _stamp(),
          canActivate: true,
          actions: [],
        ),
        map: wrongMap,
        player: scene.player,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('rejects absent identities and mismatched coordinates', () {
    for (final action in [
      const AonwPendingUnitTurnAction(
        unitId: 'absent',
        coordinate: AonwCoordinate(col: 0, row: 0),
      ),
      const AonwPendingCityProductionTurnAction(
        cityId: 'absent',
        coordinate: AonwCoordinate(col: 1, row: 1),
      ),
      const AonwPendingUnitTurnAction(
        unitId: 'preview-commander',
        coordinate: AonwCoordinate(col: 1, row: 0),
      ),
      const AonwPendingCityProductionTurnAction(
        cityId: 'preview-city',
        coordinate: AonwCoordinate(col: 99, row: 99),
      ),
    ]) {
      expect(() => map(actions: [action]), throwsFormatException);
    }
  });

  test('rejects foreign entities and duplicate targets without filtering', () {
    final foreign = testMapScene(
      units: [testVisibleUnit(ownerPlayerId: 'other')],
      cities: [testCityView(ownerPlayerId: 'other', owned: false)],
    );
    for (final action in _actions.skip(1)) {
      expect(
        () => mapper.fromWire(
          AonwPendingTurnActionsResult(
            stamp: _stamp(),
            canActivate: true,
            actions: [action],
          ),
          map: foreign.map,
          player: foreign.player,
          expectedRevision: 0,
        ),
        throwsFormatException,
      );
    }
    for (final action in _actions) {
      expect(() => map(actions: [action, action]), throwsFormatException);
    }
  });
}

const _actions = <AonwPendingTurnAction>[
  AonwPendingResearchTurnAction(),
  AonwPendingCityProductionTurnAction(
    cityId: 'preview-city',
    coordinate: AonwCoordinate(col: 1, row: 1),
  ),
  AonwPendingUnitTurnAction(
    unitId: 'preview-commander',
    coordinate: AonwCoordinate(col: 0, row: 0),
  ),
];
AonwSessionStamp _stamp({
  int revision = 0,
  String? digest,
  String? map,
  String? rules,
}) => AonwSessionStamp(
  revision: revision,
  stateDigest: digest ?? 'b' * 64,
  mapHash: map ?? 'a' * 64,
  rulesetHash: rules ?? 'c' * 64,
);
