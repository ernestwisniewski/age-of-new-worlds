import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/infrastructure/production_view_mapper.dart';
import 'package:aonw_flutter/features/production/read_model/production_details_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  final scene = testMapScene(cities: [testCityView()]);
  const mapper = ProductionViewMapper();
  ProductionDetailsView map(
    Map<String, Object?> value,
    ProductionTargetView target,
  ) => mapper.details(
    AonwQueryResult.fromJson(value) as AonwProductionDetailsResult,
    map: scene.map,
    player: scene.player,
    cityId: 'preview-city',
    target: target,
    expectedRevision: 0,
  );

  test(
    'maps effects without estimating output or changing authoritative priorities',
    () {
      final building = map(
        _fixture('building'),
        const BuildingProductionTargetView('workshop'),
      );
      final effects = building.effects as BuildingProductionDetailsView;
      expect(
        (effects.current.production, effects.completed.production),
        (3, 5),
      );
      expect(effects.requirements.single.met, isTrue);
      final unit = map(
        _fixture('unit'),
        const UnitProductionTargetView(VisibleUnitKind.tank),
      );
      expect(
        (unit.effects as UnitProductionDetailsView).supplyUsedWithoutCityQueue,
        3,
      );
      final wonder = map(
        _fixture('wonder'),
        const WonderProductionTargetView('greatLibrary'),
      );
      expect(
        (wonder.effects as WonderProductionDetailsView).requirements,
        hasLength(4),
      );
      final ranks = mapper.buildingRanks(
        _ranks(),
        map: scene.map,
        player: scene.player,
        cityId: 'preview-city',
        expectedRevision: 0,
      );
      expect(ranks.buildings, hasLength(59));
      expect(ranks.buildings.first.recommended, 10040);
    },
  );

  test(
    'rejects response for another city target revision digest or ruleset',
    () {
      final mutations = <void Function(Map<String, Object?>)>[
        (value) => value['cityId'] = 'other',
        (value) => (value['stamp'] as Map)['revision'] = 1,
        (value) => (value['stamp'] as Map)['stateDigest'] = 'a' * 64,
        (value) => (value['stamp'] as Map)['rulesetHash'] = 'b' * 64,
        (value) => value['effects'] = _fixture('unit')['effects'],
      ];
      for (final change in mutations) {
        final value = _fixture('building');
        change(value);
        expect(
          () => map(value, const BuildingProductionTargetView('workshop')),
          throwsFormatException,
        );
      }
      expect(
        () => map(
          _fixture('building'),
          const BuildingProductionTargetView('granary'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'rejects partial duplicate rankings and inconsistent requirements or allocations',
    () {
      for (final ranks in [_ranks(complete: false), _ranks(duplicate: true)]) {
        expect(
          () => mapper.buildingRanks(
            ranks,
            map: scene.map,
            player: scene.player,
            cityId: 'preview-city',
            expectedRevision: 0,
          ),
          throwsFormatException,
        );
      }
      final building = _fixture('building');
      final effects = (building['effects'] as Map)['details'] as Map;
      effects['riverApplications'] = 4;
      expect(
        () => map(building, const BuildingProductionTargetView('workshop')),
        throwsFormatException,
      );
      final unit = _fixture('unit');
      ((unit['effects'] as Map)['details']
          as Map)['affordableResourceOptionIndices'] = [
        1,
      ];
      expect(
        () => map(unit, const UnitProductionTargetView(VisibleUnitKind.tank)),
        throwsFormatException,
      );
    },
  );
}

Map<String, Object?> _fixture(String kind) {
  final name = kind == 'ranks' ? 'building_ranks' : '${kind}_details';
  final document =
      jsonDecode(
            File(
              '../../tests/fixtures/client_protocol/production_${name}_response.json',
            ).readAsStringSync(),
          )
          as Map;
  final outcome = document['outcome'] as Map;
  final response = outcome['response'] as Map;
  final value = response['result'] as Map<String, Object?>;
  final stamp = testSessionStamp();
  value['stamp'] = {
    'revision': stamp.revision,
    'stateDigest': stamp.stateDigest,
    'mapHash': stamp.mapHash,
    'rulesetHash': stamp.rulesetHash,
  };
  value['cityId'] = 'preview-city';
  return value;
}

AonwProductionBuildingRanksResult _ranks({
  bool complete = true,
  bool duplicate = false,
}) {
  final value = _fixture('ranks');
  final rank = (value['buildings'] as List).single as Map<String, Object?>;
  if (complete) {
    value['buildings'] = [
      for (final building in AonwCityBuildingType.values)
        {...rank, 'building': duplicate ? 'workshop' : building.name},
    ];
  }
  return AonwQueryResult.fromJson(value) as AonwProductionBuildingRanksResult;
}
