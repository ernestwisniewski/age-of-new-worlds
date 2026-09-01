use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// Public territorial victory pressure for one active participant.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DominationVictoryProgressDto {
    /// Stable participant identifier.
    pub player_id: String,
    /// Exact controlled-territory numerator.
    pub controlled_passable_hexes: u32,
    /// Exact passable-map denominator.
    pub total_passable_hexes: u32,
    /// Consecutive turns above the threshold.
    pub hold_turns: u32,
}

/// Recipient-owned cultural victory pressure.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CulturalVictoryProgressDto {
    /// Distinct artifact types stored in recipient-owned cities.
    pub unique_stored_artifacts: u32,
    /// Consecutive turns above the cultural threshold.
    pub hold_turns: u32,
}

/// Disclosure-filtered progress for one authored map objective.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MapObjectiveProgressDto {
    /// Stable authored objective identifier.
    pub objective_id: String,
    /// Controller disclosed to the recipient, when permitted.
    pub controller_player_id: Option<String>,
    /// Disclosed controller's consecutive hold count.
    pub hold_turns: u32,
}

/// Complete recipient-safe victory rules, live scores, and progress.
#[allow(clippy::struct_excessive_bools)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerVictoryViewDto {
    /// Whether conquest victory is enabled.
    pub conquest_enabled: bool,
    /// Whether domination victory is enabled.
    pub domination_enabled: bool,
    /// Exact configured domination percentage.
    pub domination_required_control_percent: serde_json::Number,
    /// Consecutive domination turns required.
    pub domination_required_hold_turns: u32,
    /// Whether cultural victory is enabled.
    pub cultural_enabled: bool,
    /// Distinct stored artifacts required.
    pub cultural_required_artifacts: u32,
    /// Consecutive cultural turns required.
    pub cultural_required_hold_turns: u32,
    /// Whether the turn limit falls back to score.
    pub score_fallback_enabled: bool,
    /// Optional score turn limit.
    pub turn_limit: Option<u32>,
    /// Remaining turns before score resolution.
    pub remaining_turns: Option<u32>,
    /// Live public empire scores in participant-ID order.
    pub score_by_player_id: BTreeMap<String, i64>,
    /// Public domination pressure in participant-ID order.
    pub domination: Vec<DominationVictoryProgressDto>,
    /// Cultural pressure visible only to the recipient.
    pub own_cultural: CulturalVictoryProgressDto,
    /// Authored objective progress in objective-ID order.
    pub map_objectives: Vec<MapObjectiveProgressDto>,
}
