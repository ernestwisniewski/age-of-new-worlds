use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// Identity and rule configuration retained for the whole match.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MatchIdentityDto {
    pub match_rules: MatchRulesDto,
    pub participants: Vec<ParticipantDto>,
    pub game_mode: GameModeDto,
    /// Explicit turn resolution model. Omission is accepted only for documents
    /// produced before turn mode became independent from session mode.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub turn_mode: Option<TurnModeDto>,
}

impl Default for MatchIdentityDto {
    fn default() -> Self {
        Self {
            match_rules: MatchRulesDto::default(),
            participants: Vec::new(),
            game_mode: GameModeDto::HotSeat,
            turn_mode: Some(TurnModeDto::Sequential),
        }
    }
}

/// Per-turn lifecycle state keyed by participant identity.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TurnLifecycleDto {
    pub turn_states_by_player_id: BTreeMap<String, PlayerTurnStateDto>,
    pub required_submission_player_ids: Vec<String>,
    pub submitted_player_ids: Vec<String>,
    pub timeout_streaks_by_player_id: BTreeMap<String, i64>,
    pub afk_player_ids: Vec<String>,
    pub kicked_player_ids: Vec<String>,
    pub turn_started_at: Option<String>,
}

/// Immutable match rules shared across engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MatchRulesDto {
    pub game_length: GameLengthConfigDto,
    pub victory: VictoryRulesDto,
    pub balance: BTreeMap<String, RuleValueDto>,
}

/// Match duration and pace selection.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct GameLengthConfigDto {
    pub kind: GameLengthKindDto,
    pub target_minutes: Option<u32>,
    pub turn_limit: Option<u32>,
    pub pace_profile: PaceProfileDto,
    pub score_fallback_enabled: bool,
}

impl Default for GameLengthConfigDto {
    fn default() -> Self {
        Self {
            kind: GameLengthKindDto::Unlimited,
            target_minutes: None,
            turn_limit: None,
            pace_profile: PaceProfileDto::Unlimited,
            score_fallback_enabled: false,
        }
    }
}

/// Victory switches and thresholds.
#[allow(clippy::struct_excessive_bools, missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct VictoryRulesDto {
    pub conquest_enabled: bool,
    pub domination_enabled: bool,
    pub domination_control_percent: serde_json::Number,
    pub domination_hold_turns: u32,
    pub score_fallback_enabled: bool,
    pub turn_limit: Option<u32>,
    pub hard_time_limit_minutes: Option<u32>,
    pub cultural_enabled: bool,
    pub cultural_required_artifacts: u32,
    pub cultural_hold_turns: u32,
}

impl Default for VictoryRulesDto {
    fn default() -> Self {
        Self {
            conquest_enabled: true,
            domination_enabled: true,
            domination_control_percent: serde_json::Number::from(60),
            domination_hold_turns: 5,
            score_fallback_enabled: false,
            turn_limit: None,
            hard_time_limit_minutes: None,
            cultural_enabled: true,
            cultural_required_artifacts: 6,
            cultural_hold_turns: 5,
        }
    }
}

/// Typed recursive value used by the open-ended current balance object.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(untagged)]
pub enum RuleValueDto {
    Null,
    Bool(bool),
    Number(serde_json::Number),
    String(String),
    Array(Vec<RuleValueDto>),
    Object(BTreeMap<String, RuleValueDto>),
}

/// Ordered player entry, including persisted display identity, retained by canonical state.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ParticipantDto {
    pub id: String,
    pub name: String,
    pub color_value: u32,
    pub country: PlayerCountryDto,
    pub kind: PlayerKindDto,
    pub ai: Option<AiPlayerDto>,
}

/// Deterministic AI identity persisted with an AI participant.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct AiPlayerDto {
    pub strategy_id: AiStrategyIdDto,
    pub difficulty: AiDifficultyDto,
    pub persona: AiPersonaDto,
    pub seed: i64,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum GameLengthKindDto {
    Unlimited,
    TargetMinutes,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum PaceProfileDto {
    Unlimited,
    Standard60,
    Normal90,
    Long120,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum GameModeDto {
    HotSeat,
    Multiplayer,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TurnModeDto {
    Sequential,
    Simultaneous,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum PlayerTurnStateDto {
    Active,
    Finished,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum PlayerKindDto {
    Human,
    Ai,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum PlayerCountryDto {
    Poland,
    Ukraine,
    Germany,
    France,
    UnitedKingdom,
    Italy,
    Spain,
    Netherlands,
    Sweden,
    Russia,
    UnitedStates,
    Canada,
    China,
    Korea,
    Japan,
    Portugal,
    India,
    Brazil,
    Indonesia,
    Mexico,
    Turkey,
    SaudiArabia,
    Egypt,
    Greece,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum AiStrategyIdDto {
    Random,
    Basic,
    Scripted,
    Utility,
    Mcts,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum AiDifficultyDto {
    Easy,
    Normal,
    Hard,
    VeryHard,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum AiPersonaDto {
    Balanced,
    Aggressive,
    Expansive,
    Economic,
    Scientific,
}
