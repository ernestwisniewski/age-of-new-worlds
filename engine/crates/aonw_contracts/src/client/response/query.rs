use serde::{Deserialize, Serialize};

use crate::{
    CityProductionTargetDto, CombatExecutionDto, CombatPreviewDto, CoordinateDto,
    FieldImprovementKindDto, TechnologyIdDto,
};

use super::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CitySpecializationOptionDto,
    CityYieldContributionDto, ClientLogisticsEvidenceDto, ClientSessionStampDto,
    DetachmentOptionDto, MerchantDestinationOptionDto, MovementStepViewDto, ProductionOptionDto,
    StrategicResourceAmountDto, StrategicResourceSourceDto, UnitMovementExecutionDto,
    UnitProductionOptionDto, WorkerAutomationOptionDto, WorkerImprovementOptionDto, YieldValueDto,
};
use super::{ResearchOptionDto, ScienceYieldBreakdownDto};

/// Recipient-owned action awaiting player input.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum PendingActionViewDto {
    ResearchSelection,
    CityWorkedHexSelection {
        city_id: String,
    },
    CityExpansionSelection {
        city_id: String,
    },
    WorkerActionSelection {
        unit_id: String,
        improvement: Option<FieldImprovementKindDto>,
    },
    MerchantTradeRouteSelection {
        unit_id: String,
    },
    MerchantMoveToCitySelection {
        unit_id: String,
    },
    UnitTurnSkip {
        unit_id: String,
        restore_movement_units: u32,
    },
    AttackTargeting {
        unit_id: String,
        defender: Option<CoordinateDto>,
    },
    CommanderMergeSelection {
        unit_id: String,
    },
}

/// Exact client-visible execution evidence.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientEvidenceDto {
    /// Exact combat seed, rolls, modifiers and result.
    Combat {
        /// Exact combat execution.
        execution: CombatExecutionDto,
    },
    /// Exact executed movement prefix.
    UnitMovement {
        /// Moved unit.
        unit_id: String,
        /// Position before execution.
        from: CoordinateDto,
        /// Executed steps excluding the origin.
        steps: Vec<MovementStepViewDto>,
    },
    /// Exact auto-exploration, merchant, or detachment execution.
    Logistics {
        /// Typed logistics execution.
        execution: ClientLogisticsEvidenceDto,
    },
    /// Exact worker automation target, counters, and movement.
    WorkerAutomation {
        /// Worker receiving the automation command.
        unit_id: String,
        /// Engine-selected action.
        option: WorkerAutomationOptionDto,
        /// Executed movement prefix when the target was remote.
        movement: Option<UnitMovementExecutionDto>,
    },
    /// Exact capability-gated turn processors executed.
    TurnKernel {
        /// Processors executed in canonical order.
        processors: Vec<String>,
        /// Cities founded during the pipeline and visible to the recipient.
        founded_city_ids: Vec<String>,
        /// Exact intended-attack resolutions in execution order.
        combat_executions: Vec<CombatExecutionDto>,
        /// Units whose movement allowance was reset.
        reset_unit_ids: Vec<String>,
        /// Exact movements performed by queued, merchant, and auto processors.
        movement_executions: Vec<UnitMovementExecutionDto>,
        /// Units whose stored movement order became invalid.
        invalidated_order_unit_ids: Vec<String>,
        /// Scouts whose auto-exploration ended without another target.
        finished_auto_explore_unit_ids: Vec<String>,
    },
}

/// Recipient-safe query result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientQueryResultDto {
    /// Complete engine-owned research selection choices.
    ResearchOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Authenticated owner of this private view.
        player_id: String,
        /// Current research target.
        active_technology_id: Option<TechnologyIdDto>,
        /// Stored science available to the next selection.
        science_overflow: i64,
        /// Engine-owned current per-turn science preview.
        science_yield: ScienceYieldBreakdownDto,
        /// Complete technology catalog in canonical order.
        options: Vec<ResearchOptionDto>,
    },
    /// Legal initial territory choices for one founder.
    CityFoundingOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried founder.
        founder_unit_id: String,
        /// Immutable prospective center.
        center: CoordinateDto,
        /// Canonically ordered current draft selection.
        selected_controlled_hexes: Vec<CoordinateDto>,
        /// Legal next selections owned by the engine.
        available_controlled_hexes: Vec<CoordinateDto>,
        /// Required exact non-center territory count.
        required_controlled_hexes: u32,
        /// Maximum founding radius.
        maximum_radius: u32,
    },
    /// Controlled, manual, and effective worked-city coordinates.
    CityWorkedHexOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried city.
        city_id: String,
        /// City center.
        center: CoordinateDto,
        /// Canonically ordered non-center territory.
        controlled_hexes: Vec<CoordinateDto>,
        /// Coordinates accepted by the toggle command.
        available_hexes: Vec<CoordinateDto>,
        /// Canonically ordered manual selection.
        selected_hexes: Vec<CoordinateDto>,
        /// Manual selection plus deterministic automatic fill.
        effective_hexes: Vec<CoordinateDto>,
        /// Population-based worked-hex limit.
        limit: u32,
    },
    /// Engine-ranked preferred-expansion choices.
    CityExpansionOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried city.
        city_id: String,
        /// Canonically ordered non-center territory.
        controlled_hexes: Vec<CoordinateDto>,
        /// Persisted preferred coordinate.
        preferred_hex: Option<CoordinateDto>,
        /// Current deterministic candidate ranking.
        candidates: Vec<CityExpansionCandidateDto>,
    },
    /// Display-ready checked city yield.
    CityYield {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried city.
        city_id: String,
        /// Ordered exact contributions.
        contributions: Vec<CityYieldContributionDto>,
        /// Checked aggregate.
        total: YieldValueDto,
    },
    /// Technology-gated strategic resource output owned by the recipient.
    StrategicResourceProjection {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Recipient account.
        player_id: String,
        /// Positive output in canonical resource order.
        output: Vec<StrategicResourceAmountDto>,
        /// Exact controlled extraction sources.
        sources: Vec<StrategicResourceSourceDto>,
    },
    /// Complete engine-owned city-production choices.
    ProductionOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried city.
        city_id: String,
        /// Active target, when present.
        current_target: Option<CityProductionTargetDto>,
        /// Production already invested in the active target.
        invested_production: i64,
        /// Stored overflow available to the next target.
        production_overflow: i64,
        /// Complete building catalog in canonical order.
        buildings: Vec<ProductionOptionDto>,
        /// Complete unit catalog in canonical order.
        units: Vec<UnitProductionOptionDto>,
        /// Repeatable city projects.
        projects: Vec<ProductionOptionDto>,
        /// Complete wonder catalog in canonical order.
        wonders: Vec<ProductionOptionDto>,
        /// City specializations and blockers.
        specializations: Vec<CitySpecializationOptionDto>,
    },
    /// Recipient-safe combat preview.
    CombatPreview {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Engine-owned preview.
        preview: CombatPreviewDto,
    },
    /// Current-turn reachable overlay.
    Reachable {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried unit.
        unit_id: String,
        /// Movement available at query time.
        available_movement_units: u32,
        /// Stable row-major reachable tiles.
        tiles: Vec<ReachableTileViewDto>,
    },
    /// Deterministic route preview.
    RoutePlan {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried unit.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
        /// Planned destination.
        destination: CoordinateDto,
        /// Fixed-point total route cost.
        total_cost_units: u32,
        /// Movement available at query time.
        available_movement_units: u32,
        /// Movement remaining after the executable prefix.
        remaining_movement_units: u32,
        /// Ordered route including the origin.
        steps: Vec<MovementStepViewDto>,
    },
    /// Complete engine-owned logistics options.
    UnitLogisticsOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried unit.
        unit_id: String,
        /// Selected auto-exploration action, when legal.
        auto_explore: Option<AutoExploreOptionDto>,
        /// Valid cyclic merchant-route destinations.
        merchant_route_destinations: Vec<MerchantDestinationOptionDto>,
        /// Valid explicit merchant-travel destinations.
        merchant_travel_destinations: Vec<MerchantDestinationOptionDto>,
        /// Exact legal troop-detachment actions.
        detachments: Vec<DetachmentOptionDto>,
    },
    /// Complete legal worker options.
    WorkerOptions {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried worker.
        unit_id: String,
        /// Current coordinate.
        coordinate: CoordinateDto,
        /// Currently legal improvements.
        improvements: Vec<WorkerImprovementOptionDto>,
        /// Whether the current improvement can be assigned.
        can_assign: bool,
        /// Whether road construction can start here.
        can_build_road: bool,
        /// Deterministic automation action, when one exists.
        automation: Option<WorkerAutomationOptionDto>,
    },
}

/// One current-turn reachable map tile.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReachableTileViewDto {
    /// Tile coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point route cost.
    pub cost_units: u32,
    /// Whether entry consumes remaining current-turn movement.
    pub exhausts_movement: bool,
}
