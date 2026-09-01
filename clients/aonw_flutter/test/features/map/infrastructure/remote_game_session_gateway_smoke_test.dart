import 'dart:convert';
import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runs shared map capabilities over an externally opened session',
    () async {
      final native = await createAonwEngineSession();
      expect(native, isNotNull);
      final remote = _TrackingSession(native!);
      final mapDocument = await File(
        MapAssetPaths.starter.document,
      ).readAsString();
      final scenarioDocument = await File(
        MapAssetPaths.starter.scenarioDocument,
      ).readAsString();
      final opened = await remote.send(
        AonwClientRequest.openSession(
          mapDocument: mapDocument,
          scenarioDocument: scenarioDocument,
          actorPlayerId: MapAssetPaths.starter.actorPlayerId,
        ),
      );
      expect(opened.isSuccess, isTrue);
      remote.requestTypes.clear();
      final gateway = EngineGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);

      final scene = await gateway.startRemoteMatch(
        assets: MapAssetPaths.starter,
        session: remote,
      );
      final reachable = await gateway.reachable(
        expectedRevision: scene.player.stamp.revision,
        unitId: scene.player.units.single.id,
      );

      expect(scene.player.stamp.mapHash, scene.map.contentHash);
      expect(reachable.unitId, 'preview-commander');
      expect(remote.requestTypes, ['snapshot', 'query']);
      await gateway.close();
      expect(remote.closeCalls, 1);
    },
  );
}

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

final class _TrackingSession implements AonwEngineSession {
  _TrackingSession(this.delegate);

  final AonwEngineSession delegate;
  final requestTypes = <String>[];
  var closeCalls = 0;

  @override
  Future<String> requestJson(String request) {
    final envelope = jsonDecode(request) as Map<String, Object?>;
    final body = envelope['request']! as Map<String, Object?>;
    requestTypes.add(body['type']! as String);
    return delegate.requestJson(request);
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
    await delegate.close();
  }
}
