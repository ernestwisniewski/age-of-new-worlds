import 'dart:convert';
import 'dart:io';
import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('turn actions request matches the shared Rust fixture', () {
    expect(
      jsonDecode(
        AonwClientRequest.pendingTurnActions(expectedRevision: 0).toJson(),
      ),
      _fixture('pending_turn_actions_request.json'),
    );
  });
  test(
    'Rust turn actions preserve order, coordinates and immutable ownership',
    () {
      final result = _decode(_fixture());
      expect(result.stamp.revision, 0);
      expect(result.canActivate, isTrue);
      expect(result.actions, hasLength(3));
      final unit = result.actions[0] as AonwPendingUnitTurnAction;
      expect(unit.unitId, 'unit-0');
      expect((unit.coordinate.col, unit.coordinate.row), (0, 0));
      final city = result.actions[1] as AonwPendingCityProductionTurnAction;
      expect(city.cityId, 'capital');
      expect((city.coordinate.col, city.coordinate.row), (0, 1));
      expect(result.actions[2], isA<AonwPendingResearchTurnAction>());
      expect(() => result.actions.clear(), throwsUnsupportedError);
      final source = [...result.actions];
      final copy = AonwPendingTurnActionsResult(
        stamp: result.stamp,
        canActivate: false,
        actions: source,
      );
      source.clear();
      expect(copy.actions, hasLength(3));
      expect(copy.canActivate, isFalse);
    },
  );
  test('turn action objects reject all missing and unknown fields', () {
    for (final path in [
      'outcome/response/result',
      'outcome/response/result/stamp',
      'outcome/response/result/actions/0',
      'outcome/response/result/actions/0/coordinate',
      'outcome/response/result/actions/1',
      'outcome/response/result/actions/1/coordinate',
      'outcome/response/result/actions/2',
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
  test('turn action tags and scalar types are closed', () {
    for (final (path, key, replacement) in [
      ('outcome/response/result', 'canActivate', 1),
      ('outcome/response/result', 'actions', null),
      ('outcome/response/result/actions/0', 'type', 'futureAction'),
      ('outcome/response/result/actions/0', 'unitId', 3),
      ('outcome/response/result/actions/1', 'cityId', null),
      ('outcome/response/result/actions/0/coordinate', 'col', 0.5),
    ]) {
      final value = _fixture();
      (_at(value, path) as Map<String, Object?>)[key] = replacement;
      expect(() => _decode(value), throwsFormatException);
    }
    final value = _fixture();
    final result =
        _at(value, 'outcome/response/result') as Map<String, Object?>;
    result['actions'] = <Object?>[];
    result['canActivate'] = false;
    expect(_decode(value).actions, isEmpty);
    expect(_decode(value).canActivate, isFalse);
  });
}

Map<String, Object?> _fixture([
  String name = 'pending_turn_actions_response.json',
]) =>
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

AonwPendingTurnActionsResult _decode(Map<String, Object?> value) =>
    AonwClientResponse.parse(
          jsonEncode(value),
        ).require<AonwQueryResponse>().result
        as AonwPendingTurnActionsResult;
