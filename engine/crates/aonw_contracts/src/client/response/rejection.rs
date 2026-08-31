use serde::{Deserialize, Serialize};

mod wire;

/// Closed set of stable authoritative command rejection codes.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ClientCommandRejectionCodeDto {
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
    /// The movement target is outside the map.
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
    /// No legal detachment destination exists.
    DetachmentDestinationUnavailable,
    /// No bounded canonical detached-unit identifier is available.
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
    /// Trusted lifecycle scope is invalid.
    TurnScopeInvalid,
    /// A later turn processor was requested from the partial kernel.
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
    /// The attacker position is outside the map.
    AttackerOutOfBounds,
    /// The attacker has no positive attack strength.
    AttackerCannotAttack,
    /// The target is not visible.
    AttackTargetNotVisible,
    /// The target coordinate is outside the map.
    AttackTargetOutOfBounds,
    /// No target occupies the coordinate.
    AttackTargetNotFound,
    /// The target belongs to the actor.
    AttackTargetNotEnemy,
    /// A treaty protects the target.
    AttackTargetProtectedByTreaty,
    /// The target exceeds attack range.
    AttackTargetOutOfRange,
    /// The target city has no health.
    AttackCityHasNoHealth,
    /// The requested city founder does not exist.
    CityFounderNotFound,
    /// The actor cannot command the requested founder.
    CityFounderNotControlled,
    /// The founder is already performing work.
    CityFounderBusy,
    /// The unit cannot found cities.
    CityFounderInvalid,
    /// A commander has no settler troop.
    CityFounderNoSettlers,
    /// The center tile cannot host a city.
    CitySiteInvalid,
    /// Another city occupies the center.
    CityCenterOccupied,
    /// Another city controls the center.
    CityCenterClaimed,
    /// The center is too close to another city.
    CityCenterTooClose,
    /// Initial territory is invalid.
    CityControlledHexesInvalid,
    /// The requested city does not exist.
    CityNotFound,
    /// The actor cannot manage the city.
    CityNotControlled,
    /// The requested worked hex is unavailable.
    WorkedHexUnavailable,
    /// The manual worked-hex limit was reached.
    WorkedHexLimitReached,
    /// The expansion coordinate is unavailable.
    CityExpansionHexUnavailable,
    /// The building is already present, locked, or misses a requirement.
    BuildingNotAvailable,
    /// The requested strategic-resource alternative does not exist.
    UnitProductionInvalidResourceOption,
    /// The unit is not producible or is technology-locked.
    UnitProductionNotAvailable,
    /// The empire lacks a visible required resource.
    UnitProductionRequiresResource,
    /// No strategic-resource alternative can be reserved.
    UnitProductionMissingStrategicResource,
    /// Naval production requires ocean-adjacent coast.
    UnitProductionRequiresCoast,
    /// Queuing the unit would exceed supply capacity.
    UnitSupplyLimitReached,
    /// The wonder is not a legal current target.
    WonderNotAvailable,
    /// Specialization technology is locked.
    CitySpecializationLocked,
    /// The requested specialization is already active.
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
    /// The technology is not a legal current research target.
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
    /// Current activity prevents automation.
    WorkerUnavailable,
    /// The worker has no movement remaining.
    WorkerNoMovementPoints,
    /// A queued path prevents starting automation.
    WorkerQueuedPathActive,
    /// No improvement was supplied or pending.
    WorkerImprovementNotSelected,
    /// A pending action belongs to another actor.
    WorkerActionNotControlled,
    /// The requested improvement is unavailable.
    WorkerImprovementUnavailable,
    /// No worker job is active.
    WorkerJobNotActive,
    /// The current assignment is unavailable.
    WorkerAssignmentUnavailable,
    /// No worker assignment is active.
    WorkerAssignmentNotActive,
    /// Generic road readiness failure.
    WorkerRoadUnavailable,
    /// A road already occupies the coordinate.
    #[serde(rename = "road_construction_existingRoad")]
    RoadConstructionExistingRoad,
    /// A city occupies the coordinate.
    RoadConstructionCity,
    /// Diplomacy policy forbids construction.
    #[serde(rename = "road_construction_enemyTerritory")]
    RoadConstructionEnemyTerritory,
    /// Land movement cannot enter the coordinate.
    #[serde(rename = "road_construction_impassableTerrain")]
    RoadConstructionImpassableTerrain,
    /// Worker automation is not active.
    WorkerAutomationNotActive,
    /// No deterministic worker target exists.
    WorkerAutomationNoTarget,
}
impl ClientCommandRejectionCodeDto {
    /// Every code supported by the current client protocol.
    pub const ALL: [Self; 141] = [
        Self::StaleRevision,
        Self::MatchFinished,
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
