import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/city_planning_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  final scene = testMapScene();
  final stamp = scene.player.stamp;
  final wireStamp = AonwSessionStamp(
    revision: stamp.revision,
    stateDigest: stamp.stateDigest,
    mapHash: stamp.mapHash,
    rulesetHash: stamp.rulesetHash,
  );
  const a = AonwCoordinate(col: 0, row: 0);
  const b = AonwCoordinate(col: 1, row: 0);
  const outside = AonwCoordinate(col: 9, row: 9);
  final mapper = CityPlanningViewMapper();
  AonwCityPlanningResult wire(
    List<AonwCoordinate> sites,
    List<AonwCoordinate> growth,
  ) => AonwCityPlanningResult(
    stamp: wireStamp,
    citySites: sites,
    growthTiles: growth,
  );

  test('maps disclosed authoritative coordinates into immutable sets', () {
    final value = mapper.fromWire(
      wire([a], [a, b]),
      map: scene.map,
      player: scene.player,
      expectedRevision: 0,
    );
    expect(value.citySites, {(col: 0, row: 0)});
    expect(value.growthTiles, {(col: 0, row: 0), (col: 1, row: 0)});
    expect(() => value.citySites.clear(), throwsUnsupportedError);
  });

  test(
    'rejects duplicates, unordered, outside and inconsistent coordinates',
    () {
      for (final value in [
        wire([a, a], [a, b]),
        wire([], [b, a]),
        wire([], [outside]),
        wire([a], [b]),
      ]) {
        expect(
          () => mapper.fromWire(
            value,
            map: scene.map,
            player: scene.player,
            expectedRevision: 0,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects stale identities and hidden coordinates', () {
    for (final player in [
      PlayerMapView.preview(
        turn: 1,
        pendingAction: null,
        units: const [],
        actorPlayerId: scene.player.actorPlayerId,
        stamp: SessionStampView(
          revision: 1,
          stateDigest: stamp.stateDigest,
          mapHash: stamp.mapHash,
          rulesetHash: stamp.rulesetHash,
        ),
      ),
      PlayerMapView(
        actorPlayerId: scene.player.actorPlayerId,
        stamp: stamp,
        turnMode: scene.player.turnMode,
        participants: scene.player.participants,
        fog: MapFogView(
          enabled: true,
          discoveredHexes: const [],
          visibleHexes: const [],
        ),
        economy: scene.player.economy,
        research: scene.player.research,
        victory: scene.player.victory,
        turnView: scene.player.turnView,
        diplomacy: scene.player.diplomacy,
        units: const [],
        cities: const [],
        artifacts: const [],
        fieldImprovements: const [],
        roads: const [],
      ),
    ]) {
      expect(
        () => mapper.fromWire(
          wire([a], [a]),
          map: scene.map,
          player: player,
          expectedRevision: 0,
        ),
        throwsFormatException,
      );
    }
  });
}
