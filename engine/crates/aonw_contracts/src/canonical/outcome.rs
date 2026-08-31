use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// Stable condition of the persisted authoritative match result.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum GameOutcomeConditionDto {
    Ongoing,
    Conquest,
    Domination,
    Cultural,
    Score,
    Resignation,
    Draw,
}

/// Complete persisted authoritative match result.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct GameOutcomeDto {
    pub condition: GameOutcomeConditionDto,
    pub winner_player_id: Option<String>,
    pub score_by_player_id: BTreeMap<String, i64>,
}
