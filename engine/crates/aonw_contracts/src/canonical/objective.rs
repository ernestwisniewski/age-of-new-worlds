use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// One persisted controller and hold duration for a map objective.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MapObjectiveHoldStateDto {
    pub objective_id: String,
    pub player_id: String,
    pub hold_turns: i64,
}

/// Sparse per-player domination progress counters.
pub type DominationHoldTurnsDto = BTreeMap<String, i64>;

/// Sparse per-player cultural-victory progress counters.
pub type CulturalVictoryHoldTurnsDto = BTreeMap<String, i64>;
