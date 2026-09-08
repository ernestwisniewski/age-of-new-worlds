part of 'map_test_fixture.dart';

ResearchOptionsView testResearchOptionsView({
  int revision = 0,
  TechnologyIdView? activeTechnology,
}) => ResearchOptionsView(
  stamp: testSessionStamp(revision: revision),
  playerId: 'preview-player',
  activeTechnology: activeTechnology,
  scienceOverflow: 0,
  scienceYield: ScienceYieldBreakdownView(
    total: 0,
    byCityId: const {},
    sources: const [],
  ),
  options: [
    for (final technology in TechnologyIdView.values)
      ResearchOptionView(
        technology: technology,
        availability: technology == activeTechnology
            ? TechnologyAvailabilityView.active
            : TechnologyAvailabilityView.available,
        effectiveCost: 1,
        progress: 0,
        boostDiscountBasisPoints: 0,
        prerequisites: const [],
        blockedBy: const [],
        unlocks: const [],
      ),
  ],
);
