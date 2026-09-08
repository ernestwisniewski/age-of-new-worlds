use crate::CoordinateDto;
use serde::{Deserialize, Serialize};

/// An engine-selected focus target in the actor's turn work list.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum PendingTurnActionDto {
    Unit {
        unit_id: String,
        coordinate: CoordinateDto,
    },
    CityProduction {
        city_id: String,
        coordinate: CoordinateDto,
    },
    Research {},
}
