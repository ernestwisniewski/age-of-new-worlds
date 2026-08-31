use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, MovementStepDto, TroopKindDto};

/// Exact movement performed inside one replayed turn processor.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayUnitMovementExecutionDto {
    /// Moved unit identity.
    pub unit_id: String,
    /// Position before execution.
    pub from: CoordinateDto,
    /// Exact executed steps excluding the origin.
    pub steps: Vec<MovementStepDto>,
}

/// Exact logistics execution stored in a replay result.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayLogisticsEvidenceDto {
    AutoExplore {
        unit_id: String,
        target: CoordinateDto,
        movement: Option<ReplayUnitMovementExecutionDto>,
    },
    MerchantRouteAssigned {
        unit_id: String,
        origin_city_id: String,
        destination_city_id: String,
        steps: Vec<MovementStepDto>,
        transport_network_fingerprint: String,
    },
    MerchantTravelQueued {
        unit_id: String,
        destination_city_id: String,
        steps: Vec<MovementStepDto>,
    },
    TroopDetached {
        source_unit_id: String,
        detached_unit_id: String,
        troop_kind: TroopKindDto,
        destination: CoordinateDto,
    },
}
