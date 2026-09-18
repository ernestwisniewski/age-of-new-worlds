import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test(
    'parses the shared building, unit, wonder, project and rank fixtures',
    () {
      final building = _parse('building') as AonwProductionDetailsResult;
      final effects = building.effects as AonwBuildingProductionDetails;
      expect(
        building.option.target.buildingType,
        AonwCityBuildingType.workshop,
      );
      expect(effects.riverApplications, 2);
      expect(effects.current.production, 3);
      expect(effects.completed.production, 5);
      final unit =
          (_parse('unit') as AonwProductionDetailsResult).effects
              as AonwUnitProductionDetails;
      expect(unit.maximumMovementUnits, 4);
      expect(unit.resourceOptions.single[AonwResourceType.oil], 2);
      expect(unit.presenceResources, [AonwMapResource.iron]);
      final wonder =
          (_parse('wonder') as AonwProductionDetailsResult).effects
              as AonwWonderProductionDetails;
      expect(wonder.grantsFreeActiveTechnology, isTrue);
      expect(wonder.requirements.map((value) => value.met), [
        false,
        true,
        false,
        true,
      ]);
      expect(
        (_parse('project') as AonwProductionDetailsResult).effects,
        isA<AonwProjectProductionDetails>(),
      );
      final ranks = _parse('ranks') as AonwProductionBuildingRanksResult;
      expect(ranks.buildings.single.recommended, 10040);
      expect(ranks.buildings.single.turnsForScore, 5);
      expect(() => ranks.buildings.clear(), throwsUnsupportedError);
      expect(() => unit.resourceOptions.single.clear(), throwsUnsupportedError);
      expect(() => effects.requirements.clear(), throwsUnsupportedError);
    },
  );

  test('requires every details field and rejects unknown nested data', () {
    for (final name in ['building', 'unit', 'wonder', 'project', 'ranks']) {
      final original = _result(name);
      for (final path in _objectPaths(original)) {
        if (path.join('/') == 'effects/details/resourceOptions/0') continue;
        final object = _at(original, path) as Map<String, dynamic>;
        for (final field in object.keys) {
          final changed = _result(name);
          (_at(changed, path) as Map).remove(field);
          expect(
            () => AonwQueryResult.fromJson(changed),
            throwsFormatException,
            reason: '$name $path $field',
          );
        }
        final changed = _result(name);
        (_at(changed, path) as Map)['privateOpponentCity'] = 'hidden';
        expect(
          () => AonwQueryResult.fromJson(changed),
          throwsFormatException,
          reason: '$name $path',
        );
      }
    }
  });

  test('serializes target kinds and rank requests with no actor override', () {
    for (final target in const [
      AonwCityProductionTarget.building(AonwCityBuildingType.workshop),
      AonwCityProductionTarget.unit(AonwUnitKind.warrior),
      AonwCityProductionTarget.wonder(AonwWonderType.greatLibrary),
      AonwCityProductionTarget.project(AonwCityProjectType.research),
    ]) {
      final value =
          jsonDecode(
                AonwProductionRequest.details(
                  expectedRevision: 8,
                  cityId: 'city-1',
                  target: target,
                ).toJson(),
              )
              as Map<String, dynamic>;
      expect(value, {
        'apiVersion': aonwClientApiVersion,
        'request': {
          'type': 'query',
          'query': {
            'type': 'productionDetails',
            'expectedRevision': 8,
            'cityId': 'city-1',
            'target': target.toJson(),
          },
        },
      });
    }
    final ranks =
        jsonDecode(
              AonwProductionRequest.buildingRanks(
                expectedRevision: 8,
                cityId: 'city-1',
              ).toJson(),
            )
            as Map<String, dynamic>;
    expect(ranks['request'], {
      'type': 'query',
      'query': {
        'type': 'productionBuildingRanks',
        'expectedRevision': 8,
        'cityId': 'city-1',
      },
    });
  });

  test('unsigned counters reject negative and fractional values', () {
    for (final (name, fields) in [
      (
        'building',
        ['maxRiverApplications', 'riverApplications', 'foodDepositBasisPoints'],
      ),
      (
        'unit',
        [
          'maximumMovementUnits',
          'baseUpkeep',
          'supplyCost',
          'supplyCapacity',
          'supplyUsedWithoutCityQueue',
        ],
      ),
      ('wonder', ['empireGoldBasisPoints', 'empireProductionBasisPoints']),
    ]) {
      for (final field in fields) {
        for (final invalid in [-1, 1.5, '2', true]) {
          final value = _result(name);
          ((_at(value, const ['effects', 'details']))
                  as Map<String, dynamic>)[field] =
              invalid;
          expect(() => AonwQueryResult.fromJson(value), throwsFormatException);
        }
      }
    }
  });
}

String _document(String name) => File(
  '../../tests/fixtures/client_protocol/production_${name == 'ranks' ? 'building_ranks' : '${name}_details'}_response.json',
).readAsStringSync();

AonwQueryResult _parse(String name) => AonwClientResponse.parse(
  _document(name),
).require<AonwQueryResponse>().result;

Map<String, dynamic> _result(String name) =>
    _at(jsonDecode(_document(name)), const ['outcome', 'response', 'result'])
        as Map<String, dynamic>;

Iterable<List<Object>> _objectPaths(
  Object? value, [
  List<Object> path = const [],
]) sync* {
  if (value is Map<String, dynamic>) {
    yield path;
    for (final entry in value.entries) {
      yield* _objectPaths(entry.value, [...path, entry.key]);
    }
  } else if (value is List) {
    for (var index = 0; index < value.length; index++) {
      yield* _objectPaths(value[index], [...path, index]);
    }
  }
}

Object? _at(Object? value, List<Object> path) {
  for (final key in path) {
    value = key is int ? (value as List)[key] : (value as Map)[key];
  }
  return value;
}
