import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/hex_inspection_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/hex_inspection_view.dart';
import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = _Fixture();

  test(
    'preserves authoritative assessment without adding authored resources',
    () {
      final view = fixture.mapResult();
      expect(view.resources.map((value) => value.name), ['deer', 'coal']);
      expect(view.baseTerrain, MapTerrain.forest);
      expect(view.terrainTags, [MapTerrain.forest]);
      expect(view.height, 0);
      expect(view.hasRiver, isFalse);
      expect(view.canFoundCityOnTerrain, isTrue);
      expect((view.yieldValue.food, view.yieldValue.production), (2, 2));
      expect((view.yieldValue.gold, view.yieldValue.defense), (0, 0));
      expect(
        (view.score.city, view.score.defense, view.score.economy),
        (5, 5, 4),
      );
      expect(view.kind, HexAssessmentKindView.forestForge);
      expect(view.recommendation, HexRecommendationView.defendHere);
      expect(view.tags.map((value) => value.name), [
        'fertile',
        'defense',
        'production',
        'strategic',
        'city',
      ]);
      expect(view.improvementAccess, isA<HexOutsideControlledCityView>());
      expect(view.improvements.map((value) => value.kind.name), [
        'lumberMill',
        'camp',
        'coalShaft',
      ]);
      expect(view.improvements.map((value) => value.requiredTechnology?.name), [
        'woodworking',
        'hunting',
        'coalMining',
      ]);
      expect(view.improvements.map((value) => value.technologyUnlocked), [
        false,
        false,
        true,
      ]);
      expect(view.improvements.map((value) => value.buildTurns), [3, 4, 5]);
      expect(view.improvements.last.yieldDelta.production, 3);
      expect(() => view.resources.clear(), throwsUnsupportedError);
      expect(() => view.terrainTags.clear(), throwsUnsupportedError);
      expect(() => view.tags.clear(), throwsUnsupportedError);
      expect(() => view.improvements.clear(), throwsUnsupportedError);
    },
  );

  test('maps every assessment, recommendation and tag', () {
    for (final kind in AonwHexAssessmentKind.values) {
      expect(
        fixture.mapResult(profile: {'kind': kind.name}).kind.name,
        kind.name,
      );
    }
    for (final value in AonwHexRecommendation.values) {
      expect(
        fixture
            .mapResult(profile: {'recommendation': value.name})
            .recommendation
            .name,
        value.name,
      );
    }
    final tags = AonwHexAssessmentTag.values
        .map((value) => value.name)
        .toList();
    expect(
      fixture.mapResult(profile: {'tags': tags}).tags.map((tag) => tag.name),
      tags,
    );
  });

  test('maps all improvement access states and nullable technology', () {
    expect(
      fixture
          .mapResult(
            profile: {
              'improvementAccess': {'kind': 'cityCenter'},
            },
          )
          .improvementAccess,
      isA<HexCityCenterView>(),
    );
    expect(
      fixture
          .mapResult(
            profile: {
              'improvementAccess': {'kind': 'alreadyImproved'},
            },
          )
          .improvementAccess,
      isA<HexAlreadyImprovedView>(),
    );
    final view = fixture.mapResult(
      profile: {
        'improvementAccess': {'kind': 'controlledCity', 'cityId': 'city-7'},
        'improvements': [
          {
            'kind': 'farm',
            'requiredTechnology': null,
            'technologyUnlocked': true,
            'buildTurns': 2,
            'yieldDelta': {'food': 9, 'production': 8, 'gold': 7, 'defense': 6},
          },
        ],
      },
    );
    expect((view.improvementAccess as HexControlledCityView).cityId, 'city-7');
    expect(view.improvements.single.requiredTechnology, isNull);
    final delta = view.improvements.single.yieldDelta;
    expect(
      (delta.food, delta.production, delta.gold, delta.defense),
      (9, 8, 7, 6),
    );
  });

  test('rejects a mismatched state stamp or request revision', () {
    for (final change in <Map<String, Object?>>[
      {'revision': 1},
      {'stateDigest': 'd' * 64},
      {'mapHash': 'd' * 64},
      {'rulesetHash': 'd' * 64},
    ]) {
      expect(() => fixture.mapResult(stamp: change), throwsFormatException);
    }
    expect(() => fixture.mapResult(revision: 1), throwsFormatException);
  });

  test('rejects mismatched tile facts and coordinates', () {
    for (final change in <Map<String, Object?>>[
      {
        'coordinate': {'col': 1, 'row': 0},
      },
      {'baseTerrain': 'plains'},
      {'height': 1},
      {
        'terrainTags': ['forest', 'hills'],
      },
    ]) {
      expect(() => fixture.mapResult(profile: change), throwsFormatException);
    }
    expect(
      () => fixture.mapResult(coordinate: (col: 9, row: 9)),
      throwsFormatException,
    );
  });
}

final class _Fixture {
  _Fixture() {
    final stamp = _wire().stamp;
    map = MapView(
      mapId: 'assessment',
      contentHash: stamp.mapHash,
      gridLayout: MapGridLayout.oddQFlatTop,
      cols: 1,
      rows: 1,
      defaultZoom: 1,
      tiles: [
        MapTileView(
          coordinate: (col: 0, row: 0),
          displayTerrain: MapTerrain.forest,
          yieldTerrain: MapTerrain.forest,
          movementTerrains: [MapTerrain.forest],
          terrainTags: [MapTerrain.forest],
          resources: [MapResource.oil],
          height: 0,
        ),
      ],
      objectives: [],
    );
    player = PlayerMapView.preview(
      actorPlayerId: 'player',
      turn: 1,
      pendingAction: null,
      units: [],
      stamp: SessionStampView(
        revision: stamp.revision,
        stateDigest: stamp.stateDigest,
        mapHash: stamp.mapHash,
        rulesetHash: stamp.rulesetHash,
      ),
    );
  }
  late final MapView map;
  late final PlayerMapView player;

  HexInspectionView mapResult({
    Map<String, Object?> profile = const {},
    Map<String, Object?> stamp = const {},
    int revision = 0,
    MapHexCoordinate coordinate = (col: 0, row: 0),
  }) => const HexInspectionViewMapper().fromWire(
    _wire(profile: profile, stamp: stamp),
    map: map,
    player: player,
    expectedRevision: revision,
    coordinate: coordinate,
  );
}

AonwHexInspectionResult _wire({
  Map<String, Object?> profile = const {},
  Map<String, Object?> stamp = const {},
}) {
  final json =
      jsonDecode(
            File(
              '../../tests/fixtures/client_protocol/hex_inspection_response.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final result = json['outcome']['response']['result'] as Map<String, dynamic>;
  (result['inspection'] as Map<String, dynamic>).addAll(profile);
  (result['stamp'] as Map<String, dynamic>).addAll(stamp);
  return AonwClientResponse.parse(
        jsonEncode(json),
      ).require<AonwQueryResponse>().result
      as AonwHexInspectionResult;
}
