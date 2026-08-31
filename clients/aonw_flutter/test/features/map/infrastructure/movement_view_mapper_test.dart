import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/movement_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = MovementViewMapper();

  test('maps stable reachable tiles and a complete route', () {
    final map = testMapScene().map;
    final unit = testVisibleUnit();
    final reachable = mapper.reachable(
      AonwReachableResult(
        stamp: _stamp(),
        unitId: unit.id,
        availableMovementUnits: 12,
        tiles: const [
          AonwReachableTile(
            coordinate: AonwCoordinate(col: 1, row: 0),
            costUnits: 4,
            exhaustsMovement: false,
          ),
          AonwReachableTile(
            coordinate: AonwCoordinate(col: 0, row: 1),
            costUnits: 8,
            exhaustsMovement: false,
          ),
        ],
      ),
      map: map,
      expectedUnitId: unit.id,
      expectedRevision: 0,
    );
    final route = mapper.routePlan(
      AonwRoutePlanResult(
        stamp: _stamp(),
        unitId: unit.id,
        target: const AonwCoordinate(col: 1, row: 0),
        destination: const AonwCoordinate(col: 1, row: 0),
        totalCostUnits: 4,
        availableMovementUnits: 12,
        remainingMovementUnits: 8,
        steps: const [
          AonwMovementStep(
            coordinate: AonwCoordinate(col: 0, row: 0),
            enterCostUnits: 0,
            cumulativeCostUnits: 0,
          ),
          AonwMovementStep(
            coordinate: AonwCoordinate(col: 1, row: 0),
            enterCostUnits: 4,
            cumulativeCostUnits: 4,
          ),
        ],
      ),
      map: map,
      unit: unit,
      expectedTarget: (col: 1, row: 0),
      expectedRevision: 0,
    );

    expect(reachable.tileAt((col: 1, row: 0))?.costUnits, 4);
    expect(route.steps.first.coordinate, unit.coordinate);
    expect(route.steps.last.coordinate, route.destination);
    expect(route.remainingMovementUnits, 8);
  });

  test('rejects stale identities and inconsistent routes', () {
    final map = testMapScene().map;
    final unit = testVisibleUnit();

    expect(
      () => mapper.reachable(
        AonwReachableResult(
          stamp: _stamp(revision: 1),
          unitId: unit.id,
          availableMovementUnits: 12,
          tiles: const [],
        ),
        map: map,
        expectedUnitId: unit.id,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.routePlan(
        AonwRoutePlanResult(
          stamp: _stamp(),
          unitId: unit.id,
          target: const AonwCoordinate(col: 1, row: 0),
          destination: const AonwCoordinate(col: 1, row: 0),
          totalCostUnits: 4,
          availableMovementUnits: 12,
          remainingMovementUnits: 8,
          steps: const [
            AonwMovementStep(
              coordinate: AonwCoordinate(col: 1, row: 0),
              enterCostUnits: 4,
              cumulativeCostUnits: 4,
            ),
          ],
        ),
        map: map,
        unit: unit,
        expectedTarget: (col: 1, row: 0),
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('keeps accepted movement events and evidence typed', () {
    final execution = mapper.validateCommand(
      _command(),
      map: testMapScene().map,
      expectedUnitId: 'preview-commander',
      expectedRevision: 0,
      currentRevision: 0,
    );

    expect(execution.events.single.from, (col: 0, row: 0));
    expect(execution.events.single.to, (col: 1, row: 0));
    expect(execution.evidence?.steps.single.coordinate, (col: 1, row: 0));
  });
}

AonwSessionStamp _stamp({int revision = 0}) => AonwSessionStamp(
  revision: revision,
  stateDigest: 'b' * 64,
  mapHash: 'a' * 64,
  rulesetHash: 'c' * 64,
);

AonwCommandResult _command() => AonwCommandResult(
  stamp: _stamp(revision: 1),
  outcome: const AonwCommandAccepted(),
  events: const [
    AonwUnitMovedEvent(
      unitId: 'preview-commander',
      from: AonwCoordinate(col: 0, row: 0),
      to: AonwCoordinate(col: 1, row: 0),
    ),
  ],
  evidence: const AonwUnitMovementEvidence(
    unitId: 'preview-commander',
    from: AonwCoordinate(col: 0, row: 0),
    steps: [
      AonwMovementStep(
        coordinate: AonwCoordinate(col: 1, row: 0),
        enterCostUnits: 4,
        cumulativeCostUnits: 4,
      ),
    ],
  ),
  viewPatch: const AonwPlayerViewPatch(
    fromRevision: 0,
    toRevision: 1,
    turn: 1,
    turnMode: AonwTurnMode.sequential,
    turnLifecycle: null,
    outcome: null,
    upsertedUnits: [],
    removedUnitIds: [],
    upsertedCities: [],
    removedCityIds: [],
    upsertedArtifacts: [],
    removedArtifactIds: [],
    upsertedFieldImprovements: [],
    removedFieldImprovementCoordinates: [],
    upsertedRoads: [],
    removedRoadCoordinates: [],
    pendingAction: null,
    cityFoundingDraft: null,
    diplomacy: null,
  ),
);
