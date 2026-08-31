use aonw_domain::GameOutcome;

/// Accepted fact that authoritative turn processing ended the match.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MatchEndedEvent {
    turn: u32,
    outcome: GameOutcome,
}

impl MatchEndedEvent {
    pub(crate) const fn new(turn: u32, outcome: GameOutcome) -> Self {
        Self { turn, outcome }
    }

    /// Returns the turn at which the terminal result became authoritative.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns the exact persisted terminal result.
    #[must_use]
    pub const fn outcome(&self) -> &GameOutcome {
        &self.outcome
    }
}
