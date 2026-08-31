import 'package:aonw_flutter/features/logistics/infrastructure/unit_logistics_view_mapper.dart';
import 'package:aonw_flutter/features/logistics/read_model/unit_logistics_view.dart';
import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = UnitLogisticsViewMapper();

  test('maps engine-owned options without reconstructing legality', () {
    final options = mapper.options(
      AonwUnitLogisticsOptionsResult(
        stamp: _stamp(),
        unitId: 'preview-commander',
        autoExplore: const AonwAutoExploreOption(
          target: AonwCoordinate(col: 1, row: 0),
          totalCostUnits: 4,
          searchMetrics: AonwMovementSearchMetrics(
            frontierPops: 2,
            expandedTiles: 1,
            examinedEdges: 4,
            heapPushes: 3,
            routeRecords: 2,
          ),
        ),
        merchantRouteDestinations: const [
          AonwMerchantDestinationOption(cityId: 'city-2', totalCostUnits: 8),
        ],
        merchantTravelDestinations: const [],
        detachments: const [
          AonwDetachmentOption(
            troopKind: AonwTroopKind.warrior,
            destination: AonwCoordinate(col: 0, row: 1),
          ),
        ],
      ),
      map: testMapScene().map,
      unitId: 'preview-commander',
      expectedRevision: 0,
    );

    expect(options.autoExplore?.target, (col: 1, row: 0));
    expect(options.merchantRouteDestinations.single.cityId, 'city-2');
    expect(
      options.detachments.single.troopKind,
      LogisticsTroopKindView.warrior,
    );
  });

  test('validates typed evidence against the requested command', () {
    final command = _accepted(
      const AonwMerchantTravelExecution(
        unitId: 'preview-commander',
        destinationCityId: 'city-2',
        steps: [],
      ),
    );
    final mapped = mapper.command(
      command,
      map: testMapScene().map,
      action: const MoveMerchantToCityActionView(
        unitId: 'preview-commander',
        destinationCityId: 'city-2',
      ),
      expectedRevision: 0,
      currentRevision: 0,
    );

    expect(mapped.execution, isA<MerchantTravelExecutionView>());
    expect(
      () => mapper.command(
        command,
        map: testMapScene().map,
        action: const MoveMerchantToCityActionView(
          unitId: 'preview-commander',
          destinationCityId: 'city-3',
        ),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('fails closed on stale identity and unrelated rejection', () {
    expect(
      () => mapper.options(
        AonwUnitLogisticsOptionsResult(
          stamp: _stamp(revision: 1),
          unitId: 'preview-commander',
          autoExplore: null,
          merchantRouteDestinations: const [],
          merchantTravelDestinations: const [],
          detachments: const [],
        ),
        map: testMapScene().map,
        unitId: 'preview-commander',
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.cityNotFound),
        map: testMapScene().map,
        action: const AutoExploreActionView(unitId: 'preview-commander'),
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

AonwSessionStamp _stamp({int revision = 0}) => AonwSessionStamp(
  revision: revision,
  stateDigest: 'b' * 64,
  mapHash: 'a' * 64,
  rulesetHash: 'c' * 64,
);

AonwCommandResult _accepted(AonwLogisticsExecution execution) =>
    AonwCommandResult(
      stamp: _stamp(revision: 1),
      outcome: const AonwCommandAccepted(),
      events: const [],
      evidence: AonwLogisticsEvidence(execution: execution),
      viewPatch: _patch(toRevision: 1),
    );

AonwCommandResult _rejected(AonwCommandRejectionCode code) => AonwCommandResult(
  stamp: _stamp(),
  outcome: AonwCommandRejected(code),
  events: const [],
  evidence: null,
  viewPatch: _patch(),
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
