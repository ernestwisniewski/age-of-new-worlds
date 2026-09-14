import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  for (final merchant in [false, true]) {
    test('decodes immutable private route metadata (merchant: $merchant)', () {
      final value = _route(merchant);
      final dynamic route = merchant
          ? AonwMerchantTradeRoute.fromJson(value)
          : AonwQueuedMovePath.fromJson(value);
      expect(route.stepTurns, [1, 2]);
      expect(route.roadStepIndices, [1]);
      expect(() => route.stepTurns.clear(), throwsUnsupportedError);
      expect(() => route.roadStepIndices.clear(), throwsUnsupportedError);
      for (final key in ['stepTurns', 'roadStepIndices']) {
        final missing = {...value}..remove(key);
        expect(() => _decode(missing, merchant), throwsFormatException);
        for (final invalid in [
          null,
          <String, Object?>{},
          [-1],
          ['1'],
          [true],
        ]) {
          expect(
            () => _decode({...value, key: invalid}, merchant),
            throwsFormatException,
          );
        }
      }
      expect(
        () => _decode({...value, 'unknown': true}, merchant),
        throwsFormatException,
      );
    });
  }
}

Object _decode(Map<String, Object?> value, bool merchant) => merchant
    ? AonwMerchantTradeRoute.fromJson(value)
    : AonwQueuedMovePath.fromJson(value);

Map<String, Object?> _route(bool merchant) => {
  if (merchant) ...{
    'originCityId': 'origin',
    'destinationCityId': 'destination',
    'transportNetworkFingerprint': 'network',
  } else ...{
    'targetCol': 1,
    'targetRow': 0,
  },
  'steps': [
    {'col': 0, 'row': 0, 'enterCostUnits': 0, 'cumulativeCostUnits': 0},
    {'col': 1, 'row': 0, 'enterCostUnits': 2, 'cumulativeCostUnits': 2},
  ],
  'stepTurns': [1, 2],
  'roadStepIndices': [1],
};
