import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes current logistics query and command families', () {
    expect(
      _request(
        AonwClientRequest.unitLogisticsOptions(
          expectedRevision: 7,
          unitId: 'unit-1',
        ),
      ),
      {
        'type': 'query',
        'query': {
          'type': 'unitLogisticsOptions',
          'expectedRevision': 7,
          'unitId': 'unit-1',
        },
      },
    );
    final commands = [
      AonwClientRequest.autoExploreUnit(expectedRevision: 7, unitId: 'unit-1'),
      AonwClientRequest.assignMerchantTradeRoute(
        expectedRevision: 7,
        unitId: 'unit-1',
        destinationCityId: 'city-2',
      ),
      AonwClientRequest.moveMerchantToCity(
        expectedRevision: 7,
        unitId: 'unit-1',
        destinationCityId: 'city-2',
      ),
      AonwClientRequest.detachTroop(
        expectedRevision: 7,
        unitId: 'unit-1',
        troopKind: 'warrior',
      ),
    ];
    expect(
      commands.map((request) => (_request(request)['command'] as Map)['type']),
      [
        'autoExploreUnit',
        'assignMerchantTradeRoute',
        'moveMerchantToCity',
        'detachTroop',
      ],
    );
  });

  test('parses complete engine-owned logistics options', () {
    final result =
        AonwQueryResult.fromJson({
              'type': 'unitLogisticsOptions',
              'stamp': _stamp,
              'unitId': 'unit-1',
              'autoExplore': {
                'target': {'col': 3, 'row': 2},
                'totalCostUnits': 12,
                'searchMetrics': {
                  'frontierPops': 4,
                  'expandedTiles': 3,
                  'examinedEdges': 14,
                  'heapPushes': 7,
                  'routeRecords': 6,
                },
              },
              'merchantRouteDestinations': [
                {'cityId': 'city-2', 'totalCostUnits': 20},
              ],
              'merchantTravelDestinations': [
                {'cityId': 'city-3', 'totalCostUnits': 16},
              ],
              'detachments': [
                {
                  'troopKind': 'warrior',
                  'destination': {'col': 2, 'row': 1},
                },
              ],
            })
            as AonwUnitLogisticsOptionsResult;

    expect(result.unitId, 'unit-1');
    expect(result.autoExplore?.target.col, 3);
    expect(result.autoExplore?.target.row, 2);
    expect(result.autoExplore?.searchMetrics.examinedEdges, 14);
    expect(result.merchantRouteDestinations.single.cityId, 'city-2');
    expect(result.merchantTravelDestinations.single.totalCostUnits, 16);
    expect(result.detachments.single.troopKind, AonwTroopKind.warrior);
  });

  test('fails closed for incomplete logistics options', () {
    expect(
      () => AonwQueryResult.fromJson({
        'type': 'unitLogisticsOptions',
        'stamp': _stamp,
        'unitId': 'unit-1',
        'autoExplore': null,
        'merchantRouteDestinations': const <Object?>[],
        'merchantTravelDestinations': const <Object?>[],
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _request(AonwClientRequest value) =>
    (jsonDecode(value.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

const _stamp = <String, Object?>{
  'revision': 7,
  'stateDigest':
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  'mapHash': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  'rulesetHash':
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
};
