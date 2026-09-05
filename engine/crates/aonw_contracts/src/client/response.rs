use serde::{Deserialize, Serialize};

use crate::{
    CoordinateDto, GameOutcomeDto, PlayerCountryDto, PlayerKindDto, PlayerTurnStateDto, TurnModeDto,
};

mod artifact;
mod city;
mod diplomacy;
mod economy;
mod event;
mod logistics;
mod production;
mod query;
mod rejection;
mod research;
mod session;
mod unit;
mod victory;
mod worker;
pub use artifact::{PlayerArtifactLocationViewDto, PlayerArtifactViewDto};
pub use city::{
    CityExpansionCandidateDto, CityFoundingDraftViewDto, OwnedCityDetailsViewDto, PlayerCityViewDto,
};
pub use diplomacy::{
    PlayerDiplomacyViewDto, PlayerDiplomaticMessageViewDto, PlayerDiplomaticProposalViewDto,
    PlayerDiplomaticRelationViewDto, PlayerResourceTradeAgreementViewDto,
};
pub use economy::{
    CityYieldContributionDto, CityYieldContributionKindDto, EconomyForecastDto,
    GoldIncomeSourceDto, PlayerEconomyViewDto, StabilityBreakdownDto, StrategicResourceAmountDto,
    StrategicResourceSourceDto, UnitUpkeepBreakdownDto, UnitUpkeepSourceDto, YieldValueDto,
};
pub use event::ClientEventDto;
pub use logistics::{
    AutoExploreOptionDto, ClientLogisticsEvidenceDto, DetachmentOptionDto,
    MerchantDestinationOptionDto, MovementSearchMetricsDto, UnitMovementExecutionDto,
};
pub use production::{CitySpecializationOptionDto, ProductionOptionDto, UnitProductionOptionDto};
pub use query::{
    ClientEvidenceDto, ClientQueryResultDto, PendingActionViewDto, ReachableTileViewDto,
};
pub use rejection::ClientCommandRejectionCodeDto;
pub use research::{
    PlayerResearchViewDto, ResearchOptionDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, TechnologyAvailabilityDto, TechnologyUnlockDto,
};
pub use session::{ClientErrorDto, ClientReplayVerificationDto};
pub use unit::{CityFoundingJobViewDto, OwnedUnitDetailsViewDto, PlayerUnitViewDto};
pub use victory::{
    CulturalVictoryProgressDto, DominationVictoryProgressDto, MapObjectiveProgressDto,
    PlayerVictoryViewDto,
};
pub use worker::{
    FieldImprovementViewDto, RoadViewDto, WorkerAutomationActionDto, WorkerAutomationMetricsDto,
    WorkerAutomationOptionDto, WorkerImprovementOptionDto, WorkerJobCompletionDto,
    WorkerJobViewDto,
};

/// One current client protocol response.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientResponseDto {
    /// Client protocol version shared by independently packaged adapters.
    pub api_version: u16,
    /// Successful result or stable failure.
    pub outcome: ClientOutcomeDto,
}

/// Result envelope shared by Godot and Flutter adapters.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientOutcomeDto {
    /// Operation completed successfully.
    Success {
        /// Operation-specific result.
        response: Box<ClientResponseBodyDto>,
    },
    /// Operation failed without exposing canonical state.
    Failure {
        /// Stable machine code and diagnostic message.
        error: ClientErrorDto,
    },
}

/// Successful local client results.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientResponseBodyDto {
    /// Supported engine behavior and client operations.
    Capabilities {
        /// Supported current protocol features.
        features: Vec<ClientFeatureDto>,
    },
    /// A strict authored map was projected for presentation.
    MapInspected {
        /// Validated framework-neutral map view.
        map: super::MapViewDto,
    },
    /// A local session was opened.
    SessionOpened {
        /// Current authoritative identity.
        stamp: ClientSessionStampDto,
    },
    /// Recipient ownership was transferred inside a local hot-seat match.
    ActorHandedOff {
        /// Current authoritative identity after rebuilding recipient state.
        stamp: ClientSessionStampDto,
    },
    /// One bounded AI turn was executed through public runtime commands.
    AiTurnAdvanced {
        /// Current authoritative identity after AI execution.
        stamp: ClientSessionStampDto,
        /// Participant controlled by the AI driver.
        actor_player_id: String,
        /// Number of authoritative commands executed.
        executed_commands: u32,
        /// Whether the planner completed the participant turn.
        completed_turn: bool,
    },
    /// The local session was closed.
    SessionClosed,
    /// Complete recipient-safe snapshot.
    Snapshot {
        /// Snapshot payload.
        snapshot: PlayerViewSnapshotDto,
    },
    /// Query result.
    Query {
        /// Query-specific payload.
        result: ClientQueryResultDto,
    },
    /// Authoritative command result.
    Command {
        /// Command-specific payload.
        result: Box<ClientCommandResultDto>,
    },
    /// Current save document.
    SaveExported {
        /// Strict save JSON.
        document: String,
    },
    /// A save was opened transactionally.
    SaveOpened {
        /// Current authoritative identity.
        stamp: ClientSessionStampDto,
        /// Recipient restored from the canonical save header.
        actor_player_id: String,
        /// Ordered local participant controls required to resume orchestration.
        participants: Vec<ClientParticipantControlDto>,
    },
    /// Current replay document.
    ReplayExported {
        /// Strict replay JSON.
        document: String,
    },
    /// Replay verification completed.
    ReplayVerified {
        /// Verification summary.
        verification: ClientReplayVerificationDto,
    },
    /// One recipient-safe replay frame at an authoritative entry boundary.
    ReplayFrame {
        /// Number of replay entries applied in this frame.
        position: u64,
        /// Total number of entries in the verified replay archive.
        entry_count: u64,
        /// Recipient-safe snapshot at this exact entry boundary.
        snapshot: PlayerViewSnapshotDto,
    },
}

/// Minimal participant identity needed by a local client after save restore.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientParticipantControlDto {
    pub id: String,
    pub name: String,
    pub kind: PlayerKindDto,
}

/// Stable client-visible feature identifiers.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ClientFeatureDto {
    /// Artifact excavation, storage, trade, and recipient-safe projection.
    Artifacts,
    /// City founding, worked territory, expansion, and city projections.
    Cities,
    /// Combat preview and authoritative visible attacks.
    Combat,
    /// Stateless strict map inspection.
    InspectMap,
    /// Atomic participant, lifecycle, and fog initialization.
    MatchStart,
    /// Local hot-seat recipient handoff.
    ActorHandoff,
    /// Bounded AI turn execution through an injected planner.
    AiTurns,
    /// Complete player snapshot.
    Snapshot,
    /// Reachable movement overlay.
    Reachable,
    /// Route planning.
    RoutePlan,
    /// Manual movement command.
    MoveUnit,
    /// Cancel, skip, and fortify commands.
    UnitActions,
    /// Capability-gated `EndTurn` and `SubmitTurn` kernel commands.
    TurnKernel,
    /// Save export and restore.
    SaveGame,
    /// Replay export and verification.
    ReplayVerification,
    /// Recipient-safe replay open and random access playback.
    ReplayPlayback,
    /// Auto-exploration, merchant routing, and troop detachment.
    MovementLogistics,
    /// Worker improvements, assignments, roads, automation, and progression.
    Workers,
    /// City production queries and queue commands.
    Production,
    /// Research selection and complete technology options.
    Research,
    /// Bilateral friendship and truce proposal commands.
    Diplomacy,
}

/// Identity metadata returned with state-dependent results.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientSessionStampDto {
    /// Current canonical revision.
    pub revision: u64,
    /// Digest of the complete canonical state.
    pub state_digest: String,
    /// Hash of immutable canonical map content.
    pub map_hash: String,
    /// Hash of immutable ruleset content.
    pub ruleset_hash: String,
}

/// Public immutable participant identity available to every match recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerParticipantViewDto {
    /// Stable participant identifier.
    pub id: String,
    /// Persisted display name.
    pub name: String,
    /// Persisted ARGB display color.
    pub color_value: u32,
    /// Persisted country identity.
    pub country: PlayerCountryDto,
    /// Human or engine-controlled participant kind.
    pub kind: PlayerKindDto,
}

/// Recipient-safe fog state for map rendering.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerFogViewDto {
    /// Whether fog rules are enabled for this match.
    pub enabled: bool,
    /// Coordinates ever discovered by the recipient in canonical order.
    pub discovered_hexes: Vec<CoordinateDto>,
    /// Coordinates currently visible to the recipient in canonical order.
    pub visible_hexes: Vec<CoordinateDto>,
}

/// Complete recipient-safe player snapshot.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerViewSnapshotDto {
    /// Identity of the represented state.
    pub stamp: ClientSessionStampDto,
    /// Authoritative turn number.
    pub turn: u32,
    /// Authoritative participant turn resolution model.
    pub turn_mode: TurnModeDto,
    /// Immutable public participant identities in canonical turn order.
    pub participants: Vec<PlayerParticipantViewDto>,
    /// Complete recipient map visibility state.
    pub fog: PlayerFogViewDto,
    /// Recipient-owned economy accounts and strategic-resource flow.
    pub economy: PlayerEconomyViewDto,
    /// Recipient-owned research progress and science forecast.
    pub research: PlayerResearchViewDto,
    /// Recipient-safe victory pressure and live public scores.
    pub victory: PlayerVictoryViewDto,
    /// Persisted authoritative match result.
    pub outcome: GameOutcomeDto,
    /// Recipient-owned lifecycle status and aggregate submission progress.
    pub turn_lifecycle: PlayerTurnLifecycleViewDto,
    /// Action currently awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
    /// Recipient-owned city-founding workflow, when one is persisted.
    pub city_founding_draft: Option<CityFoundingDraftViewDto>,
    /// Bilateral diplomacy state in which this recipient participates.
    pub diplomacy: PlayerDiplomacyViewDto,
    /// Units currently visible to the recipient.
    pub units: Vec<PlayerUnitViewDto>,
    /// Cities currently known to the recipient.
    pub cities: Vec<PlayerCityViewDto>,
    /// Artifacts currently visible to the recipient.
    pub artifacts: Vec<PlayerArtifactViewDto>,
    /// Field improvements currently known to the recipient.
    pub field_improvements: Vec<FieldImprovementViewDto>,
    /// Roads currently known to the recipient.
    pub roads: Vec<RoadViewDto>,
}

/// Recipient-safe lifecycle projection with no per-opponent readiness map.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerTurnLifecycleViewDto {
    /// Current lifecycle status of the recipient.
    pub own_state: Option<PlayerTurnStateDto>,
    /// Whether the recipient already submitted this turn.
    pub own_submitted: bool,
    /// Number of participants required to submit.
    pub required_submission_count: u32,
    /// Number of required submissions received, without participant identities.
    pub submitted_count: u32,
}

/// Recipient-safe view update produced by one command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerViewPatchDto {
    /// Revision to which the patch applies.
    pub from_revision: u64,
    /// Revision represented after the patch.
    pub to_revision: u64,
    /// Authoritative turn number represented after the patch.
    pub turn: u32,
    /// Authoritative participant turn resolution model.
    pub turn_mode: TurnModeDto,
    /// Replacement recipient fog state when visibility changed.
    pub fog: Option<PlayerFogViewDto>,
    /// Replacement recipient economy state when any account or resource flow changed.
    pub economy: Option<PlayerEconomyViewDto>,
    /// Replacement recipient research state when progress or science changed.
    pub research: Option<PlayerResearchViewDto>,
    /// Replacement victory pressure and live scores when they changed.
    pub victory: Option<PlayerVictoryViewDto>,
    /// Replacement lifecycle projection when turn/readiness changed.
    pub turn_lifecycle: Option<PlayerTurnLifecycleViewDto>,
    /// Replacement match result when it changed.
    pub outcome: Option<GameOutcomeDto>,
    /// New or changed visible units.
    pub upserted_units: Vec<PlayerUnitViewDto>,
    /// Units no longer visible.
    pub removed_unit_ids: Vec<String>,
    /// New or changed recipient-safe cities.
    pub upserted_cities: Vec<PlayerCityViewDto>,
    /// Cities no longer known to the recipient.
    pub removed_city_ids: Vec<String>,
    /// New or changed visible artifacts.
    pub upserted_artifacts: Vec<PlayerArtifactViewDto>,
    /// Artifacts no longer visible to the recipient.
    pub removed_artifact_ids: Vec<String>,
    /// New or changed known field improvements.
    pub upserted_field_improvements: Vec<FieldImprovementViewDto>,
    /// Field-improvement coordinates no longer known.
    pub removed_field_improvement_coordinates: Vec<CoordinateDto>,
    /// New or changed known roads.
    pub upserted_roads: Vec<RoadViewDto>,
    /// Road coordinates no longer known.
    pub removed_road_coordinates: Vec<CoordinateDto>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
    /// Current recipient-owned founding workflow; null clears it.
    pub city_founding_draft: Option<CityFoundingDraftViewDto>,
    /// Replacement bilateral diplomacy view when any visible record changed.
    pub diplomacy: Option<PlayerDiplomacyViewDto>,
}

/// Result of one authoritative command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientCommandResultDto {
    /// Identity of the resulting canonical state.
    pub stamp: ClientSessionStampDto,
    /// Accepted or rejected authoritative outcome.
    pub outcome: ClientCommandOutcomeDto,
    /// Ordered presentation-safe domain events.
    pub events: Vec<ClientEventDto>,
    /// Exact execution evidence when produced.
    pub evidence: Option<ClientEvidenceDto>,
    /// Recipient-safe state delta.
    pub view_patch: PlayerViewPatchDto,
}

/// Coherent authoritative command outcome.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientCommandOutcomeDto {
    /// The command was accepted.
    Accepted,
    /// The command was rejected without changing canonical state.
    Rejected {
        /// Stable language-neutral rejection code.
        code: ClientCommandRejectionCodeDto,
    },
}

/// One movement step exposed by a query or command result.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MovementStepViewDto {
    /// Step coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point entry cost.
    pub enter_cost_units: u32,
    /// Fixed-point cumulative cost.
    pub cumulative_cost_units: u32,
}
