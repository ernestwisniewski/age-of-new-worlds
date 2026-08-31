//! Domain-independent DTOs for current engine boundaries.
//!
//! These values define admissible data shape, not game invariants. Conversion
//! into canonical domain types belongs to `aonw_contract_mapping`. Current
//! canonical state DTOs provide a strict bounded JSON codec; framework-specific
//! transport remains outside this crate.

#![forbid(unsafe_code)]

mod canonical;
pub mod client;
mod combat;
mod limits;
mod persistence;
pub mod server;

pub use canonical::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, ArmyTroopDto, CityBuildingTypeDto,
    CityConquestActionDto, CityDto, CityFoundingDraftDto, CityFoundingJobDto,
    CityProductionQueueDto, CityProductionTargetDto, CityProjectTypeDto, CitySpecializationTypeDto,
    CoordinateDto, CulturalVictoryHoldTurnsDto, DiplomacyStateDto, DiplomaticMessageCategoryDto,
    DiplomaticMessageDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalDto, DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto,
    DiplomaticRelationDto, DiplomaticRelationStatusDto, DiplomaticScoreChangeReasonDto,
    DiplomaticScoreEntryDto, DominationHoldTurnsDto, EconomyStateDto, FieldImprovementDto,
    FieldImprovementKindDto, GameLengthConfigDto, GameLengthKindDto, GameModeDto,
    GameOutcomeConditionDto, GameOutcomeDto, GameStateCodecError, GameStateDto,
    InitialResourceDistributionDto, InitialResourcePlacementDto, IntendedAttackDto,
    InteractionStateDto, MapObjectiveHoldStateDto, MatchIdentityDto, MatchRulesDto,
    MerchantTradeRouteDto, PaceProfileDto, ParticipantDto, PendingInteractionDto, PlayerCountryDto,
    PlayerFogDto, PlayerKindDto, PlayerPairDto, PlayerResearchStateDto, PlayerTurnStateDto,
    ResearchStateDto, ResourceTradeAgreementDto, ResourceTypeDto, RuleValueDto,
    StrategicResourceStockpileDto, TechnologyIdDto, TransportConditionDto, TransportSegmentDto,
    TransportSegmentKindDto, TroopKindDto, TurnLifecycleDto, UnitActivityDto, UnitDto,
    UnitOccupancyPolicyDto, VictoryRulesDto, WonderRegistryDto, WonderTypeDto, WorkerJobDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};

pub use combat::{
    CombatExecutionDto, CombatModifierDto, CombatModifierKindDto, CombatOutcomeDto,
    CombatPreviewDto, CombatRollDto, CombatStatTargetDto, CombatStatsDto, CombatTargetDto,
};
pub use limits::{
    MAX_GAME_STATE_UNIT_COUNT, MAX_MOVEMENT_BALANCE_UNITS, MAX_QUEUED_PATH_STEP_COUNT,
};
pub use persistence::{
    MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_LOG_JSON_BYTES, MAX_REPLAY_SEGMENT_COUNT,
    MAX_SAVE_GAME_JSON_BYTES, PERSISTENCE_FORMAT_VERSION, PersistenceCodecError, ReplayCommandDto,
    ReplayContextDto, ReplayEntryDto, ReplayEventDto, ReplayEvidenceDto, ReplayLogDto,
    ReplayLogisticsEvidenceDto, ReplayRecordDto, ReplayResultDto, ReplaySegmentDto,
    ReplaySystemCommandDto, ReplayUnitMovementExecutionDto, SaveGameDto,
};

/// Stable authored map-objective type shared by client and replay contracts.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapObjectiveTypeDto {
    Ruins,
    StrategicPass,
    HolySite,
    LegendaryResource,
}

/// Stable presentation band derived from one participant's current stability net.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub enum StabilityBandDto {
    Content,
    Stable,
    Strained,
    Unrest,
}

/// Stable unit type used at engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitKindDto {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

/// Persistent unit behavior used at engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitPostureDto {
    Active,
    Fortified,
    AutoExploring,
    AutoWorking,
}

/// One persisted step of a queued movement route.
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MovementStepDto {
    /// Odd-q offset-grid column.
    pub col: i32,
    /// Odd-q offset-grid row.
    pub row: i32,
    /// Fixed-point cost of entering this coordinate.
    pub enter_cost_units: u32,
    /// Fixed-point route cost through this coordinate.
    pub cumulative_cost_units: u32,
}

/// Persisted movement route retained between commands.
#[derive(Clone, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct QueuedMovePathDto {
    /// Final requested odd-q column.
    pub target_col: i32,
    /// Final requested odd-q row.
    pub target_row: i32,
    /// Steps in execution order, including the origin.
    pub steps: Vec<MovementStepDto>,
}
