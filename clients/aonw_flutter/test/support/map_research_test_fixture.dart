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

mixin FakeResearchSessionFixture implements ResearchSessionPort {
  ResearchOptionsView? get researchOptionsResult;
  ResearchCommandResultView? get researchResult;
  ResearchSessionException? get researchFailure;

  var researchOptionCalls = 0;
  var researchCommandCalls = 0;
  int? lastResearchExpectedRevision;
  TechnologyIdView? lastResearchTechnology;

  var researchCancellationCalls = 0;
  Future<ResearchCommandResultView> Function(int revision)?
  researchCancellationHandler;

  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) async {
    researchOptionCalls += 1;
    lastResearchExpectedRevision = expectedRevision;
    final error = researchFailure;
    if (error != null) throw error;
    return researchOptionsResult ??
        testResearchOptionsView(revision: expectedRevision);
  }

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) async {
    researchCommandCalls += 1;
    lastResearchExpectedRevision = expectedRevision;
    lastResearchTechnology = technology;
    final error = researchFailure;
    if (error != null) throw error;
    return researchResult ?? (throw StateError('No research result fixture.'));
  }

  @override
  Future<ResearchCommandResultView> cancelResearchSelection({
    required int expectedRevision,
  }) async {
    researchCancellationCalls += 1;
    lastResearchExpectedRevision = expectedRevision;
    final handler = researchCancellationHandler;
    if (handler != null) return handler(expectedRevision);
    final error = researchFailure;
    if (error != null) throw error;
    return researchResult ??
        (throw StateError('No research cancellation fixture.'));
  }
}
