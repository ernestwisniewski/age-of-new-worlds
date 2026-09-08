import 'dart:io';

import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native pending work preserves state and refreshes after a unit order',
    () async {
      final session = await createAonwEngineSession();
      expect(session, isNotNull);
      addTearDown(session!.close);
      Future<AonwClientResponse> request(AonwClientRequest value) async =>
          AonwClientResponse.parse(await session.requestJson(value.toJson()));
      final capabilities = (await request(
        AonwClientRequest.capabilities(),
      )).require<AonwCapabilitiesResponse>();
      expect(
        capabilities.features,
        contains(AonwClientFeature.pendingTurnActions),
      );
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
      Future<AonwPendingTurnActionsResult> query(int revision) async =>
          (await request(
                AonwClientRequest.pendingTurnActions(
                  expectedRevision: revision,
                ),
              )).require<AonwQueryResponse>().result
              as AonwPendingTurnActionsResult;
      final result = await query(opened.stamp.revision);
      expect(result.canActivate, isTrue);
      expect(result.stamp.stateDigest, opened.stamp.stateDigest);
      expect(result.stamp.mapHash, opened.stamp.mapHash);
      expect(result.stamp.rulesetHash, opened.stamp.rulesetHash);
      expect(result.actions.last, isA<AonwPendingResearchTurnAction>());
      final unit = result.actions.whereType<AonwPendingUnitTurnAction>().first;
      expect(
        await session.requestJson(AonwClientRequest.snapshot().toJson()),
        before,
      );
      final command = (await request(
        AonwClientRequest.skipUnitTurn(
          expectedRevision: opened.stamp.revision,
          unitId: unit.unitId,
        ),
      )).require<AonwCommandResponse>();
      expect(command.result.accepted, isTrue);
      final stale = await request(
        AonwClientRequest.pendingTurnActions(
          expectedRevision: opened.stamp.revision,
        ),
      );
      expect(stale.error!.code, 'stale_revision');
      final updated = await query(command.result.stamp.revision);
      expect(
        updated.actions.whereType<AonwPendingUnitTurnAction>().map(
          (value) => value.unitId,
        ),
        isNot(contains(unit.unitId)),
      );
      expect(updated.actions.length, result.actions.length - 1);
    },
  );
}
