import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/turns/infrastructure/turn_view_mapper.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_command_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = TurnViewMapper();

  test('maps accepted turn events in authoritative revision order', () {
    final result = mapper.accepted(
      _command(
        revision: 8,
        outcome: const AonwCommandAccepted(),
        events: [
          const AonwTurnEndedEvent(playerId: 'player-1'),
          AonwAllPlayersSubmittedEvent(turn: 7, playerIds: ['player-1']),
        ],
        evidence: AonwTurnKernelEvidence(
          processors: const ['movement', 'production'],
          foundedCityIds: const ['city-1'],
          combatExecutions: const [],
          resetUnitIds: const ['unit-1'],
          movementExecutions: const [],
          invalidatedOrderUnitIds: const [],
          finishedAutoExploreUnitIds: const [],
        ),
      ),
      map: testMapScene().map,
      expectedRevision: 7,
    );

    expect(result.activities.map((item) => item.kind), [
      TurnActivityKindView.turnEnded,
      TurnActivityKindView.allPlayersSubmitted,
    ]);
    expect(result.activities.last.identity.revision, 8);
    expect(result.activities.last.identity.eventIndex, 1);
    expect(result.evidence.processors, ['movement', 'production']);
  });

  test('accepts an idempotent turn submission without a revision advance', () {
    final result = mapper.accepted(
      _command(
        revision: 7,
        outcome: const AonwCommandAccepted(),
        evidence: AonwTurnKernelEvidence(
          processors: const ['submission', 'lifecycle'],
          foundedCityIds: const [],
          combatExecutions: const [],
          resetUnitIds: const [],
          movementExecutions: const [],
          invalidatedOrderUnitIds: const [],
          finishedAutoExploreUnitIds: const [],
        ),
      ),
      map: testMapScene().map,
      expectedRevision: 7,
    );

    expect(result.activities, isEmpty);
    expect(result.evidence.processors, ['submission', 'lifecycle']);
  });

  test('maps only turn rejection codes and rejects execution residue', () {
    expect(
      mapper.rejected(
        _command(
          revision: 7,
          outcome: const AonwCommandRejected(
            AonwCommandRejectionCode.turnPlayerNotActive,
          ),
        ),
        map: testMapScene().map,
        currentRevision: 7,
      ),
      TurnRejectionCodeView.playerNotActive,
    );
    expect(
      () => mapper.rejected(
        _command(
          revision: 7,
          outcome: const AonwCommandRejected(AonwCommandRejectionCode.unitBusy),
        ),
        map: testMapScene().map,
        currentRevision: 7,
      ),
      throwsFormatException,
    );
  });
}

AonwCommandResult _command({
  required int revision,
  required AonwCommandOutcome outcome,
  List<AonwClientEvent> events = const [],
  AonwClientEvidence? evidence,
}) => AonwCommandResult(
  stamp: AonwSessionStamp(
    revision: revision,
    stateDigest: 'b' * 64,
    mapHash: 'a' * 64,
    rulesetHash: 'c' * 64,
  ),
  outcome: outcome,
  events: events,
  evidence: evidence,
  viewPatch: AonwPlayerViewPatch(
    fromRevision: revision - (outcome is AonwCommandAccepted ? 1 : 0),
    toRevision: revision,
    turn: 7,
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
