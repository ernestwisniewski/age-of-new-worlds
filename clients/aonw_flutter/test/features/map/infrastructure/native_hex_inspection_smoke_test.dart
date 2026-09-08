import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native hex inspection preserves state and rejects stale queries',
    () async {
      final session = await createAonwEngineSession();
      expect(session, isNotNull);
      addTearDown(session!.close);
      Future<AonwClientResponse> request(AonwClientRequest request) async =>
          AonwClientResponse.parse(await session.requestJson(request.toJson()));

      final capabilities = (await request(
        AonwClientRequest.capabilities(),
      )).require<AonwCapabilitiesResponse>();
      expect(capabilities.features, contains(AonwClientFeature.hexInspection));
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
        AonwClientRequest.inspectHex(
          expectedRevision: opened.stamp.revision,
          coordinate: const AonwCoordinate(col: 2, row: 1),
        ),
      )).require<AonwQueryResponse>();
      final result = response.result as AonwHexInspectionResult;
      expect(result.stamp.stateDigest, opened.stamp.stateDigest);
      expect(result.stamp.mapHash, opened.stamp.mapHash);
      expect(result.inspection.coordinate.col, 2);
      expect(result.inspection.coordinate.row, 1);
      expect(result.inspection.terrainTags, isNotEmpty);
      expect(result.inspection.kind, isA<AonwHexAssessmentKind>());
      final stale = await request(
        AonwClientRequest.inspectHex(
          expectedRevision: 99,
          coordinate: const AonwCoordinate(col: 2, row: 1),
        ),
      );
      expect(stale.error!.code, 'stale_revision');
      final absent = await request(
        AonwClientRequest.inspectHex(
          expectedRevision: opened.stamp.revision,
          coordinate: const AonwCoordinate(col: 99, row: 99),
        ),
      );
      expect(absent.error!.code, 'hex_inspection_outside_map');
      expect(
        await session.requestJson(AonwClientRequest.snapshot().toJson()),
        before,
      );
    },
  );
}
