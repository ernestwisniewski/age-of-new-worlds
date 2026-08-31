import 'dart:convert';

import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects missing capabilities before loading map assets', () async {
    final assets = _GuardedAssetBundle();
    final session = _IncompleteRustSession();
    final gateway = RustGameSessionGateway(
      assets: assets,
      sessionFactory: () async => session,
    );

    await expectLater(
      gateway.load(MapAssetPaths.starter),
      throwsA(
        isA<MapLoadException>()
            .having((error) => error.code, 'code', 'rust_capability_mismatch')
            .having(
              (error) => error.diagnosticCause.toString(),
              'diagnostic',
              contains('moveUnit'),
            ),
      ),
    );

    expect(session.requestTypes, ['capabilities']);
    expect(session.closeCalls, 1);
    expect(assets.loadCalls, 0);
  });
}

final class _IncompleteRustSession implements AonwRustSession {
  final requestTypes = <String>[];
  var closeCalls = 0;

  @override
  Future<String> requestJson(String request) async {
    final envelope = jsonDecode(request) as Map<String, dynamic>;
    final body = envelope['request'] as Map<String, dynamic>;
    requestTypes.add(body['type'] as String);
    return jsonEncode({
      'apiVersion': aonwClientApiVersion,
      'outcome': {
        'status': 'success',
        'response': {
          'type': 'capabilities',
          'features': ['inspectMap', 'snapshot', 'reachable', 'routePlan'],
        },
      },
    });
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
  }
}

final class _GuardedAssetBundle extends CachingAssetBundle {
  var loadCalls = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCalls += 1;
    throw StateError('Map assets must not load before capability validation.');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loadCalls += 1;
    throw StateError('Map assets must not load before capability validation.');
  }
}
