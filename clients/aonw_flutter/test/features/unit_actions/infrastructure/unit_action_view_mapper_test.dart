import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/unit_actions/infrastructure/unit_action_view_mapper.dart';
import 'package:aonw_flutter/features/unit_actions/read_model/unit_action_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = UnitActionViewMapper();

  test('accepts an empty execution and advancing current identity', () {
    final rejection = mapper.validateCommand(
      _command(outcome: const AonwCommandAccepted(), revision: 1),
      map: testMapScene().map,
      expectedRevision: 0,
      currentRevision: 0,
    );

    expect(rejection, isNull);
  });

  test('maps only rejection codes owned by the unit action family', () {
    final rejection = mapper.validateCommand(
      _command(
        outcome: const AonwCommandRejected(AonwCommandRejectionCode.unitBusy),
      ),
      map: testMapScene().map,
      expectedRevision: 0,
      currentRevision: 0,
    );

    expect(rejection, UnitActionRejectionCodeView.unitBusy);
    expect(
      () => mapper.validateCommand(
        _command(
          outcome: const AonwCommandRejected(
            AonwCommandRejectionCode.movePathNotFound,
          ),
        ),
        map: testMapScene().map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('fails closed for stale identity or unexpected execution details', () {
    expect(
      () => mapper.validateCommand(
        _command(outcome: const AonwCommandAccepted(), revision: 2),
        map: testMapScene().map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.validateCommand(
        _command(
          outcome: const AonwCommandAccepted(),
          revision: 1,
          events: const [
            AonwUnitMovedEvent(
              unitId: 'preview-commander',
              from: AonwCoordinate(col: 0, row: 0),
              to: AonwCoordinate(col: 1, row: 0),
            ),
          ],
        ),
        map: testMapScene().map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

AonwCommandResult _command({
  required AonwCommandOutcome outcome,
  int revision = 0,
  List<AonwClientEvent> events = const [],
}) => AonwCommandResult(
  stamp: AonwSessionStamp(
    revision: revision,
    stateDigest: 'b' * 64,
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  outcome: outcome,
  events: events,
  evidence: null,
  viewPatch: AonwPlayerViewPatch(
    fromRevision: 0,
    toRevision: revision,
    turn: 1,
    turnMode: AonwTurnMode.sequential,
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
  ),
);
