import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/research/infrastructure/research_view_mapper.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  const mapper = ResearchViewMapper();

  test('maps the complete ordered research projection exactly', () {
    final scene = testMapScene(cities: [testCityView()]);
    final result = mapper.options(
      _projection(),
      map: scene.map,
      player: scene.player,
      expectedRevision: 0,
    );

    expect(result.options, hasLength(TechnologyIdView.values.length));
    expect(
      result.options.map((option) => option.technology),
      TechnologyIdView.values,
    );
    expect(result.scienceYield.total, 5);
    expect(result.scienceYield.byCityId, {'preview-city': 5});
    final agriculture = result.options.first;
    expect(agriculture.availability, TechnologyAvailabilityView.available);
    expect(agriculture.effectiveCost, 12);
    expect(agriculture.progress, 6);
    expect(agriculture.boostDiscountBasisPoints, 2500);
    expect(agriculture.blockedBy, [TechnologyIdView.hunting]);
    expect(agriculture.unlocks.single.kind, TechnologyUnlockKindView.building);
    expect(agriculture.unlocks.single.target, 'granary');
  });

  test('rejects reordered catalogs and inconsistent science', () {
    final scene = testMapScene(cities: [testCityView()]);
    final reordered = [..._options()];
    final first = reordered.removeAt(0);
    reordered.insert(1, first);

    expect(
      () => mapper.options(
        _projection(options: reordered),
        map: scene.map,
        player: scene.player,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
    expect(
      () => mapper.options(
        _projection(
          scienceYield: AonwScienceYieldBreakdown(
            total: 6,
            byCityId: const {'preview-city': 5},
            sources: const [
              AonwScienceYieldSource(
                cityId: 'preview-city',
                amount: 5,
                kind: AonwScienceYieldSourceKind.cityScience,
              ),
            ],
          ),
        ),
        map: scene.map,
        player: scene.player,
        expectedRevision: 0,
      ),
      throwsFormatException,
    );
  });

  test('accepts only research command shape and rejection family', () {
    final map = testMapScene().map;

    expect(
      mapper.command(
        _accepted(),
        map: map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      isNull,
    );
    expect(
      mapper.command(
        _rejected(AonwCommandRejectionCode.technologyNotAvailable),
        map: map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      ResearchRejectionCodeView.technologyNotAvailable,
    );
    expect(
      () => mapper.command(
        _rejected(AonwCommandRejectionCode.workerNotFound),
        map: map,
        expectedRevision: 0,
        currentRevision: 0,
      ),
      throwsFormatException,
    );
  });
}

AonwResearchOptionsResult _projection({
  List<AonwResearchOption>? options,
  AonwScienceYieldBreakdown? scienceYield,
}) => AonwResearchOptionsResult(
  stamp: _stamp(),
  playerId: 'preview-player',
  activeTechnology: null,
  scienceOverflow: 3,
  scienceYield:
      scienceYield ??
      AonwScienceYieldBreakdown(
        total: 5,
        byCityId: const {'preview-city': 5},
        sources: const [
          AonwScienceYieldSource(
            cityId: 'preview-city',
            amount: 5,
            kind: AonwScienceYieldSourceKind.cityScience,
          ),
        ],
      ),
  options: options ?? _options(),
);

List<AonwResearchOption> _options() => [
  for (final technology in AonwTechnologyId.values)
    AonwResearchOption(
      technology: technology,
      availability: technology == AonwTechnologyId.agriculture
          ? AonwTechnologyAvailability.available
          : AonwTechnologyAvailability.lockedByPrerequisites,
      effectiveCost: technology == AonwTechnologyId.agriculture ? 12 : 20,
      progress: technology == AonwTechnologyId.agriculture ? 6 : 0,
      boostDiscountBasisPoints: technology == AonwTechnologyId.agriculture
          ? 2500
          : 0,
      prerequisites: const [],
      blockedBy: technology == AonwTechnologyId.agriculture
          ? const [AonwTechnologyId.hunting]
          : const [],
      unlocks: technology == AonwTechnologyId.agriculture
          ? const [AonwTechnologyBuildingUnlock(AonwCityBuildingType.granary)]
          : const [],
    ),
];

AonwCommandResult _accepted() => AonwCommandResult(
  stamp: _stamp(revision: 1),
  outcome: const AonwCommandAccepted(),
  events: const [],
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
