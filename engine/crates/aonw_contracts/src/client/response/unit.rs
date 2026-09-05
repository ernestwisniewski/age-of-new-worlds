use serde::{Deserialize, Serialize};

use super::WorkerJobViewDto;
use crate::{
    ArmyTroopDto, CoordinateDto, MerchantTradeRouteDto, QueuedMovePathDto, UnitKindDto,
    UnitPostureDto,
};

/// Recipient-safe unit read model.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerUnitViewDto {
    /// Unit identifier.
    pub id: String,
    /// Visible owning player.
    pub owner_player_id: String,
    /// Stable unit kind.
    pub kind: UnitKindDto,
    /// Authored display name.
    pub name: String,
    /// Current map coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point movement balance.
    pub movement_units: u32,
    /// Persistent unit posture.
    pub posture: UnitPostureDto,
    /// Public combat health when the unit type uses explicit health.
    pub hit_points: Option<u32>,
    /// Authoritative maximum combat health in the unit's current progression state.
    pub maximum_hit_points: Option<u32>,
    /// Publicly visible carried artifact, when present.
    pub carried_artifact_id: Option<String>,
    /// Exact recipient-inspectable coordinates currently threatened by this unit.
    pub threatened_hexes: Vec<CoordinateDto>,
    /// Complete private command and progression state for a recipient-owned unit.
    pub owned_details: Option<OwnedUnitDetailsViewDto>,
}

/// Complete unit state disclosed only to the owning recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct OwnedUnitDetailsViewDto {
    /// Army composition in canonical troop order.
    pub army: Vec<ArmyTroopDto>,
    /// Persisted manual route, when one is queued.
    pub queued_path: Option<QueuedMovePathDto>,
    /// Persisted merchant route, when assigned.
    pub merchant_trade_route: Option<MerchantTradeRouteDto>,
    /// Current worker construction.
    pub worker_job: Option<WorkerJobViewDto>,
    /// Current city-founding work.
    pub city_founding_job: Option<CityFoundingJobViewDto>,
    /// Current worker assignment.
    pub worker_assignment: Option<CoordinateDto>,
    /// Artifact currently being excavated.
    pub excavating_artifact_id: Option<String>,
    /// Remaining improvement charges for workers.
    pub worker_build_charges: u32,
    /// Accumulated unit experience.
    pub experience_points: u32,
}

/// Recipient-owned city-founding activity retained by a settler.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityFoundingJobViewDto {
    /// Planned city center.
    pub center: CoordinateDto,
    /// Canonically ordered planned non-center territory.
    pub controlled_hexes: Vec<CoordinateDto>,
    /// Turns still required.
    pub remaining_turns: u32,
    /// Original activity duration.
    pub total_turns: u32,
}
