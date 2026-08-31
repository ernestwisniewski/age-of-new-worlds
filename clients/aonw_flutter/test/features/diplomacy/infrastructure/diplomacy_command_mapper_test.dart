import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/diplomacy/infrastructure/diplomacy_command_mapper.dart';
import 'package:aonw_flutter/features/diplomacy/read_model/diplomacy_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = DiplomacyCommandMapper();

  test('accepts only the event family of the requested action', () {
    final map = testMapScene().map;
    expect(
      mapper.command(
        _accepted(const [
          AonwClientEventKind.diplomaticRelationChanged,
          AonwClientEventKind.diplomaticScoreChanged,
        ]),
        map: map,
        action: const DeclareWarActionView('player-2'),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      isNull,
    );
    expect(
      () => mapper.command(
        _accepted(const [AonwClientEventKind.unitMoved]),
        map: map,
        action: const SendGoldGiftActionView(
          targetPlayerId: 'player-2',
          amount: 2,
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('keeps diplomacy rejections typed and rejects unrelated codes', () {
    final map = testMapScene().map;
    expect(
      mapper.command(
        _rejected(AonwCommandRejectionCode.diplomacyProposalNotFound),
        map: map,
        action: const RespondDiplomaticProposalActionView(
          proposalId: 'proposal-1',
          accepted: true,
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      DiplomacyRejectionCodeView.diplomacyProposalNotFound,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.workerNotFound),
        map: map,
        action: const DeclareWarActionView('player-2'),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

AonwCommandResult _accepted(List<AonwClientEventKind> events) =>
    AonwCommandResult(
      stamp: _stamp(revision: 1),
      outcome: const AonwCommandAccepted(),
      events: [for (final event in events) AonwPresentationEvent(event)],
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
