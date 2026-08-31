import 'dart:convert';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:test/test.dart';

void main() {
  test('serializes every current artifact command exactly', () {
    expect(
      _request(
        AonwArtifactRequest.startExcavation(
          expectedRevision: 8,
          unitId: 'scout-1',
        ),
      ),
      _command('startArtifactExcavation', 8, {'unitId': 'scout-1'}),
    );
    expect(
      _request(
        AonwArtifactRequest.storeInCity(
          expectedRevision: 9,
          unitId: 'scout-1',
          cityId: 'capital',
        ),
      ),
      _command('storeArtifactInCity', 9, {
        'unitId': 'scout-1',
        'cityId': 'capital',
      }),
    );
    expect(
      _request(
        AonwArtifactRequest.trade(
          expectedRevision: 10,
          targetPlayerId: 'player-2',
          offeredArtifactId: 'artifact-1',
          offeredGold: 4,
        ),
      ),
      _command('tradeArtifact', 10, {
        'targetPlayerId': 'player-2',
        'offeredArtifactId': 'artifact-1',
        'offeredGold': 4,
      }),
    );
  });

  test(
    'preserves explicit null city selection without an omission fallback',
    () {
      expect(
        _request(
          AonwArtifactRequest.storeInCity(
            expectedRevision: 9,
            unitId: 'scout-1',
          ),
        ),
        _command('storeArtifactInCity', 9, {
          'unitId': 'scout-1',
          'cityId': null,
        }),
      );
    },
  );
}

Map<String, Object?> _request(AonwClientRequest request) =>
    (jsonDecode(request.toJson()) as Map<String, Object?>)['request']!
        as Map<String, Object?>;

Map<String, Object?> _command(
  String type,
  int expectedRevision,
  Map<String, Object?> fields,
) => {
  'type': 'dispatch',
  'command': {'type': type, 'expectedRevision': expectedRevision, ...fields},
};
