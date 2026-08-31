use serde::{Deserialize, Serialize};

use super::{CoordinateDto, FieldImprovementKindDto};

#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct InteractionStateDto {
    pub city_founding_draft: Option<CityFoundingDraftDto>,
    pub pending: Option<PendingInteractionDto>,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityFoundingDraftDto {
    pub unit_id: String,
    pub owner_player_id: String,
    pub center: CoordinateDto,
    pub controlled_hexes: Vec<CoordinateDto>,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum PendingInteractionDto {
    ResearchSelection {
        owner_player_id: String,
    },
    CityWorkedHexSelection {
        owner_player_id: String,
        city_id: String,
    },
    CityExpansionSelection {
        owner_player_id: String,
        city_id: String,
    },
    WorkerActionSelection {
        owner_player_id: String,
        unit_id: String,
        improvement: Option<FieldImprovementKindDto>,
    },
    MerchantTradeRouteSelection {
        owner_player_id: String,
        unit_id: String,
    },
    MerchantMoveToCitySelection {
        owner_player_id: String,
        unit_id: String,
    },
    UnitTurnSkip {
        owner_player_id: String,
        unit_id: String,
        restore_movement_units: u32,
    },
    AttackTargeting {
        owner_player_id: String,
        unit_id: String,
        defender: Option<CoordinateDto>,
    },
    CommanderMergeSelection {
        owner_player_id: String,
        unit_id: String,
    },
}
