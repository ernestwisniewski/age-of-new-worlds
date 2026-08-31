import 'package:aonw_flutter/features/artifacts/infrastructure/artifact_view_mapper.dart';
import 'package:aonw_flutter/features/artifacts/read_model/artifact_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = ArtifactViewMapper();

  test('accepts only the exact artifact event for each command', () {
    final map = testMapScene().map;

    expect(
      mapper.command(
        _accepted(AonwClientEventKind.artifactExcavationStarted),
        map: map,
        action: const StartArtifactExcavationActionView(
          unitId: 'preview-commander',
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      isNull,
    );
    expect(
      mapper.command(
        _accepted(AonwClientEventKind.artifactStored),
        map: map,
        action: const TradeArtifactActionView(
          targetPlayerId: 'player-two',
          offeredArtifactId: 'artifact-crown',
          offeredGold: 2,
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      isNull,
    );
    expect(
      () => mapper.command(
        _accepted(AonwClientEventKind.unitMoved),
        map: map,
        action: const StoreArtifactInCityActionView(
          unitId: 'preview-commander',
          cityId: 'preview-city',
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('keeps artifact rejections typed and rejects unrelated codes', () {
    final map = testMapScene().map;
    expect(
      mapper.command(
        _rejected(AonwCommandRejectionCode.artifactTradeBlockedByWar),
        map: map,
        action: const TradeArtifactActionView(
          targetPlayerId: 'player-two',
          offeredArtifactId: 'artifact-crown',
          offeredGold: 0,
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      ArtifactRejectionCodeView.artifactTradeBlockedByWar,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.workerNotFound),
        map: map,
        action: const StartArtifactExcavationActionView(
          unitId: 'preview-commander',
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

AonwCommandResult _accepted(AonwClientEventKind event) => AonwCommandResult(
  stamp: _stamp(revision: 1),
  outcome: const AonwCommandAccepted(),
  events: [AonwPresentationEvent(event)],
  evidence: null,
  viewPatch: _patch(toRevision: 1),
);

AonwCommandResult _rejected(AonwCommandRejectionCode code) => AonwCommandResult(
  stamp: _stamp(),
  outcome: AonwCommandRejected(code),
  events: const [],
  evidence: null,
  viewPatch: _patch(),
);

AonwSessionStamp _stamp({int revision = 0}) => AonwSessionStamp(
  revision: revision,
  stateDigest: 'b' * 64,
  mapHash: 'a' * 64,
  rulesetHash: 'c' * 64,
);

AonwPlayerViewPatch _patch({int toRevision = 0}) => AonwPlayerViewPatch(
  fromRevision: 0,
  toRevision: toRevision,
  turn: 1,
  turnLifecycle: null,
  outcome: null,
  upsertedUnits: const [],
  removedUnitIds: const [],
  upsertedCities: const [],
  removedCityIds: const [],
  upsertedArtifacts: const [],
  removedArtifactIds: const [],
  upsertedFieldImprovements: const [],
  removedFieldImprovementCoordinates: const [],
  upsertedRoads: const [],
  removedRoadCoordinates: const [],
  pendingAction: null,
  cityFoundingDraft: null,
  diplomacy: null,
);
