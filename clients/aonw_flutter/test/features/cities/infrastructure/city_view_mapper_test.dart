import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/cities/infrastructure/city_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = CityViewMapper();
  final map = testMapScene(cols: 4, rows: 4).map;

  test('maps engine-owned founding options without deriving territory', () {
    final result = mapper.founding(
      AonwCityFoundingOptionsResult(
        stamp: _stamp(),
        founderUnitId: 'preview-commander',
        center: const AonwCoordinate(col: 0, row: 0),
        selectedControlledHexes: const [],
        availableControlledHexes: const [AonwCoordinate(col: 1, row: 0)],
        requiredControlledHexes: 1,
        maximumRadius: 2,
      ),
      map: map,
      founder: testVisibleUnit(),
      expectedRevision: 0,
    );

    expect(result.availableControlledHexes, const [(col: 1, row: 0)]);
    expect(result.requiredControlledHexes, 1);
  });

  test('maps exact worked expansion and yield projections', () {
    final inspection = mapper.inspection(
      worked: AonwCityWorkedHexOptionsResult(
        stamp: _stamp(),
        cityId: 'preview-city',
        center: const AonwCoordinate(col: 1, row: 1),
        controlledHexes: const [AonwCoordinate(col: 1, row: 0)],
        availableHexes: const [AonwCoordinate(col: 1, row: 0)],
        selectedHexes: const [],
        effectiveHexes: const [AonwCoordinate(col: 1, row: 0)],
        limit: 1,
      ),
      expansion: AonwCityExpansionOptionsResult(
        stamp: _stamp(),
        cityId: 'preview-city',
        controlledHexes: const [AonwCoordinate(col: 1, row: 0)],
        preferredHex: null,
        candidates: const [
          AonwCityExpansionCandidate(
            coordinate: AonwCoordinate(col: 2, row: 1),
            score: -1,
            distance: 1,
          ),
        ],
      ),
      cityYield: AonwCityYieldResult(
        stamp: _stamp(),
        cityId: 'preview-city',
        contributions: const [
          AonwCityYieldContribution(
            kind: AonwCityYieldContributionKind.center,
            coordinate: AonwCoordinate(col: 1, row: 1),
            value: AonwYieldValue(food: 2, production: 1, gold: 0, defense: -1),
          ),
        ],
        total: const AonwYieldValue(
          food: 2,
          production: 1,
          gold: 0,
          defense: -1,
        ),
      ),
      map: map,
      city: testCityView(),
      expectedRevision: 0,
    );

    expect(inspection.expansion.candidates.single.score, -1);
    expect(inspection.cityYield.total.defense, -1);
    expect(inspection.workedHexes.effectiveHexes, const [(col: 1, row: 0)]);
  });

  test('fails closed for unrelated city command residue', () {
    expect(
      () => mapper.command(
        _command(
          outcome: const AonwCommandRejected(
            AonwCommandRejectionCode.attackerNotFound,
          ),
        ),
        map: map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      mapper
          .command(
            _command(outcome: const AonwCommandAccepted(), revision: 1),
            map: map,
            expectedRevision: 0,
            currentRevision: 0,
          )
          .rejection,
      isNull,
    );
  });
}

AonwCommandResult _command({
  required AonwCommandOutcome outcome,
  int revision = 0,
}) => AonwCommandResult(
  stamp: _stamp(revision: revision),
  outcome: outcome,
  events: const [],
  evidence: null,
  viewPatch: _patch(toRevision: revision),
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
);
