use crate::{
    AllPlayersSubmittedEvent, ArtifactCarriedEvent, ArtifactExcavationStartedEvent,
    ArtifactStoredEvent, AutoExplorePlannedEvent, CityBuiltBuildingEvent, CityBuiltWonderEvent,
    CityClaimedHexEvent, CityFoundedEvent, CityProducedUnitEvent, CombatEvent, CombatExecution,
    DiplomaticScoreChangedEvent, LogisticsExecution, MerchantRouteAssignedEvent,
    MerchantTravelQueuedEvent, PlayerKickedEvent, PlayerTimedOutEvent, ResearchPointsGainedEvent,
    TechnologyResearchedEvent, TroopDetachedEvent, TurnEndedEvent, TurnKernelExecution,
    UnitMovedEvent, UnitMovementExecution, WonderProductionRefundedEvent,
    WorkerAutomationExecution, WorkerCompletedJobEvent,
};
use crate::{
    DiplomaticMessageRespondedEvent, DiplomaticMessageSentEvent, DiplomaticPromiseBrokenEvent,
    DiplomaticProposalExpiredEvent, DiplomaticProposalRespondedEvent, DiplomaticProposalSentEvent,
    DiplomaticRelationChangedEvent, DominationThresholdReachedEvent, MapObjectiveSecuredEvent,
    MatchEndedEvent, StabilityBandChangedEvent,
};

/// Ordered event emitted by an accepted transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DomainEvent {
    /// One unit started excavating an artifact.
    ArtifactExcavationStarted(ArtifactExcavationStartedEvent),
    /// One completed excavation moved an artifact to its unit.
    ArtifactCarried(ArtifactCarriedEvent),
    /// One carried or traded artifact entered city storage.
    ArtifactStored(ArtifactStoredEvent),
    /// One city-founding job completed.
    CityFounded(CityFoundedEvent),
    /// One city completed a building.
    CityBuiltBuilding(CityBuiltBuildingEvent),
    /// One city produced a unit.
    CityProducedUnit(CityProducedUnitEvent),
    /// One city won a globally unique wonder race.
    CityBuiltWonder(CityBuiltWonderEvent),
    /// A losing wonder queue was converted to production overflow.
    WonderProductionRefunded(WonderProductionRefundedEvent),
    /// A completion effect unlocked the selected technology.
    TechnologyResearched(TechnologyResearchedEvent),
    /// One participant produced positive science during turn progression.
    ResearchPointsGained(ResearchPointsGainedEvent),
    /// One growing city claimed a deterministic territory coordinate.
    CityClaimedHex(CityClaimedHexEvent),
    /// One player's recomputed stability crossed a band boundary.
    StabilityBandChanged(StabilityBandChangedEvent),
    /// One player crossed an authored map objective's hold threshold.
    MapObjectiveSecured(MapObjectiveSecuredEvent),
    /// One player started a domination-threshold hold.
    DominationThresholdReached(DominationThresholdReachedEvent),
    /// Authoritative turn processing produced a terminal match result.
    MatchEnded(MatchEndedEvent),
    /// One unit changed map position.
    UnitMoved(UnitMovedEvent),
    /// Auto-exploration selected an engine-owned target.
    AutoExplorePlanned(AutoExplorePlannedEvent),
    /// A cyclic merchant route was assigned.
    MerchantRouteAssigned(MerchantRouteAssignedEvent),
    /// Explicit merchant travel was queued.
    MerchantTravelQueued(MerchantTravelQueuedEvent),
    /// One army troop became an independent unit.
    TroopDetached(TroopDetachedEvent),
    /// One participant completed its sequential turn.
    TurnEnded(TurnEndedEvent),
    /// Every required participant became ready for simultaneous finalization.
    AllPlayersSubmitted(AllPlayersSubmittedEvent),
    /// The trusted host finalized one participant on timeout.
    PlayerTimedOut(PlayerTimedOutEvent),
    /// The trusted host removed one participant from active lifecycle.
    PlayerKicked(PlayerKickedEvent),
    /// A visible attacker engaged a visible target.
    UnitAttacked(CombatEvent),
    /// A visible attacker engaged a visible city.
    CityAttacked(CombatEvent),
    /// Exact authoritative combat resolution occurred.
    CombatResolved(CombatEvent),
    /// A known observer applied a city-attack reputation penalty.
    DiplomaticScoreChanged(DiplomaticScoreChangedEvent),
    /// One participant sent a private bilateral proposal.
    DiplomaticProposalSent(DiplomaticProposalSentEvent),
    /// The proposal recipient accepted or rejected it.
    DiplomaticProposalResponded(DiplomaticProposalRespondedEvent),
    /// One unanswered bilateral proposal reached its expiry boundary.
    DiplomaticProposalExpired(DiplomaticProposalExpiredEvent),
    /// One participant sent a private bilateral message.
    DiplomaticMessageSent(DiplomaticMessageSentEvent),
    /// The message recipient selected one response tone.
    DiplomaticMessageResponded(DiplomaticMessageRespondedEvent),
    /// One accepted withdrawal promise was broken by unit proximity.
    DiplomaticPromiseBroken(DiplomaticPromiseBrokenEvent),
    /// One known bilateral status changed.
    DiplomaticRelationChanged(DiplomaticRelationChangedEvent),
    /// A surviving unit gained combat experience.
    UnitGainedExperience(CombatEvent),
    /// A defeated unit was removed.
    UnitKilled(CombatEvent),
    /// A surviving defender changed position.
    UnitRetreated(CombatEvent),
    /// A defeated city changed owner.
    CityCaptured(CombatEvent),
    /// A defeated city was removed.
    CityDestroyed(CombatEvent),
    /// One worker job completed successfully.
    WorkerCompletedJob(WorkerCompletedJobEvent),
}

/// Exact evidence used by clients for deterministic presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ExecutionEvidence {
    /// Exact movement steps executed by the engine.
    UnitMovement(UnitMovementExecution),
    /// Exact result of one movement-logistics command.
    Logistics(LogisticsExecution),
    /// Exact capability-gated processors executed by the T1 turn kernel.
    TurnKernel(TurnKernelExecution),
    /// Exact seed, rolls, modifiers, damage and retreat result for one attack.
    Combat(CombatExecution),
    /// Exact target, bounded counters, and movement selected by worker automation.
    WorkerAutomation(WorkerAutomationExecution),
}
