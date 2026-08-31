mod participant;
mod rules;
mod turn;
mod value;

pub use participant::{
    AiDifficulty, AiPersona, AiPlayer, AiStrategyId, GameMode, MatchIdentity, Participant,
    PlayerCountry, PlayerKind,
};
pub use rules::{
    GameLengthConfig, GameLengthKind, MatchRules, MatchRulesBuildError, PaceProfile, VictoryRules,
};
pub use turn::{PlayerTurnState, TurnLifecycle, TurnLifecycleBuildError, UtcTimestamp};
pub use value::{RuleNumber, RuleNumberError, RuleValue};

/// Canonical identity, immutable rules and current turn lifecycle.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct MatchLifecycle {
    identity: MatchIdentity,
    turn: TurnLifecycle,
}

impl MatchLifecycle {
    /// Combines already validated identity and turn state.
    #[must_use]
    pub const fn new(identity: MatchIdentity, turn: TurnLifecycle) -> Self {
        Self { identity, turn }
    }

    /// Returns immutable match identity and rules.
    #[must_use]
    pub const fn identity(&self) -> &MatchIdentity {
        &self.identity
    }

    /// Returns current per-player turn lifecycle.
    #[must_use]
    pub const fn turn(&self) -> &TurnLifecycle {
        &self.turn
    }

    /// Replaces current turn state while retaining immutable match identity.
    #[must_use]
    pub fn with_turn(self, turn: TurnLifecycle) -> Self {
        Self {
            identity: self.identity,
            turn,
        }
    }
}
