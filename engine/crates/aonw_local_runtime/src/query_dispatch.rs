use aonw_domain::{CityId, HexCoord, MovementUnits, TroopKind, UnitId};
use aonw_engine::{
    CityExpansionOptions, CityFoundingOptions, CityWorkedHexOptions, CityYieldBreakdown,
    CombatPreview, GameEngine, GameQuery, MovementSearchMetrics, MovementSearchWorkspace,
    ProductionOptions, QueryResult, ReachableMovementQuery, ResearchOptions, ResearchOptionsQuery,
    StrategicResourceProjection, TerrainMovementQuery, WorkerOptions,
};

mod city;
use city::{
    dispatch_city_expansion_query, dispatch_city_founding_query, dispatch_city_worked_query,
};
mod city_planning;
pub use city_planning::CityPlanningRequest;
mod pending_turn_actions;
pub use pending_turn_actions::PendingTurnActionsRequest;
mod hex_inspection;
pub use hex_inspection::HexInspectionRequest;
use hex_inspection::dispatch_hex_inspection;
mod logistics;
mod movement;
mod production;
mod read_models;
pub use production::ProductionDetailsRequest;
mod worker;

use logistics::dispatch_logistics_query;
pub use movement::{MovementStepView, ReachableResult, ReachableTileView, RoutePlanResult};
pub use read_models::{
    CityYieldRequest, CombatPreviewRequest, ProductionOptionsRequest,
    StrategicResourceProjectionRequest,
};
use read_models::{
    dispatch_city_yield_query, dispatch_combat_preview_query, dispatch_production_options_query,
    dispatch_strategic_resource_query,
};
use worker::dispatch_worker_query;

/// Current city-founding-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled founder.
    pub founder_unit_id: UnitId,
}

/// Current city-worked-hex-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityWorkedHexOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
}

/// Current city-expansion-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityExpansionOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
}

/// Current engine-owned worker-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkerOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled worker.
    pub unit_id: UnitId,
}

/// Current actor-owned research-options request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ResearchOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

use crate::session::Session;
use crate::{RuntimeError, SessionStamp};

/// Current reachable-overlay request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
}

/// Current route-preview request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoutePlanRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Current engine-owned logistics-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitLogisticsOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
}

/// Versioned local query family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeQuery {
    /// Discovered city-site and growth markings.
    CityPlanning(CityPlanningRequest),
    /// Ordered actor-owned manual turn work.
    PendingTurnActions(PendingTurnActionsRequest),
    /// Disclosed profile of one map hex.
    HexInspection(HexInspectionRequest),
    /// Complete actor-owned research selection choices.
    ResearchOptions(ResearchOptionsRequest),
    /// Legal initial territory choices.
    CityFoundingOptions(CityFoundingOptionsRequest),
    /// Controlled/manual/effective worked coordinates.
    CityWorkedHexOptions(CityWorkedHexOptionsRequest),
    /// Ranked current territory-expansion candidates.
    CityExpansionOptions(CityExpansionOptionsRequest),
    /// Checked tile-level city yield.
    CityYield(CityYieldRequest),
    /// Technology-gated actor-owned extraction projection.
    StrategicResourceProjection(StrategicResourceProjectionRequest),
    /// Complete city-production options and blockers.
    ProductionOptions(ProductionOptionsRequest),
    /// Effects of a selected production target.
    ProductionDetails(ProductionDetailsRequest),
    /// Authoritative building priorities.
    ProductionBuildingRanks(ProductionOptionsRequest),
    /// Improvement, assignment, road, and automation options.
    WorkerOptions(WorkerOptionsRequest),
    /// Effective combat stats and damage bounds without RNG evidence.
    CombatPreview(CombatPreviewRequest),
    /// Current-turn reachable overlay.
    Reachable(ReachableRequest),
    /// Deterministic complete route preview.
    RoutePlan(RoutePlanRequest),
    /// Auto-exploration, merchant, and detachment options.
    UnitLogisticsOptions(UnitLogisticsOptionsRequest),
}

/// Engine-selected auto-exploration action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AutoExploreOptionView {
    /// Selected target.
    pub target: HexCoord,
    /// Complete route cost.
    pub total_cost: MovementUnits,
    /// Bounded route-search evidence.
    pub search_metrics: MovementSearchMetrics,
}

/// One owned merchant destination accepted by engine rules.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantDestinationView {
    /// Destination city.
    pub city_id: CityId,
    /// Complete route cost.
    pub total_cost: MovementUnits,
}

/// One exact legal troop-detachment action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DetachmentOptionView {
    /// Troop kind to detach.
    pub troop_kind: TroopKind,
    /// Engine-selected adjacent destination.
    pub destination: HexCoord,
}

/// Complete engine-owned logistics options for one unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitLogisticsOptionsResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Queried unit.
    pub unit_id: UnitId,
    /// Selected auto-exploration action, when legal.
    pub auto_explore: Option<AutoExploreOptionView>,
    /// Valid cyclic-route destinations.
    pub merchant_route_destinations: Box<[MerchantDestinationView]>,
    /// Valid explicit-travel destinations.
    pub merchant_travel_destinations: Box<[MerchantDestinationView]>,
    /// Exact legal detachments.
    pub detachments: Box<[DetachmentOptionView]>,
}

/// Versioned local query response family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeQueryResult {
    /// Disclosed planning candidates.
    CityPlanning {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned city-site and growth markings.
        planning: aonw_engine::CityPlanning,
    },
    /// Ordered actor-owned manual turn work.
    PendingTurnActions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned targets and lifecycle availability.
        actions: aonw_engine::PendingTurnActions,
    },
    /// Disclosed profile of one map hex.
    HexInspection {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Actor-filtered query result.
        inspection: aonw_engine::HexInspection,
    },
    /// Complete actor-owned research selection choices.
    ResearchOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: ResearchOptions,
    },
    /// Legal city-founding choices.
    CityFoundingOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: CityFoundingOptions,
    },
    /// Worked-city coordinates.
    CityWorkedHexOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: CityWorkedHexOptions,
    },
    /// Ranked expansion candidates.
    CityExpansionOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: CityExpansionOptions,
    },
    /// Engine-owned city yield.
    CityYield {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        breakdown: CityYieldBreakdown,
    },
    /// Engine-owned strategic resource projection.
    StrategicResourceProjection {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        projection: StrategicResourceProjection,
    },
    /// Engine-owned city-production options.
    ProductionOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: ProductionOptions,
    },
    /// Engine-owned selected target details.
    ProductionDetails {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Selected target effects, kept indirect to bound every cache entry.
        details: Box<aonw_engine::ProductionDetails>,
    },
    /// Engine-owned building priorities.
    ProductionBuildingRanks {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Complete building priorities.
        ranks: aonw_engine::ProductionBuildingRanks,
    },
    /// Engine-owned worker options.
    WorkerOptions {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned query result.
        options: WorkerOptions,
    },
    /// Recipient-safe combat preview.
    CombatPreview {
        /// Version and authoritative identity metadata.
        stamp: SessionStamp,
        /// Engine-owned preview.
        preview: CombatPreview,
    },
    /// Reachable overlay.
    Reachable(ReachableResult),
    /// Route preview.
    RoutePlan(RoutePlanResult),
    /// Engine-owned logistics options.
    UnitLogisticsOptions(UnitLogisticsOptionsResult),
}

pub(crate) fn dispatch_query(
    session: &Session,
    request: RuntimeQuery,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    match request {
        RuntimeQuery::CityPlanning(request) => city_planning::dispatch(session, request, workspace),
        RuntimeQuery::PendingTurnActions(request) => {
            pending_turn_actions::dispatch(session, request, workspace)
        }
        RuntimeQuery::HexInspection(request) => {
            dispatch_hex_inspection(session, request, workspace)
        }
        RuntimeQuery::ResearchOptions(request) => {
            dispatch_research_query(session, request, workspace)
        }
        RuntimeQuery::CityFoundingOptions(request) => {
            dispatch_city_founding_query(session, &request, workspace)
        }
        RuntimeQuery::CityWorkedHexOptions(request) => {
            dispatch_city_worked_query(session, &request, workspace)
        }
        RuntimeQuery::CityExpansionOptions(request) => {
            dispatch_city_expansion_query(session, &request, workspace)
        }
        RuntimeQuery::CityYield(request) => dispatch_city_yield_query(session, &request, workspace),
        RuntimeQuery::StrategicResourceProjection(request) => {
            dispatch_strategic_resource_query(session, request, workspace)
        }
        RuntimeQuery::ProductionOptions(request) => {
            dispatch_production_options_query(session, &request, workspace)
        }
        RuntimeQuery::ProductionDetails(request) => {
            production::dispatch_details(session, &request, workspace)
        }
        RuntimeQuery::ProductionBuildingRanks(request) => {
            production::dispatch_ranks(session, &request, workspace)
        }
        RuntimeQuery::WorkerOptions(request) => dispatch_worker_query(session, &request, workspace),
        RuntimeQuery::CombatPreview(request) => {
            dispatch_combat_preview_query(session, &request, workspace)
        }
        RuntimeQuery::Reachable(request) => dispatch_reachable(session, &request, workspace),
        RuntimeQuery::RoutePlan(request) => {
            let result = GameEngine::query_with_workspace(
                session.state(),
                session.context(),
                GameQuery::PlanRoute(TerrainMovementQuery::new(
                    request.expected_revision,
                    &request.unit_id,
                    request.target,
                )),
                workspace,
            )
            .map_err(RuntimeError::Query)?;
            let QueryResult::Route(result) = result else {
                unreachable!("route query returns route response")
            };
            Ok(RuntimeQueryResult::RoutePlan(RoutePlanResult {
                stamp: session.stamp(),
                unit_id: result.unit_id().clone(),
                target: result.target(),
                destination: result.destination(),
                total_cost: result.total_cost(),
                available_movement: result.available_movement(),
                remaining_movement: result.remaining_movement(),
                estimated_turns: result.estimated_turns(),
                step_turns: result.step_turns().collect(),
                road_step_indices: result.road_step_indices().collect(),
                steps: result
                    .steps()
                    .iter()
                    .map(|step| MovementStepView {
                        coordinate: step.coordinate(),
                        enter_cost: step.enter_cost(),
                        cumulative_cost: step.cumulative_cost(),
                    })
                    .collect(),
            }))
        }
        RuntimeQuery::UnitLogisticsOptions(request) => {
            dispatch_logistics_query(session, &request, workspace)
        }
    }
}

fn dispatch_research_query(
    session: &Session,
    request: ResearchOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::ResearchOptions(ResearchOptionsQuery::new(request.expected_revision)),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::ResearchOptions(options) = result else {
        unreachable!("research query returns research options")
    };
    Ok(RuntimeQueryResult::ResearchOptions {
        stamp: session.stamp(),
        options,
    })
}

fn dispatch_reachable(
    session: &Session,
    request: &ReachableRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::Reachable(ReachableMovementQuery::new(
            request.expected_revision,
            &request.unit_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::Reachable(result) = result else {
        unreachable!("reachable query returns reachable response")
    };
    Ok(RuntimeQueryResult::Reachable(ReachableResult {
        stamp: session.stamp(),
        unit_id: result.unit_id().clone(),
        available_movement: result.available_movement(),
        can_start_targeting: result.can_start_targeting(),
        can_retain_targeting: result.can_retain_targeting(),
        tiles: result
            .tiles()
            .iter()
            .map(|tile| ReachableTileView {
                coordinate: tile.coordinate(),
                cost: tile.cost(),
                exhausts_movement: tile.exhausts_movement(),
            })
            .collect(),
    }))
}
