use serde::{Deserialize, Serialize};

/// One persisted simultaneous-combat declaration.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct IntendedAttackDto {
    pub attacker_unit_id: String,
    pub defender_col: i32,
    pub defender_row: i32,
    pub declared_at_tick: u64,
    pub declaring_player_id: String,
    pub city_conquest_action: CityConquestActionDto,
}

/// Requested disposition of a defeated city.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CityConquestActionDto {
    #[default]
    Capture,
    Destroy,
}
