import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/movement_view_mapper.dart';
import 'package:aonw_flutter/features/map/read_model/movement_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('preserves every engine turn without recomputing terrain costs', () {
    final route = _map([1, 1, 2, 2, 3, 3]);
    expect(route.stepTurns, [1, 1, 2, 2, 3, 3]);
    expect(
      route.steps[1].cumulativeCostUnits,
      greaterThan(route.availableMovementUnits),
    );
    expect(() => route.stepTurns.clear(), throwsUnsupportedError);
  });

  test('accepts a spent current turn and an origin-only approach', () {
    expect(_map([1, 2, 3, 3, 4, 4], available: 0).stepTurns, [
      1,
      2,
      3,
      3,
      4,
      4,
    ]);
    expect(_map([1], originOnly: true).stepTurns, [1]);
  });

  test('rejects mismatched, decreasing and skipped step turns', () {
    for (final turns in <List<int>>[
      [],
      [1],
      [1, 1, 2, 2, 3],
      [0, 1, 2, 2, 3, 3],
      [2, 2, 2, 2, 3, 3],
      [1, 2, 1, 2, 3, 3],
      [1, 1, 3, 3, 3, 3],
      [1, 1, 2, 2, 2, 2],
    ]) {
      expect(
        () => _map(turns, estimated: 3),
        throwsFormatException,
        reason: '$turns',
      );
    }
  });
}

RoutePlanView _map(
  List<int> turns, {
  int available = 3,
  int? estimated,
  bool originOnly = false,
}) {
  final value =
      jsonDecode(
            File(
              '../../tests/fixtures/client_protocol/route_plan_response.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  final result =
      ((value['outcome'] as Map)['response'] as Map)['result']
          as Map<String, Object?>;
  result['stepTurns'] = turns;
  result['availableMovementUnits'] = available;
  result['estimatedTurns'] = estimated ?? (turns.isEmpty ? 1 : turns.last);
  if (originOnly) {
    result['steps'] = [(result['steps'] as List).first];
    result['destination'] = {'col': 0, 'row': 0};
    result['totalCostUnits'] = 0;
  }
  final wire =
      AonwClientResponse.parse(
            jsonEncode(value),
          ).require<AonwQueryResponse>().result
          as AonwRoutePlanResult;
  return const MovementViewMapper().routePlan(
    wire,
    map: testMapScene(cols: 6).map,
    unit: testVisibleUnit(id: 'unit-1'),
    expectedTarget: (col: 5, row: 0),
    expectedRevision: 7,
  );
}
