import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/map/presentation/geometry/odd_q_flat_top_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = _fixture();
  final map = fixture['map']! as Map<String, dynamic>;
  final geometry = AonwOddQFlatTopGeometry(
    cols: map['cols']! as int,
    rows: map['rows']! as int,
    radius: (fixture['radius']! as num).toDouble(),
  );

  test('matches shared odd-q centers, corners, bounds and neighbors', () {
    for (final vector in _vectors(fixture, 'centers')) {
      _expectPoint(geometry.center(_hex(vector['hex'])), vector['point']);
    }
    for (final vector in _vectors(fixture, 'corners')) {
      final hex = _hex(vector['hex']);
      final points = vector['points']! as List<dynamic>;
      for (var index = 0; index < points.length; index++) {
        _expectPoint(geometry.corner(hex, index), points[index]);
      }
    }
    final expectedBounds = _numbers(fixture['bounds']);
    final actualBounds = geometry.bounds;
    _expectNumbers([
      actualBounds.x,
      actualBounds.y,
      actualBounds.width,
      actualBounds.height,
    ], expectedBounds);
    for (final vector in _vectors(fixture, 'neighbors')) {
      expect(
        geometry.neighbors(_hex(vector['hex'])),
        (vector['hexes']! as List<dynamic>).map(_hex).toList(),
      );
    }
  });

  test('matches shared picking and normalized UV vectors', () {
    for (final vector in _vectors(fixture, 'picks')) {
      expect(geometry.hexAt(_point(vector['point'])), _hex(vector['hex']));
    }
    for (final vector in _vectors(fixture, 'uv')) {
      _expectPoint(
        geometry.normalizedUv(_point(vector['point'])),
        vector['normalized'],
      );
    }
  });
}

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File(
            '../../aonw_tests/fixtures/geometry/odd_q_flat_top.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

List<Map<String, dynamic>> _vectors(
  Map<String, dynamic> fixture,
  String field,
) => (fixture[field]! as List<dynamic>).cast<Map<String, dynamic>>();

AonwHexCoordinate _hex(Object? value) {
  final numbers = _numbers(value);
  return (col: numbers[0].toInt(), row: numbers[1].toInt());
}

AonwPoint _point(Object? value) {
  final numbers = _numbers(value);
  return (x: numbers[0], y: numbers[1]);
}

List<double> _numbers(Object? value) => (value! as List<dynamic>)
    .map((number) => (number as num).toDouble())
    .toList();

void _expectPoint(AonwPoint actual, Object? expected) {
  _expectNumbers([actual.x, actual.y], _numbers(expected));
}

void _expectNumbers(List<double> actual, List<double> expected) {
  expect(actual, hasLength(expected.length));
  for (var index = 0; index < expected.length; index++) {
    expect(actual[index], closeTo(expected[index], 1e-9));
  }
}
