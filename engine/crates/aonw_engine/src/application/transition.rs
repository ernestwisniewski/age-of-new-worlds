mod artifact_events;
mod diplomacy_events;
mod domain_transition;
mod economy_events;
mod events;
mod objective_events;
mod outcome;
mod outcome_events;
mod production_events;
mod rejection_code_wire;
mod research_events;

pub use artifact_events::{
    ArtifactCarriedEvent, ArtifactExcavationStartedEvent, ArtifactStoredEvent,
};
pub use diplomacy_events::{
    DiplomaticMessageRespondedEvent, DiplomaticMessageSentEvent, DiplomaticPromiseBrokenEvent,
    DiplomaticProposalExpiredEvent, DiplomaticProposalRespondedEvent, DiplomaticProposalSentEvent,
    DiplomaticRelationChangedEvent,
};
pub use domain_transition::{DomainRejection, DomainTransition, DomainTransitionParts};
pub use economy_events::{CityClaimedHexEvent, StabilityBand, StabilityBandChangedEvent};
pub use events::{
    AllPlayersSubmittedEvent, CityFoundedEvent, CombatEvent, DiplomaticScoreChangedEvent,
    PlayerKickedEvent, PlayerTimedOutEvent, TurnEndedEvent, WorkerCompletedJobEvent,
    WorkerJobCompletion,
};
pub use objective_events::{DominationThresholdReachedEvent, MapObjectiveSecuredEvent};
pub use outcome::{DomainEvent, ExecutionEvidence};
pub use outcome_events::MatchEndedEvent;
pub use production_events::{
    CityBuiltBuildingEvent, CityBuiltWonderEvent, CityProducedUnitEvent, TechnologyResearchedEvent,
    WonderProductionRefundedEvent,
};
pub use research_events::ResearchPointsGainedEvent;

/// Stable command rejection shared by every authoritative command family.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum CommandRejectionCode {
    /// Command was planned against another canonical revision.
    StaleRevision,
    /// The authoritative match result is already terminal.
    MatchFinished,
    /// The requested unit does not exist.
    UnitNotFound,
    /// The actor cannot command the requested unit.
    UnitNotControlled,
    /// Current activity prevents manual movement.
    UnitUnavailable,
    /// The unit is controlled by the trade-route subsystem.
    UnitUsesTradeRoutes,
    /// The canonical unit position is outside the map.
    UnitOutOfBounds,
    /// The requested movement target is outside the map.
    MoveTargetOutOfBounds,
    /// The movement target equals the current unit position.
    MoveTargetIsCurrentTile,
    /// A known foreign city blocks the target.
    MoveTargetIsForeignCityCenter,
    /// A known foreign unit blocks the target.
    MoveTargetOccupied,
    /// The unit cannot pay the minimum movement cost.
    UnitMovementCapacityInsufficient,
    /// No valid route reaches the target.
    MovePathNotFound,
    /// Auto-exploration requires a scout.
    UnitNotScout,
    /// The unit has no movement left for auto-exploration.
    UnitExhausted,
    /// Auto-exploration cannot replace an existing queued path.
    UnitHasPath,
    /// No deterministic exploration target remains.
    AutoExploreNoTarget,
    /// Merchant routing requires a merchant unit.
    UnitNotMerchant,
    /// A cyclic route can only start in an owned city center.
    MerchantNotInCity,
    /// The requested destination city does not exist.
    DestinationCityNotFound,
    /// The requested destination city is not controlled by the actor.
    DestinationCityNotControlled,
    /// A cyclic merchant destination equals its origin.
    DestinationCityIsOrigin,
    /// Explicit merchant travel already starts in the destination city.
    DestinationCityIsCurrent,
    /// No cyclic merchant route reaches the destination.
    MerchantRouteNotFound,
    /// No explicit merchant path reaches the destination city.
    MerchantCityPathNotFound,
    /// The requested troop is absent from the source army.
    TroopNotAvailable,
    /// The detachment source is outside immutable map content.
    DetachmentSourceOutOfBounds,
    /// No visible, passable, unoccupied detachment destination exists.
    DetachmentDestinationUnavailable,
    /// No bounded canonical identifier can be assigned to the detached unit.
    DetachedUnitIdUnavailable,
    /// The unit has an activity that prevents the requested action.
    UnitBusy,
    /// The ruleset lacks the requested unit definition.
    UnitDefinitionMissing,
    /// The next canonical revision cannot be represented.
    StateRevisionOverflow,
    /// A queued movement path violates its invariants.
    InvalidQueuedMovementPath,
    /// An engine-produced unit violates its invariants.
    InvalidUnit,
    /// The validated movement unit disappeared during transition construction.
    MovementUnitUpdateFailed,
    /// Player payload identity conflicts with authenticated actor identity.
    TurnPlayerNotControlled,
    /// Participant cannot act in the current turn scope.
    TurnPlayerNotActive,
    /// Trusted player scope is empty, duplicated, or inconsistent.
    TurnScopeInvalid,
    /// A later turn processor was requested from the partial T1 kernel.
    TurnProcessorUnsupported,
    /// The next turn number cannot be represented.
    TurnNumberOverflow,
    /// The requested attacking unit does not exist.
    AttackerNotFound,
    /// The actor cannot command the requested attacker.
    AttackerNotControlled,
    /// Current activity prevents the attacker from acting.
    AttackerUnavailable,
    /// The attacker has no movement remaining.
    AttackerExhausted,
    /// The attacker position is outside the canonical map.
    AttackerOutOfBounds,
    /// The attacking unit has no positive attack strength.
    AttackerCannotAttack,
    /// The target coordinate is not currently visible to the actor.
    AttackTargetNotVisible,
    /// The target coordinate is outside the canonical map.
    AttackTargetOutOfBounds,
    /// No unit or city occupies the target coordinate.
    AttackTargetNotFound,
    /// The target belongs to the attacking player.
    AttackTargetNotEnemy,
    /// A friendly or truce relation protects the target.
    AttackTargetProtectedByTreaty,
    /// The target exceeds the effective attack range.
    AttackTargetOutOfRange,
    /// A target city has no positive current health.
    AttackCityHasNoHealth,
    /// The requested city founder does not exist.
    CityFounderNotFound,
    /// The actor cannot command the requested founder.
    CityFounderNotControlled,
    /// The founder is already performing authoritative work.
    CityFounderBusy,
    /// The unit cannot found cities.
    CityFounderInvalid,
    /// A commander army has no settler troop to consume.
    CityFounderNoSettlers,
    /// The founder's current tile cannot contain a city center.
    CitySiteInvalid,
    /// Another city already occupies the requested center.
    CityCenterOccupied,
    /// Another city controls the requested center.
    CityCenterClaimed,
    /// The requested center is too close to another city.
    CityCenterTooClose,
    /// Initial controlled territory is incomplete or invalid.
    CityControlledHexesInvalid,
    /// The requested city does not exist.
    CityNotFound,
    /// The actor cannot manage the requested city.
    CityNotControlled,
    /// The coordinate cannot be manually worked by the city.
    WorkedHexUnavailable,
    /// The city already manually works its population-based limit.
    WorkedHexLimitReached,
    /// The coordinate is not a legal current expansion candidate.
    CityExpansionHexUnavailable,
    /// The building is already present, locked, or misses a map requirement.
    BuildingNotAvailable,
    /// A strategic-resource option index does not exist for this unit.
    UnitProductionInvalidResourceOption,
    /// The unit is not producible or is technology-locked.
    UnitProductionNotAvailable,
    /// The empire lacks a visible controlled presence resource.
    UnitProductionRequiresResource,
    /// No strategic-resource alternative can be reserved.
    UnitProductionMissingStrategicResource,
    /// A naval unit requires an ocean-adjacent coastal spawn topology.
    UnitProductionRequiresCoast,
    /// Queuing the unit would exceed canonical supply capacity.
    UnitSupplyLimitReached,
    /// The wonder is completed, locked, blocked, or another wonder is active.
    WonderNotAvailable,
    /// City specialization technology is not unlocked.
    CitySpecializationLocked,
    /// The requested specialization is already selected.
    CitySpecializationUnchanged,
    /// The specialization prerequisite building is missing.
    CitySpecializationMissingBuilding,
    /// The city has no active production queue.
    ProductionQueueEmpty,
    /// Continuous projects cannot be rushed.
    ProjectCannotBeRushed,
    /// No positive affordable rush quote exists.
    RushProductionUnavailable,
    /// The controlled unit already carries an artifact.
    UnitAlreadyCarryingArtifact,
    /// No map artifact occupies the controlled unit's coordinate.
    ArtifactNotFound,
    /// The controlled unit does not carry an artifact.
    UnitNotCarryingArtifact,
    /// The controlled unit does not occupy the requested city center.
    UnitNotInCity,
    /// The requested city already stores an artifact.
    CityArtifactSlotFull,
    /// The authenticated actor cannot select a technology.
    TechnologyPlayerNotControlled,
    /// The technology is unlocked, active, blocked, or misses prerequisites.
    TechnologyNotAvailable,
    /// The authenticated actor cannot issue diplomacy commands.
    DiplomacyPlayerNotControlled,
    /// The target participant has not been discovered by the actor.
    DiplomacyTargetNotDiscovered,
    /// Current relation status forbids this proposal kind.
    DiplomacyProposalNotAllowed,
    /// The same proposal or proposal identifier is already pending.
    DiplomacyDuplicateProposal,
    /// The requested proposal is absent or addressed to another participant.
    DiplomacyProposalNotFound,
    /// The original sender can no longer fund an accepted truce payment.
    DiplomacyProposalPaymentUnavailable,
    /// A recent message of the same category is still on cooldown.
    DiplomacyMessageCooldown,
    /// The requested or generated message identity is already present.
    DiplomacyDuplicateMessage,
    /// The requested message is absent or addressed to another participant.
    DiplomacyMessageNotFound,
    /// The requested message was already answered or has expired.
    DiplomacyMessageUnavailable,
    /// A non-expired truce prevents declaring war.
    DiplomacyTruceActive,
    /// The bilateral relation is already at war.
    DiplomacyWarAlreadyActive,
    /// A gold gift cannot have a negative amount.
    DiplomacyInvalidGoldAmount,
    /// War and truce relations forbid gold gifts.
    DiplomacyGoldGiftBlockedByRelation,
    /// The requested gold transfer cannot be funded atomically.
    DiplomacyGoldUnavailable,
    /// The gift is below the minimum score threshold or still on cooldown.
    DiplomacyGoldGiftUnavailable,
    /// The requested resource trade targets the authenticated actor.
    InvalidResourceTradeTarget,
    /// At least one requested resource is not strategic.
    InvalidResourceTradeResource,
    /// Gold, duration, or exchange terms are invalid.
    InvalidResourceTradeTerms,
    /// Current war policy blocks opening a resource agreement.
    ResourceTradeBlockedByWar,
    /// The importer cannot fund the first gold settlement.
    ResourceTradeGoldUnavailable,
    /// The same directed resource import is already active.
    ResourceTradeAlreadyActive,
    /// A caller-supplied agreement identity is malformed.
    InvalidResourceTradeAgreementId,
    /// A caller-supplied agreement identity collides with an active token.
    ResourceTradeAgreementIdConflict,
    /// The requested exporter has no uncommitted resource output.
    ResourceTradeExportUnavailable,
    /// The actor has no uncommitted output for the offered exchange resource.
    ResourceTradeOfferUnavailable,
    /// The counterparty has no uncommitted output for the requested exchange resource.
    ResourceTradeRequestUnavailable,
    /// The authenticated actor cannot initiate an artifact trade.
    ArtifactTradeActorUnavailable,
    /// The artifact trade target is absent or equals the actor.
    ArtifactTradeTargetInvalid,
    /// Offered artifact-trade gold is negative.
    ArtifactTradeGoldInvalid,
    /// Current war policy blocks artifact trade.
    ArtifactTradeBlockedByWar,
    /// The offered gold cannot be transferred atomically.
    ArtifactTradeGoldUnavailable,
    /// The offered artifact is not stored in an actor-owned city.
    OfferedArtifactUnavailable,
    /// The target player has no empty city artifact slot.
    TargetArtifactSlotUnavailable,
    /// The requested worker does not exist or is not a worker.
    WorkerNotFound,
    /// The actor cannot command the requested worker.
    WorkerNotControlled,
    /// Current activity or posture prevents worker automation.
    WorkerUnavailable,
    /// The worker has no movement remaining.
    WorkerNoMovementPoints,
    /// A manual queued route prevents starting worker automation.
    WorkerQueuedPathActive,
    /// Confirmation omitted an explicit and matching pending selection.
    WorkerImprovementNotSelected,
    /// The pending worker selection belongs to another actor.
    WorkerActionNotControlled,
    /// The requested improvement is not currently legal.
    WorkerImprovementUnavailable,
    /// No worker job exists to cancel.
    WorkerJobNotActive,
    /// The current hex cannot receive a worker assignment.
    WorkerAssignmentUnavailable,
    /// No worker assignment exists to cancel.
    WorkerAssignmentNotActive,
    /// Generic road-construction readiness failure.
    WorkerRoadUnavailable,
    /// The coordinate already contains a road.
    RoadConstructionExistingRoad,
    /// City centers cannot receive road-construction jobs.
    RoadConstructionCity,
    /// Diplomacy policy forbids construction in this territory.
    RoadConstructionEnemyTerritory,
    /// Land movement cannot enter the construction coordinate.
    RoadConstructionImpassableTerrain,
    /// Automation continuation was requested for a non-automated worker.
    WorkerAutomationNotActive,
    /// No deterministic legal automation target exists.
    WorkerAutomationNoTarget,
}

impl CommandRejectionCode {
    /// Complete stable rejection surface exposed to current clients.
    pub const ALL: [Self; 140] = [
        Self::StaleRevision,
        Self::UnitNotFound,
        Self::UnitNotControlled,
        Self::UnitUnavailable,
        Self::UnitUsesTradeRoutes,
        Self::UnitOutOfBounds,
        Self::MoveTargetOutOfBounds,
        Self::MoveTargetIsCurrentTile,
        Self::MoveTargetIsForeignCityCenter,
        Self::MoveTargetOccupied,
        Self::UnitMovementCapacityInsufficient,
        Self::MovePathNotFound,
        Self::UnitNotScout,
        Self::UnitExhausted,
        Self::UnitHasPath,
        Self::AutoExploreNoTarget,
        Self::UnitNotMerchant,
        Self::MerchantNotInCity,
        Self::DestinationCityNotFound,
        Self::DestinationCityNotControlled,
        Self::DestinationCityIsOrigin,
        Self::DestinationCityIsCurrent,
        Self::MerchantRouteNotFound,
        Self::MerchantCityPathNotFound,
        Self::TroopNotAvailable,
        Self::DetachmentSourceOutOfBounds,
        Self::DetachmentDestinationUnavailable,
        Self::DetachedUnitIdUnavailable,
        Self::UnitBusy,
        Self::UnitDefinitionMissing,
        Self::StateRevisionOverflow,
        Self::InvalidQueuedMovementPath,
        Self::InvalidUnit,
        Self::MovementUnitUpdateFailed,
        Self::TurnPlayerNotControlled,
        Self::TurnPlayerNotActive,
        Self::TurnScopeInvalid,
        Self::TurnProcessorUnsupported,
        Self::TurnNumberOverflow,
        Self::AttackerNotFound,
        Self::AttackerNotControlled,
        Self::AttackerUnavailable,
        Self::AttackerExhausted,
        Self::AttackerOutOfBounds,
        Self::AttackerCannotAttack,
        Self::AttackTargetNotVisible,
        Self::AttackTargetOutOfBounds,
        Self::AttackTargetNotFound,
        Self::AttackTargetNotEnemy,
        Self::AttackTargetProtectedByTreaty,
        Self::AttackTargetOutOfRange,
        Self::AttackCityHasNoHealth,
        Self::CityFounderNotFound,
        Self::CityFounderNotControlled,
        Self::CityFounderBusy,
        Self::CityFounderInvalid,
        Self::CityFounderNoSettlers,
        Self::CitySiteInvalid,
        Self::CityCenterOccupied,
        Self::CityCenterClaimed,
        Self::CityCenterTooClose,
        Self::CityControlledHexesInvalid,
        Self::CityNotFound,
        Self::CityNotControlled,
        Self::WorkedHexUnavailable,
        Self::WorkedHexLimitReached,
        Self::CityExpansionHexUnavailable,
        Self::BuildingNotAvailable,
        Self::UnitProductionInvalidResourceOption,
        Self::UnitProductionNotAvailable,
        Self::UnitProductionRequiresResource,
        Self::UnitProductionMissingStrategicResource,
        Self::UnitProductionRequiresCoast,
        Self::UnitSupplyLimitReached,
        Self::WonderNotAvailable,
        Self::CitySpecializationLocked,
        Self::CitySpecializationUnchanged,
        Self::CitySpecializationMissingBuilding,
        Self::ProductionQueueEmpty,
        Self::ProjectCannotBeRushed,
        Self::RushProductionUnavailable,
        Self::UnitAlreadyCarryingArtifact,
        Self::ArtifactNotFound,
        Self::UnitNotCarryingArtifact,
        Self::UnitNotInCity,
        Self::CityArtifactSlotFull,
        Self::TechnologyPlayerNotControlled,
        Self::TechnologyNotAvailable,
        Self::DiplomacyPlayerNotControlled,
        Self::DiplomacyTargetNotDiscovered,
        Self::DiplomacyProposalNotAllowed,
        Self::DiplomacyDuplicateProposal,
        Self::DiplomacyProposalNotFound,
        Self::DiplomacyProposalPaymentUnavailable,
        Self::DiplomacyMessageCooldown,
        Self::DiplomacyDuplicateMessage,
        Self::DiplomacyMessageNotFound,
        Self::DiplomacyMessageUnavailable,
        Self::DiplomacyTruceActive,
        Self::DiplomacyWarAlreadyActive,
        Self::DiplomacyInvalidGoldAmount,
        Self::DiplomacyGoldGiftBlockedByRelation,
        Self::DiplomacyGoldUnavailable,
        Self::DiplomacyGoldGiftUnavailable,
        Self::InvalidResourceTradeTarget,
        Self::InvalidResourceTradeResource,
        Self::InvalidResourceTradeTerms,
        Self::ResourceTradeBlockedByWar,
        Self::ResourceTradeGoldUnavailable,
        Self::ResourceTradeAlreadyActive,
        Self::InvalidResourceTradeAgreementId,
        Self::ResourceTradeAgreementIdConflict,
        Self::ResourceTradeExportUnavailable,
        Self::ResourceTradeOfferUnavailable,
        Self::ResourceTradeRequestUnavailable,
        Self::ArtifactTradeActorUnavailable,
        Self::ArtifactTradeTargetInvalid,
        Self::ArtifactTradeGoldInvalid,
        Self::ArtifactTradeBlockedByWar,
        Self::ArtifactTradeGoldUnavailable,
        Self::OfferedArtifactUnavailable,
        Self::TargetArtifactSlotUnavailable,
        Self::WorkerNotFound,
        Self::WorkerNotControlled,
        Self::WorkerUnavailable,
        Self::WorkerNoMovementPoints,
        Self::WorkerQueuedPathActive,
        Self::WorkerImprovementNotSelected,
        Self::WorkerActionNotControlled,
        Self::WorkerImprovementUnavailable,
        Self::WorkerJobNotActive,
        Self::WorkerAssignmentUnavailable,
        Self::WorkerAssignmentNotActive,
        Self::WorkerRoadUnavailable,
        Self::RoadConstructionExistingRoad,
        Self::RoadConstructionCity,
        Self::RoadConstructionEnemyTerritory,
        Self::RoadConstructionImpassableTerrain,
        Self::WorkerAutomationNotActive,
        Self::WorkerAutomationNoTarget,
    ];
}
