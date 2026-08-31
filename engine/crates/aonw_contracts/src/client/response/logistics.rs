use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, TroopKindDto};

use super::MovementStepViewDto;

/// Deterministic work performed while selecting an auto-exploration target.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MovementSearchMetricsDto {
    /// Entries removed from the route-search frontier.
    pub frontier_pops: u64,
    /// Tiles whose outgoing edges were inspected.
    pub expanded_tiles: u64,
    /// Neighbor edges inspected by the search.
    pub examined_edges: u64,
    /// Entries inserted into the route-search frontier.
    pub heap_pushes: u64,
    /// Route records retained by the search.
    pub route_records: u64,
}

/// Engine-selected auto-exploration action.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct AutoExploreOptionDto {
    /// Selected exploration target.
    pub target: CoordinateDto,
    /// Complete fixed-point route cost.
    pub total_cost_units: u32,
    /// Bounded search evidence.
    pub search_metrics: MovementSearchMetricsDto,
}

/// One owned city accepted by merchant pathing rules.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MerchantDestinationOptionDto {
    /// Destination city identity.
    pub city_id: String,
    /// Complete fixed-point route cost.
    pub total_cost_units: u32,
}

/// One troop and deterministic destination accepted for detachment.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DetachmentOptionDto {
    /// Troop kind that can be detached.
    pub troop_kind: TroopKindDto,
    /// Engine-selected adjacent destination.
    pub destination: CoordinateDto,
}

/// Exact movement performed inside a larger logistics or turn transition.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitMovementExecutionDto {
    /// Moved unit identity.
    pub unit_id: String,
    /// Position before execution.
    pub from: CoordinateDto,
    /// Exact executed steps excluding the origin.
    pub steps: Vec<MovementStepViewDto>,
}

/// Exact execution evidence for one accepted logistics command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientLogisticsEvidenceDto {
    AutoExplore {
        unit_id: String,
        target: CoordinateDto,
        movement: Option<UnitMovementExecutionDto>,
    },
    MerchantRouteAssigned {
        unit_id: String,
        origin_city_id: String,
        destination_city_id: String,
        steps: Vec<MovementStepViewDto>,
        transport_network_fingerprint: String,
    },
    MerchantTravelQueued {
        unit_id: String,
        destination_city_id: String,
        steps: Vec<MovementStepViewDto>,
    },
    TroopDetached {
        source_unit_id: String,
        detached_unit_id: String,
        troop_kind: TroopKindDto,
        destination: CoordinateDto,
    },
}
