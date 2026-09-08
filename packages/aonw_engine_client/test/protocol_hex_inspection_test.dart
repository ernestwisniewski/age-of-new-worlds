import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

const _profilePath = 'outcome/response/result/inspection';

void main() {
  test('hex request matches the shared Rust protocol fixture', () {
    final value = AonwClientRequest.inspectHex(
      expectedRevision: 0,
      coordinate: const AonwCoordinate(col: 0, row: 0),
    );
    expect(jsonDecode(value.toJson()), _fixture('hex_inspection_request.json'));
  });

  test(
    'Rust hex response decodes complete immutable engine-owned evidence',
    () {
      final result = _decode(_fixture());
      final profile = result.inspection;
      expect(result.stamp.revision, 0);
      expect(profile.baseTerrain, AonwMapTerrain.forest);
      expect(profile.resources, [AonwMapResource.deer, AonwMapResource.coal]);
      expect(profile.kind, AonwHexAssessmentKind.forestForge);
      expect(profile.recommendation, AonwHexRecommendation.defendHere);
      expect(
        [profile.score.city, profile.score.defense, profile.score.economy],
        [5, 5, 4],
      );
      expect(profile.yieldValue.production, 2);
      expect(profile.canFoundCityOnTerrain, isTrue);
      expect(profile.hasRiver, isFalse);
      expect(profile.improvementAccess, isA<AonwHexOutsideControlledCity>());
      expect(
        profile.improvements.last.requiredTechnology,
        AonwTechnologyId.coalMining,
      );
      expect(profile.improvements.last.technologyUnlocked, isTrue);
      expect(profile.improvements.last.buildTurns, 5);
      expect(profile.improvements.last.yieldDelta.production, 3);
      expect(() => profile.resources.clear(), throwsUnsupportedError);
      expect(() => profile.terrainTags.clear(), throwsUnsupportedError);
      expect(() => profile.tags.clear(), throwsUnsupportedError);
      expect(() => profile.improvements.clear(), throwsUnsupportedError);
    },
  );

  test('every hex object rejects missing and unknown fields', () {
    for (final path in [
      'outcome/response/result',
      _profilePath,
      '$_profilePath/coordinate',
      '$_profilePath/yieldValue',
      '$_profilePath/score',
      '$_profilePath/improvements/0',
      '$_profilePath/improvements/0/yieldDelta',
      '$_profilePath/improvementAccess',
    ]) {
      final keys = (_at(_fixture(), path) as Map<String, Object?>).keys;
      for (final key in keys) {
        final missing = _fixture();
        (_at(missing, path) as Map<String, Object?>).remove(key);
        expect(
          () => _decode(missing),
          throwsFormatException,
          reason: '$path/$key',
        );
      }
      final unknown = _fixture();
      (_at(unknown, path) as Map<String, Object?>)['futureField'] = true;
      expect(() => _decode(unknown), throwsFormatException, reason: path);
    }
  });

  test('hex enums and scalar fields reject unknown values and wrong types', () {
    for (final path in [
      'baseTerrain',
      'terrainTags/0',
      'resources/0',
      'kind',
      'recommendation',
      'tags/0',
      'improvementAccess/kind',
      'improvements/0/kind',
      'improvements/0/requiredTechnology',
      'height',
      'hasRiver',
      'canFoundCityOnTerrain',
      'score/city',
      'improvements/0/buildTurns',
      'improvements/0/technologyUnlocked',
    ]) {
      final value = _fixture();
      _setAt(value, '$_profilePath/$path', 'futureValue');
      expect(() => _decode(value), throwsFormatException, reason: path);
    }
  });

  test(
    'access variants are closed and explicit null technology is supported',
    () {
      final cases = <String, Matcher>{
        'outsideControlledCity': isA<AonwHexOutsideControlledCity>(),
        'cityCenter': isA<AonwHexCityCenter>(),
        'alreadyImproved': isA<AonwHexAlreadyImproved>(),
        'controlledCity': isA<AonwHexControlledCity>().having(
          (v) => v.cityId,
          'city',
          'city-1',
        ),
      };
      for (final entry in cases.entries) {
        final value = _fixture();
        final access = <String, Object?>{
          'kind': entry.key,
          if (entry.key == 'controlledCity') 'cityId': 'city-1',
        };
        _setAt(value, '$_profilePath/improvementAccess', access);
        _setAt(value, '$_profilePath/improvements/0/requiredTechnology', null);
        final result = _decode(value).inspection;
        expect(result.improvementAccess, entry.value);
        expect(result.improvements.first.requiredTechnology, isNull);
        access['extra'] = true;
        expect(() => _decode(value), throwsFormatException);
      }
    },
  );
}

AonwHexInspectionResult _decode(Map<String, Object?> source) =>
    AonwClientResponse.parse(
          jsonEncode(source),
        ).require<AonwQueryResponse>().result
        as AonwHexInspectionResult;

Map<String, Object?> _fixture([String name = 'hex_inspection_response.json']) =>
    jsonDecode(
          File('../../tests/fixtures/client_protocol/$name').readAsStringSync(),
        )
        as Map<String, Object?>;

Object? _at(Object? source, String path) {
  var value = source;
  for (final part in path.split('/')) {
    value = value is List<Object?>
        ? value[int.parse(part)]
        : (value as Map<String, Object?>)[part];
  }
  return value;
}

void _setAt(Object? source, String path, Object? replacement) {
  final separator = path.lastIndexOf('/');
  final parent = _at(source, path.substring(0, separator));
  final key = path.substring(separator + 1);
  if (parent is List<Object?>) {
    parent[int.parse(key)] = replacement;
  } else {
    (parent as Map<String, Object?>)[key] = replacement;
  }
}
