//! Canonical, framework-independent game-domain types.
//!
//! The crate owns invariants and deterministic state representation. It has no
//! serialization, persistence, networking, UI, framework, or ambient-time
//! dependencies.

#![forbid(unsafe_code)]

mod artifact;
mod city;
mod combat;
mod diplomacy;
mod economy;
mod fog;
mod game_state;
mod hex_coord;
mod hex_grid;
mod identifier;
mod infrastructure;
mod interaction;
mod match_lifecycle;
mod movement_path;
mod movement_units;
mod objective;
mod outcome;
mod research;
mod shared;
mod transport;
mod unit;
mod unit_kind;
mod unit_posture;

pub use artifact::{
    ArtifactTransitionError, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};
pub use city::{
    City, CityBuildError, CityBuilder, CityBuildingType, CityProductionQueue,
    CityProductionQueueBuildError, CityProductionTarget, CityProjectType, CitySpecializationType,
    WonderType,
};
pub use combat::{CityConquestAction, CombatState, CombatStateValidationError, IntendedAttack};
pub use diplomacy::{
    Diplomacy, DiplomacyStateBuildError, DiplomaticMessage, DiplomaticMessageCategory,
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind,
    DiplomaticRelation, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason, DiplomaticScoreEntry, PlayerPair, ResourceTradeAgreement,
};
pub use economy::{
    EconomyAccountChange, EconomyAccountKind, EconomyState, EconomyStateBuildError,
    InitialResourceDistribution, InitialResourcePlacement, ResourceType,
    StrategicResourceStockpile,
};
pub use fog::{FogOfWar, FogVisibility, PlayerFog};
pub use game_state::{
    GameState, GameStateBuildError, GameStateBuilder, UnitOccupancyPolicy,
    turn_update::{
        ArtifactStateUpdate, CombatBatchStepUpdate, CombatCityStateChange, CombatResolutionBatch,
        CombatStateUpdate, CombatUnitStateChange, DiplomacyStateUpdate, ProductionStateUpdate,
        ResearchStateUpdate, TurnKernelStateUpdate,
    },
};
pub use hex_coord::HexCoord;
pub use hex_grid::{HexGridBounds, HexTileIndex};
pub use identifier::{ArtifactId, CityId, IdentifierError, PlayerId, UnitId};
pub use infrastructure::{
    FieldImprovement, InfrastructureState, InfrastructureStateBuildError,
    InfrastructureValidationError,
};
pub use interaction::{CityFoundingDraft, InteractionState, PendingInteraction};
pub use match_lifecycle::{
    AiDifficulty, AiPersona, AiPlayer, AiStrategyId, GameLengthConfig, GameLengthKind, GameMode,
    MatchIdentity, MatchLifecycle, MatchRules, MatchRulesBuildError, PaceProfile, Participant,
    PlayerCountry, PlayerKind, PlayerTurnState, RuleNumber, RuleNumberError, RuleValue,
    TurnLifecycle, TurnLifecycleBuildError, TurnMode, UtcTimestamp, VictoryRules,
};
pub use movement_path::{MovementPathError, MovementStep, QueuedMovePath};
pub use movement_units::MovementUnits;
pub use objective::{MapObjectiveHoldState, ObjectiveState, ObjectiveStateBuildError};
pub use outcome::{GameOutcome, GameOutcomeBuildError, GameOutcomeCondition};
pub use research::{
    KnowledgeState, KnowledgeStateValidationError, PlayerResearchState,
    PlayerResearchStateBuildError, ResearchState, ResearchTransitionError, TechnologyId,
    WonderCompletionError, WonderRegistry,
};
pub use shared::StateRevision;
pub use transport::{TransportCondition, TransportKind, TransportNetwork, TransportSegment};
pub use unit::{
    ArmyTroop, CityFoundingJob, FieldImprovementKind, MerchantTradeRoute, TroopKind, Unit,
    UnitActivity, UnitBuildError, UnitBuilder, WorkerJob,
};
pub use unit_kind::{UnitKind, UnitMovementDomain};
pub use unit_posture::UnitPosture;
