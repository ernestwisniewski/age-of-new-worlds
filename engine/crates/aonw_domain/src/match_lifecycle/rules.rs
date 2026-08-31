use std::collections::BTreeMap;

use super::{RuleNumber, RuleValue};

/// Match duration mode.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GameLengthKind {
    /// No duration target.
    Unlimited,
    /// A supported target duration is configured.
    TargetMinutes,
}

/// Pace profile used by rule-derived balance.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PaceProfile {
    /// Unlimited match.
    Unlimited,
    /// Approximately 60 minutes.
    Standard60,
    /// Approximately 90 minutes.
    Normal90,
    /// Approximately 120 minutes.
    Long120,
}

/// Validated game duration configuration.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameLengthConfig {
    kind: GameLengthKind,
    target_minutes: Option<u32>,
    turn_limit: Option<u32>,
    pace_profile: PaceProfile,
    score_fallback_enabled: bool,
}

/// Validated victory configuration.
#[allow(clippy::struct_excessive_bools)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct VictoryRules {
    conquest_enabled: bool,
    domination_enabled: bool,
    domination_control_percent: RuleNumber,
    domination_hold_turns: u32,
    score_fallback_enabled: bool,
    turn_limit: Option<u32>,
    hard_time_limit_minutes: Option<u32>,
    cultural_enabled: bool,
    cultural_required_artifacts: u32,
    cultural_hold_turns: u32,
}

/// Immutable match rules and typed balance overrides.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct MatchRules {
    game_length: GameLengthConfig,
    victory: VictoryRules,
    balance: BTreeMap<Box<str>, RuleValue>,
}

/// Structural match-rule failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MatchRulesBuildError {
    /// A duration or turn limit was zero.
    NonPositiveGameLength,
    /// Domination percent was outside `(0, 100]`.
    InvalidDominationPercent,
    /// A victory turn or artifact count was zero.
    NonPositiveVictoryThreshold,
}

impl core::fmt::Display for MatchRulesBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::NonPositiveGameLength => {
                formatter.write_str("game length values must be positive")
            }
            Self::InvalidDominationPercent => {
                formatter.write_str("domination control percent must be in range (0, 100]")
            }
            Self::NonPositiveVictoryThreshold => {
                formatter.write_str("victory thresholds must be positive")
            }
        }
    }
}

impl std::error::Error for MatchRulesBuildError {}

impl Default for GameLengthConfig {
    fn default() -> Self {
        Self {
            kind: GameLengthKind::Unlimited,
            target_minutes: None,
            turn_limit: None,
            pace_profile: PaceProfile::Unlimited,
            score_fallback_enabled: false,
        }
    }
}

impl GameLengthConfig {
    /// Constructs a structurally valid duration configuration.
    ///
    /// # Errors
    ///
    /// Returns an error when an optional positive value is zero.
    pub fn try_new(
        kind: GameLengthKind,
        target_minutes: Option<u32>,
        turn_limit: Option<u32>,
        pace_profile: PaceProfile,
        score_fallback_enabled: bool,
    ) -> Result<Self, MatchRulesBuildError> {
        if target_minutes == Some(0) || turn_limit == Some(0) {
            return Err(MatchRulesBuildError::NonPositiveGameLength);
        }
        Ok(Self {
            kind,
            target_minutes,
            turn_limit,
            pace_profile,
            score_fallback_enabled,
        })
    }

    /// Returns the duration mode.
    #[must_use]
    pub const fn kind(&self) -> GameLengthKind {
        self.kind
    }
    /// Returns the optional duration target.
    #[must_use]
    pub const fn target_minutes(&self) -> Option<u32> {
        self.target_minutes
    }
    /// Returns the optional turn limit.
    #[must_use]
    pub const fn turn_limit(&self) -> Option<u32> {
        self.turn_limit
    }
    /// Returns the pace profile.
    #[must_use]
    pub const fn pace_profile(&self) -> PaceProfile {
        self.pace_profile
    }
    /// Returns whether score fallback is enabled.
    #[must_use]
    pub const fn score_fallback_enabled(&self) -> bool {
        self.score_fallback_enabled
    }
}

impl Default for VictoryRules {
    fn default() -> Self {
        Self {
            conquest_enabled: true,
            domination_enabled: true,
            domination_control_percent: RuleNumber::new("60").expect("constant JSON number"),
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

impl VictoryRules {
    /// Constructs structurally valid victory thresholds.
    ///
    /// # Errors
    ///
    /// Returns an error for zero thresholds or a percent outside `(0, 100]`.
    #[allow(clippy::fn_params_excessive_bools, clippy::too_many_arguments)]
    pub fn try_new(
        conquest_enabled: bool,
        domination_enabled: bool,
        domination_control_percent: RuleNumber,
        domination_hold_turns: u32,
        score_fallback_enabled: bool,
        turn_limit: Option<u32>,
        hard_time_limit_minutes: Option<u32>,
        cultural_enabled: bool,
        cultural_required_artifacts: u32,
        cultural_hold_turns: u32,
    ) -> Result<Self, MatchRulesBuildError> {
        if !domination_control_percent.is_positive_and_at_most_integer(100) {
            return Err(MatchRulesBuildError::InvalidDominationPercent);
        }
        if domination_hold_turns == 0
            || cultural_required_artifacts == 0
            || cultural_hold_turns == 0
            || turn_limit == Some(0)
            || hard_time_limit_minutes == Some(0)
        {
            return Err(MatchRulesBuildError::NonPositiveVictoryThreshold);
        }
        Ok(Self {
            conquest_enabled,
            domination_enabled,
            domination_control_percent,
            domination_hold_turns,
            score_fallback_enabled,
            turn_limit,
            hard_time_limit_minutes,
            cultural_enabled,
            cultural_required_artifacts,
            cultural_hold_turns,
        })
    }

    /// Returns whether conquest victory is enabled.
    #[must_use]
    pub const fn conquest_enabled(&self) -> bool {
        self.conquest_enabled
    }
    /// Returns whether domination victory is enabled.
    #[must_use]
    pub const fn domination_enabled(&self) -> bool {
        self.domination_enabled
    }
    /// Returns the exact domination control percent.
    #[must_use]
    pub const fn domination_control_percent(&self) -> &RuleNumber {
        &self.domination_control_percent
    }
    /// Returns required domination hold turns.
    #[must_use]
    pub const fn domination_hold_turns(&self) -> u32 {
        self.domination_hold_turns
    }
    /// Returns whether score fallback is enabled.
    #[must_use]
    pub const fn score_fallback_enabled(&self) -> bool {
        self.score_fallback_enabled
    }
    /// Returns the optional score turn limit.
    #[must_use]
    pub const fn turn_limit(&self) -> Option<u32> {
        self.turn_limit
    }
    /// Returns the optional hard time limit.
    #[must_use]
    pub const fn hard_time_limit_minutes(&self) -> Option<u32> {
        self.hard_time_limit_minutes
    }
    /// Returns whether cultural victory is enabled.
    #[must_use]
    pub const fn cultural_enabled(&self) -> bool {
        self.cultural_enabled
    }
    /// Returns required cultural artifacts.
    #[must_use]
    pub const fn cultural_required_artifacts(&self) -> u32 {
        self.cultural_required_artifacts
    }
    /// Returns required cultural hold turns.
    #[must_use]
    pub const fn cultural_hold_turns(&self) -> u32 {
        self.cultural_hold_turns
    }
}

impl MatchRules {
    /// Combines validated match rule components.
    #[must_use]
    pub const fn new(
        game_length: GameLengthConfig,
        victory: VictoryRules,
        balance: BTreeMap<Box<str>, RuleValue>,
    ) -> Self {
        Self {
            game_length,
            victory,
            balance,
        }
    }

    /// Returns duration configuration.
    #[must_use]
    pub const fn game_length(&self) -> &GameLengthConfig {
        &self.game_length
    }
    /// Returns victory configuration.
    #[must_use]
    pub const fn victory(&self) -> &VictoryRules {
        &self.victory
    }
    /// Returns key-sorted balance overrides.
    #[must_use]
    pub const fn balance(&self) -> &BTreeMap<Box<str>, RuleValue> {
        &self.balance
    }
}
