import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('route timing uses the shared Rust request and response fixtures', () {
    expect(
      jsonDecode(
        AonwClientRequest.routePlan(
          expectedRevision: 7,
          unitId: 'unit-1',
          targetCol: 5,
          targetRow: 0,
        ).toJson(),
      ),
      _fixture('route_plan_request.json'),
    );
    final route = _decode(_fixture());
    expect(route.stepTurns, [1, 1, 2, 2, 3, 3]);
    expect(route.stepTurns, hasLength(route.steps.length));
    expect(route.stepTurns.last, route.estimatedTurns);
    expect(
      route.steps[1].enterCostUnits,
      greaterThan(route.availableMovementUnits),
    );
    expect(() => route.stepTurns.clear(), throwsUnsupportedError);
  });

  test('route timing rejects missing fields, wrong types and API versions', () {
    final missing = _fixture();
    _result(missing).remove('stepTurns');
    expect(() => _decode(missing), throwsFormatException);
    for (final invalid in [
      null,
      {},
      [null],
      ['1'],
      [-1],
      [1.5],
      [true],
    ]) {
      final value = _fixture();
      _result(value)['stepTurns'] = invalid;
      expect(() => _decode(value), throwsFormatException, reason: '$invalid');
    }
    final unknown = _fixture();
    _result(unknown)['futureField'] = true;
    expect(() => _decode(unknown), throwsFormatException);
    for (final version in [
      aonwClientApiVersion - 1,
      aonwClientApiVersion + 1,
    ]) {
      expect(
        () => _decode({..._fixture(), 'apiVersion': version}),
        throwsFormatException,
      );
    }
  });
}

Map<String, Object?> _fixture([String name = 'route_plan_response.json']) =>
    jsonDecode(
          File('../../tests/fixtures/client_protocol/$name').readAsStringSync(),
        )
        as Map<String, Object?>;

Map<String, Object?> _result(Map<String, Object?> value) =>
    ((value['outcome'] as Map)['response'] as Map)['result']
        as Map<String, Object?>;

AonwRoutePlanResult _decode(Map<String, Object?> value) =>
    AonwClientResponse.parse(
          jsonEncode(value),
        ).require<AonwQueryResponse>().result
        as AonwRoutePlanResult;
