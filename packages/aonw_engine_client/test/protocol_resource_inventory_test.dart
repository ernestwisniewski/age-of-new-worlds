import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';
import 'package:test/test.dart';

Map<String, Object?> inventoryFixture() {
  Object? value = jsonDecode(
    File(
      '../../tests/fixtures/client_protocol/command_result_response.json',
    ).readAsStringSync(),
  );
  for (final key in [
    'outcome',
    'response',
    'result',
    'viewPatch',
    'economy',
    'strategicResourceInventory',
  ]) {
    value = readObject(value, key)[key];
  }
  return readObject(value, 'inventory');
}

void main() {
  test('inventory decodes all balances and owns immutable collections', () {
    final value = AonwStrategicResourceInventory.fromJson(inventoryFixture());
    expect(value.balances.map((row) => row.resource), [
      AonwResourceType.iron,
      AonwResourceType.coal,
      AonwResourceType.oil,
      AonwResourceType.aluminium,
      AonwResourceType.uranium,
      AonwResourceType.horses,
      AonwResourceType.marble,
    ]);
    expect(value.availableTypeCount, 1);
    expect(value.balances[2].available, 4);
    expect(value.balances[2].domesticProduction, 1);
    expect(value.deposits.single.amountPerTurn, 1);
    expect(() => value.balances.clear(), throwsUnsupportedError);
    expect(() => value.deposits.clear(), throwsUnsupportedError);
    expect(() => value.expiringTradeIds.add('foreign'), throwsUnsupportedError);
  });

  test('inventory rejects missing and unknown fields at every level', () {
    final valid = inventoryFixture();
    for (final key in valid.keys) {
      expect(
        () => AonwStrategicResourceInventory.fromJson({...valid}..remove(key)),
        throwsFormatException,
        reason: key,
      );
    }
    expect(
      () => AonwStrategicResourceInventory.fromJson({...valid, 'extra': 0}),
      throwsFormatException,
    );
    for (final list in ['balances', 'deposits']) {
      final row = Map<String, Object?>.from(
        (valid[list]! as List<Object?>).first as Map<String, Object?>,
      );
      for (final key in row.keys) {
        final value = inventoryFixture();
        (value[list]! as List<Object?>)[0] = {...row}..remove(key);
        expect(
          () => AonwStrategicResourceInventory.fromJson(value),
          throwsFormatException,
          reason: '$list.$key',
        );
      }
    }
  });

  test('unimproved deposit requires explicitly null extraction fields', () {
    final value = inventoryFixture();
    final deposit =
        (value['deposits']! as List<Object?>).first as Map<String, Object?>;
    deposit['improvement'] = null;
    deposit['amountPerTurn'] = null;
    final result = AonwStrategicResourceInventory.fromJson(value);
    expect(result.deposits.single.improvement, isNull);
    expect(result.deposits.single.amountPerTurn, isNull);
  });
}
