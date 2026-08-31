import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes every current production query and command exactly', () {
    expect(
      _request(
        AonwProductionRequest.options(expectedRevision: 8, cityId: 'c1'),
      ),
      _query('productionOptions', 8, {'cityId': 'c1'}),
    );
    expect(
      _request(AonwProductionRequest.strategicResources(expectedRevision: 8)),
      _query('strategicResourceProjection', 8),
    );
    expect(
      _request(
        AonwProductionRequest.startBuilding(
          expectedRevision: 8,
          cityId: 'c1',
          building: AonwCityBuildingType.workshop,
        ),
      ),
      _command('startBuilding', 8, 'c1', {'building': 'workshop'}),
    );
    expect(
      _request(
        AonwProductionRequest.startUnit(
          expectedRevision: 8,
          cityId: 'c1',
          unit: AonwUnitKind.tank,
          resourceOptionIndex: 0,
        ),
      ),
      _command('startUnitProduction', 8, 'c1', {
        'unit': 'tank',
        'resourceOptionIndex': 0,
      }),
    );
    expect(
      _request(
        AonwProductionRequest.startProject(
          expectedRevision: 8,
          cityId: 'c1',
          project: AonwCityProjectType.research,
        ),
      ),
      _command('startCityProject', 8, 'c1', {'project': 'research'}),
    );
    expect(
      _request(
        AonwProductionRequest.startWonder(
          expectedRevision: 8,
          cityId: 'c1',
          wonder: AonwWonderType.greatLibrary,
        ),
      ),
      _command('startWonder', 8, 'c1', {'wonder': 'greatLibrary'}),
    );
    expect(
      _request(
        AonwProductionRequest.setSpecialization(
          expectedRevision: 8,
          cityId: 'c1',
          specialization: AonwCitySpecialization.industry,
        ),
      ),
      _command('setCitySpecialization', 8, 'c1', {
        'specialization': 'industry',
      }),
    );
    expect(
      _request(AonwProductionRequest.rush(expectedRevision: 8, cityId: 'c1')),
      _command('rushProduction', 8, 'c1'),
    );
  });

  test('parses exact production options and strategic resource projection', () {
    final production =
        AonwQueryResult.fromJson({
              'type': 'productionOptions',
              'stamp': _stamp,
              'cityId': 'c1',
              'currentTarget': {'kind': 'project', 'projectType': 'research'},
              'investedProduction': 4,
              'productionOverflow': 1,
              'buildings': [
                {
                  'target': {'kind': 'building', 'buildingType': 'workshop'},
                  'cost': 15,
                  'rejection': null,
                },
              ],
              'units': [
                {
                  'option': {
                    'target': {'kind': 'unit', 'unitType': 'tank'},
                    'cost': 32,
                    'rejection': 'unit_production_missing_strategic_resource',
                  },
                  'resourceOptions': [
                    {'oil': 2},
                  ],
                  'affordableResourceOptionIndices': <Object?>[],
                },
              ],
              'projects': [
                {
                  'target': {'kind': 'project', 'projectType': 'research'},
                  'cost': 0,
                  'rejection': null,
                },
              ],
              'wonders': <Object?>[],
              'specializations': [
                {
                  'specialization': 'industry',
                  'requiredBuilding': 'workshop',
                  'rejection': null,
                },
              ],
            })
            as AonwProductionOptionsResult;
    expect(production.cityId, 'c1');
    expect(production.investedProduction, 4);
    expect(production.buildings.single.cost, 15);
    expect(
      production.units.single.option.rejection,
      AonwCommandRejectionCode.unitProductionMissingStrategicResource,
    );
    expect(
      production.units.single.resourceOptions.single[AonwResourceType.oil],
      2,
    );

    final resources =
        AonwQueryResult.fromJson({
              'type': 'strategicResourceProjection',
              'stamp': _stamp,
              'playerId': 'p1',
              'output': [
                {'resource': 'oil', 'amount': 2},
              ],
              'sources': [
                {
                  'cityId': 'c1',
                  'coordinate': {'col': 3, 'row': 4},
                  'resource': 'oil',
                  'improvement': 'oilWell',
                  'amountPerTurn': 2,
                },
              ],
            })
            as AonwStrategicResourceProjectionResult;
    expect(resources.playerId, 'p1');
    expect(resources.output.single.amount, 2);
    expect(
      resources.sources.single.improvement,
      AonwFieldImprovementKind.oilWell,
    );
  });

  test('production projections reject unknown and incomplete fields', () {
    expect(
      () => AonwProductionOption.fromJson({
        'target': {'kind': 'project', 'projectType': 'research'},
        'cost': 0,
        'rejection': null,
        'clientAvailability': true,
      }),
      throwsFormatException,
    );
    expect(
      () => AonwStrategicResourceAmount.fromJson({
        'resource': 'unknownResource',
        'amount': 1,
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

Map<String, Object?> _query(
  String type,
  int expectedRevision, [
  Map<String, Object?> fields = const {},
]) => {
  'type': 'query',
  'query': {'type': type, 'expectedRevision': expectedRevision, ...fields},
};

Map<String, Object?> _command(
  String type,
  int expectedRevision,
  String cityId, [
  Map<String, Object?> fields = const {},
]) => {
  'type': 'dispatch',
  'command': {
    'type': type,
    'expectedRevision': expectedRevision,
    'cityId': cityId,
    ...fields,
  },
};

const _stamp = <String, Object?>{
  'revision': 8,
  'stateDigest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'mapHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'rulesetHash':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
};
