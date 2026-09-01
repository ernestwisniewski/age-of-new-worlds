use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, CityProductionQueueDto, CitySpecializationTypeDto, CoordinateDto,
    WonderTypeDto,
};

use super::YieldValueDto;

/// Recipient-owned city-founding selection restored through save/reopen.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityFoundingDraftViewDto {
    /// Founder owning this workflow.
    pub founder_unit_id: String,
    /// Immutable prospective city center.
    pub center: CoordinateDto,
    /// Canonically ordered selected non-center coordinates.
    pub controlled_hexes: Vec<CoordinateDto>,
}

/// Recipient-safe city read model.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerCityViewDto {
    /// City identifier.
    pub id: String,
    /// Visible owning player.
    pub owner_player_id: String,
    /// Public city name.
    pub name: String,
    /// Public city center.
    pub center: CoordinateDto,
    /// Controlled coordinates already discovered by this recipient.
    pub visible_controlled_hexes: Vec<CoordinateDto>,
    /// Public combat health when the city participates in combat.
    pub hit_points: Option<i64>,
    /// Complete private state, present only for an owned city.
    pub owned_details: Option<OwnedCityDetailsViewDto>,
}

/// Complete city state visible only to the owning recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct OwnedCityDetailsViewDto {
    /// Current population used by worked-hex rules.
    pub population: i64,
    /// Food retained toward the next population change.
    pub stored_food: i64,
    /// Current territory capacity.
    pub max_hexes: i64,
    /// Current expansion radius.
    pub territory_radius: i64,
    /// Canonically ordered manual worked coordinates.
    pub worked_hexes: Vec<CoordinateDto>,
    /// Constructed buildings in stable identity order.
    pub buildings: Vec<CityBuildingTypeDto>,
    /// Constructed wonders in stable identity order.
    pub wonders: Vec<WonderTypeDto>,
    /// Current production investment and reserved resources.
    pub production_queue: Option<CityProductionQueueDto>,
    /// Production retained beyond the previous completion.
    pub production_overflow: i64,
    /// Current city specialization.
    pub specialization: Option<CitySpecializationTypeDto>,
    /// Preferred expansion coordinate, when selected.
    pub preferred_expansion_hex: Option<CoordinateDto>,
}

/// One engine-ranked city expansion candidate.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityExpansionCandidateDto {
    /// Candidate coordinate.
    pub coordinate: CoordinateDto,
    /// Standard yield score.
    pub score: i32,
    /// Exact hex distance from the center.
    pub distance: u32,
    /// Display-ready base yield of the candidate tile.
    pub tile_yield: YieldValueDto,
}
