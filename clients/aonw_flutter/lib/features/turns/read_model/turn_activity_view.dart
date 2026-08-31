enum TurnActivityKindView {
  artifactExcavationStarted,
  artifactCarried,
  artifactStored,
  cityFounded,
  cityBuiltBuilding,
  cityProducedUnit,
  cityBuiltWonder,
  wonderProductionRefunded,
  technologyResearched,
  researchPointsGained,
  cityClaimedHex,
  stabilityBandChanged,
  mapObjectiveSecured,
  dominationThresholdReached,
  matchEnded,
  unitAttacked,
  cityAttacked,
  combatResolved,
  diplomaticScoreChanged,
  diplomaticProposalSent,
  diplomaticProposalResponded,
  diplomaticProposalExpired,
  diplomaticMessageSent,
  diplomaticMessageResponded,
  diplomaticPromiseBroken,
  diplomaticRelationChanged,
  unitGainedExperience,
  unitKilled,
  unitRetreated,
  cityCaptured,
  cityDestroyed,
  unitMoved,
  autoExplorePlanned,
  merchantRouteAssigned,
  merchantTravelQueued,
  troopDetached,
  turnEnded,
  allPlayersSubmitted,
  playerTimedOut,
  playerKicked,
  workerCompletedJob,
}

final class TurnActivityIdentityView {
  const TurnActivityIdentityView({
    required this.revision,
    required this.eventIndex,
  });

  final int revision;
  final int eventIndex;

  @override
  bool operator ==(Object other) =>
      other is TurnActivityIdentityView &&
      revision == other.revision &&
      eventIndex == other.eventIndex;

  @override
  int get hashCode => Object.hash(revision, eventIndex);
}

final class TurnActivityView {
  const TurnActivityView({required this.identity, required this.kind});

  final TurnActivityIdentityView identity;
  final TurnActivityKindView kind;
}

final class TurnKernelEvidenceView {
  TurnKernelEvidenceView({
    required List<String> processors,
    required List<String> foundedCityIds,
    required this.combatExecutionCount,
    required List<String> resetUnitIds,
    required this.movementExecutionCount,
    required List<String> invalidatedOrderUnitIds,
    required List<String> finishedAutoExploreUnitIds,
  }) : processors = List.unmodifiable(processors),
       foundedCityIds = List.unmodifiable(foundedCityIds),
       resetUnitIds = List.unmodifiable(resetUnitIds),
       invalidatedOrderUnitIds = List.unmodifiable(invalidatedOrderUnitIds),
       finishedAutoExploreUnitIds = List.unmodifiable(
         finishedAutoExploreUnitIds,
       );

  final List<String> processors;
  final List<String> foundedCityIds;
  final int combatExecutionCount;
  final List<String> resetUnitIds;
  final int movementExecutionCount;
  final List<String> invalidatedOrderUnitIds;
  final List<String> finishedAutoExploreUnitIds;
}
