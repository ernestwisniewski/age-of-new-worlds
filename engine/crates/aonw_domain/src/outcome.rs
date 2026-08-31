use std::collections::BTreeMap;

use crate::{MatchIdentity, PlayerId};

/// Authoritative reason why a match is still active or has ended.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GameOutcomeCondition {
    Ongoing,
    Conquest,
    Domination,
    Cultural,
    Score,
    Resignation,
    Draw,
}

/// Persisted terminal result produced at an authoritative turn boundary.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameOutcome {
    condition: GameOutcomeCondition,
    winner_player_id: Option<PlayerId>,
    score_by_player_id: BTreeMap<PlayerId, i64>,
}

impl Default for GameOutcome {
    fn default() -> Self {
        Self::ongoing()
    }
}

impl GameOutcome {
    /// Returns the canonical non-terminal result.
    #[must_use]
    pub const fn ongoing() -> Self {
        Self {
            condition: GameOutcomeCondition::Ongoing,
            winner_player_id: None,
            score_by_player_id: BTreeMap::new(),
        }
    }

    /// Constructs and validates an outcome against match participants.
    ///
    /// # Errors
    ///
    /// Returns an error for an invalid winner, score reference, or condition shape.
    pub fn try_new(
        identity: &MatchIdentity,
        condition: GameOutcomeCondition,
        winner_player_id: Option<PlayerId>,
        score_by_player_id: BTreeMap<PlayerId, i64>,
    ) -> Result<Self, GameOutcomeBuildError> {
        let outcome = Self {
            condition,
            winner_player_id,
            score_by_player_id,
        };
        outcome.validate_for(identity)?;
        Ok(outcome)
    }

    /// Validates the result shape and every participant reference.
    ///
    /// # Errors
    ///
    /// Returns an error when the condition, winner, or scores disagree.
    pub fn validate_for(&self, identity: &MatchIdentity) -> Result<(), GameOutcomeBuildError> {
        if let Some(winner) = &self.winner_player_id
            && !identity.contains(winner)
        {
            return Err(GameOutcomeBuildError::PlayerNotFound(winner.clone()));
        }
        for (player, score) in &self.score_by_player_id {
            if !identity.contains(player) {
                return Err(GameOutcomeBuildError::PlayerNotFound(player.clone()));
            }
            if *score < 0 {
                return Err(GameOutcomeBuildError::NegativeScore(player.clone()));
            }
        }

        match self.condition {
            GameOutcomeCondition::Ongoing => {
                if self.winner_player_id.is_some() || !self.score_by_player_id.is_empty() {
                    return Err(GameOutcomeBuildError::InvalidConditionShape);
                }
            }
            GameOutcomeCondition::Conquest
            | GameOutcomeCondition::Domination
            | GameOutcomeCondition::Cultural
            | GameOutcomeCondition::Resignation => {
                if self.winner_player_id.is_none() || !self.score_by_player_id.is_empty() {
                    return Err(GameOutcomeBuildError::InvalidConditionShape);
                }
            }
            GameOutcomeCondition::Score => {
                let winner = self
                    .winner_player_id
                    .as_ref()
                    .ok_or(GameOutcomeBuildError::InvalidConditionShape)?;
                if self.score_by_player_id.is_empty()
                    || !has_unique_top_score(&self.score_by_player_id, winner)
                {
                    return Err(GameOutcomeBuildError::InvalidConditionShape);
                }
            }
            GameOutcomeCondition::Draw => {
                if self.winner_player_id.is_some()
                    || (!self.score_by_player_id.is_empty()
                        && !has_tied_top_score(&self.score_by_player_id))
                {
                    return Err(GameOutcomeBuildError::InvalidConditionShape);
                }
            }
        }
        Ok(())
    }

    /// Returns the outcome condition.
    #[must_use]
    pub const fn condition(&self) -> GameOutcomeCondition {
        self.condition
    }

    /// Returns the unique winner for a winning condition.
    #[must_use]
    pub const fn winner_player_id(&self) -> Option<&PlayerId> {
        self.winner_player_id.as_ref()
    }

    /// Returns the final deterministic score table for score outcomes and draws.
    #[must_use]
    pub const fn score_by_player_id(&self) -> &BTreeMap<PlayerId, i64> {
        &self.score_by_player_id
    }

    /// Returns whether the authoritative match has ended.
    #[must_use]
    pub const fn is_terminal(&self) -> bool {
        !matches!(self.condition, GameOutcomeCondition::Ongoing)
    }
}

/// Structural failure in a persisted match result.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum GameOutcomeBuildError {
    /// A winner or score entry references someone outside the match.
    PlayerNotFound(PlayerId),
    /// A final score cannot be negative.
    NegativeScore(PlayerId),
    /// Winner and score data do not match the selected condition.
    InvalidConditionShape,
}

impl core::fmt::Display for GameOutcomeBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::PlayerNotFound(player) => {
                write!(
                    formatter,
                    "game outcome references non-participant {player}"
                )
            }
            Self::NegativeScore(player) => {
                write!(
                    formatter,
                    "game outcome contains a negative score for {player}"
                )
            }
            Self::InvalidConditionShape => {
                formatter.write_str("game outcome data does not match its condition")
            }
        }
    }
}

impl std::error::Error for GameOutcomeBuildError {}

fn has_unique_top_score(scores: &BTreeMap<PlayerId, i64>, winner: &PlayerId) -> bool {
    let Some(winner_score) = scores.get(winner) else {
        return false;
    };
    scores
        .iter()
        .all(|(player, score)| player == winner || score < winner_score)
}

fn has_tied_top_score(scores: &BTreeMap<PlayerId, i64>) -> bool {
    let Some(top_score) = scores.values().max() else {
        return false;
    };
    scores.values().filter(|score| *score == top_score).count() > 1
}
