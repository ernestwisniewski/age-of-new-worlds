import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('planning request matches the shared Rust wire fixture', () {
    expect(
      jsonDecode(AonwClientRequest.cityPlanning(expectedRevision: 0).toJson()),
      _fixture('city_planning_request.json'),
    );
  });
  test('planning results preserve coordinates and own immutable lists', () {
    final result = _decode(_fixture());
    expect(result.stamp.revision, 0);
    expect(result.citySites.map((hex) => (hex.col, hex.row)), [(3, 0), (3, 1)]);
    expect(result.growthTiles, hasLength(7));
    expect(() => result.citySites.clear(), throwsUnsupportedError);
    expect(() => result.growthTiles.clear(), throwsUnsupportedError);
    final source = [...result.citySites];
    final copied = AonwCityPlanningResult(
      stamp: result.stamp,
      citySites: source,
      growthTiles: source,
    );
    source.clear();
    expect(copied.citySites, hasLength(2));
    expect(copied.growthTiles, hasLength(2));
  });
  test('planning objects reject every missing and unknown field', () {
    for (final path in [
      'outcome/response/result',
      'outcome/response/result/stamp',
      'outcome/response/result/citySites/0',
      'outcome/response/result/growthTiles/0',
    ]) {
      final keys = (_at(_fixture(), path) as Map<String, Object?>).keys;
      for (final key in keys) {
        final value = _fixture();
        (_at(value, path) as Map<String, Object?>).remove(key);
        expect(
          () => _decode(value),
          throwsFormatException,
          reason: '$path/$key',
        );
      }
      final value = _fixture();
      (_at(value, path) as Map<String, Object?>)['futureField'] = true;
      expect(() => _decode(value), throwsFormatException, reason: path);
    }
  });
  test('planning coordinate and collection types are closed', () {
    for (final (path, key, replacement) in [
      ('outcome/response/result', 'citySites', null),
      ('outcome/response/result', 'growthTiles', <String, Object?>{}),
      ('outcome/response/result/citySites/0', 'col', 0.5),
      ('outcome/response/result/growthTiles/0', 'row', '1'),
      ('outcome/response/result', 'type', 'futurePlanning'),
    ]) {
      final value = _fixture();
      (_at(value, path) as Map<String, Object?>)[key] = replacement;
      expect(() => _decode(value), throwsFormatException);
    }
    final value = _fixture();
    final result =
        _at(value, 'outcome/response/result') as Map<String, Object?>;
    result['citySites'] = <Object?>[];
    result['growthTiles'] = <Object?>[];
    expect(_decode(value).citySites, isEmpty);
    expect(_decode(value).growthTiles, isEmpty);
  });
}

Map<String, Object?> _fixture([String name = 'city_planning_response.json']) =>
    jsonDecode(
          File('../../tests/fixtures/client_protocol/$name').readAsStringSync(),
        )
        as Map<String, Object?>;

Object? _at(Object? value, String path) {
  for (final key in path.split('/')) {
    value = value is List
        ? value[int.parse(key)]
        : (value as Map<String, Object?>)[key];
  }
  return value;
}

AonwCityPlanningResult _decode(Map<String, Object?> value) =>
    AonwClientResponse.parse(
          jsonEncode(value),
        ).require<AonwQueryResponse>().result
        as AonwCityPlanningResult;
