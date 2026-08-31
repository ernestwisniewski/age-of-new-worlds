import 'dart:convert';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes current research query and command exactly', () {
    expect(_request(AonwResearchRequest.options(expectedRevision: 8)), {
      'type': 'query',
      'query': {'type': 'researchOptions', 'expectedRevision': 8},
    });
    expect(
      _request(
        AonwResearchRequest.select(
          expectedRevision: 8,
          technology: AonwTechnologyId.agriculture,
        ),
      ),
      {
        'type': 'dispatch',
        'command': {
          'type': 'selectTechnology',
          'expectedRevision': 8,
          'technologyId': 'agriculture',
        },
      },
    );
  });

  test('parses complete engine-owned research options exactly', () {
    final result =
        AonwQueryResult.fromJson({
              'type': 'researchOptions',
              'stamp': _stamp,
              'playerId': 'p1',
              'activeTechnologyId': null,
              'scienceOverflow': 3,
              'scienceYield': {
                'total': 5,
                'byCityId': {'c1': 5},
                'sources': [
                  {'cityId': 'c1', 'amount': 5, 'kind': 'cityScience'},
                ],
              },
              'options': [
                {
                  'technologyId': 'agriculture',
                  'availability': 'available',
                  'effectiveCost': 12,
                  'progress': 6,
                  'boostDiscountBasisPoints': 5000,
                  'prerequisites': <Object?>[],
                  'blockedBy': ['hunting'],
                  'unlocks': [
                    {'kind': 'building', 'buildingType': 'granary'},
                    {'kind': 'improvement', 'improvement': 'farm'},
                    {'kind': 'resourceVisibility', 'resource': 'wheat'},
                    {'kind': 'unit', 'unitType': 'worker'},
                    {'kind': 'wonder', 'wonderType': 'greatLibrary'},
                  ],
                },
              ],
            })
            as AonwResearchOptionsResult;

    expect(result.playerId, 'p1');
    expect(result.scienceOverflow, 3);
    expect(result.scienceYield.byCityId, {'c1': 5});
    expect(result.options.single.technology, AonwTechnologyId.agriculture);
    expect(
      result.options.single.availability,
      AonwTechnologyAvailability.available,
    );
    expect(result.options.single.unlocks, hasLength(5));
  });

  test('research parser rejects unknown values and fields', () {
    expect(
      () => AonwResearchOption.fromJson({
        'technologyId': 'unknownTechnology',
        'availability': 'available',
        'effectiveCost': 12,
        'progress': 0,
        'boostDiscountBasisPoints': 0,
        'prerequisites': <Object?>[],
        'blockedBy': <Object?>[],
        'unlocks': <Object?>[],
      }),
      throwsFormatException,
    );
    expect(
      () => AonwTechnologyUnlock.fromJson({
        'kind': 'building',
        'buildingType': 'granary',
        'unexpectedName': 'Granary',
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

const _stamp = <String, Object?>{
  'revision': 8,
  'stateDigest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'mapHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'rulesetHash':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
};
