import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/engine_game_session_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads city planning through the native application port', () async {
    final gateway = EngineGameSessionGateway(assets: _FileAssetBundle());
    addTearDown(gateway.close);
    final scene = await gateway.load(MapAssetPaths.starter);
    final view = await gateway.capabilities.cityPlanning.cityPlanning(
      expectedRevision: scene.player.stamp.revision,
    );
    expect(view.growthTiles, isNotEmpty);
    expect(view.growthTiles.containsAll(view.citySites), isTrue);
    expect(view.stamp.stateDigest, scene.player.stamp.stateDigest);
    expect(view.stamp.revision, scene.player.stamp.revision);
  });

  test(
    'native city planning preserves state and rejects stale queries',
    () async {
      final session = await createAonwEngineSession();
      expect(session, isNotNull);
      addTearDown(session!.close);
      Future<AonwClientResponse> request(AonwClientRequest request) async =>
          AonwClientResponse.parse(await session.requestJson(request.toJson()));

      final capabilities = (await request(
        AonwClientRequest.capabilities(),
      )).require<AonwCapabilitiesResponse>();
      expect(capabilities.features, contains(AonwClientFeature.cityPlanning));
      final opened = (await request(
        AonwClientRequest.openSession(
          mapDocument: File(
            'assets/maps/aonw2_starter/map.json',
          ).readAsStringSync(),
          scenarioDocument: File(
            'assets/scenarios/aonw2_starter.json',
          ).readAsStringSync(),
          actorPlayerId: 'preview-player',
        ),
      )).require<AonwSessionOpenedResponse>();
      final before = await session.requestJson(
        AonwClientRequest.snapshot().toJson(),
      );
      final response = (await request(
        AonwClientRequest.cityPlanning(expectedRevision: opened.stamp.revision),
      )).require<AonwQueryResponse>();
      final result = response.result as AonwCityPlanningResult;
      expect(result.stamp.stateDigest, opened.stamp.stateDigest);
      expect(result.stamp.mapHash, opened.stamp.mapHash);
      final stale = await request(
        AonwClientRequest.cityPlanning(expectedRevision: 99),
      );
      expect(stale.error!.code, 'stale_revision');
      expect(
        await session.requestJson(AonwClientRequest.snapshot().toJson()),
        before,
      );
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
