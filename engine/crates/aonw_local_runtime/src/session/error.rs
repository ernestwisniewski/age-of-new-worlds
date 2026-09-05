use aonw_engine::{CanonicalEngineError, CanonicalQueryError};

/// Failure from an operation requiring a valid local session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeError {
    /// No session is open.
    SessionNotOpen,
    /// A prior internal failure invalidated the in-memory session transaction.
    SessionPoisoned,
    /// A read-only query was rejected.
    Query(CanonicalQueryError),
    /// Canonical transition construction failed.
    Engine(CanonicalEngineError),
    /// Authoritative event offset exhausted its integer range.
    EventOffsetOverflow,
    /// An observed command batch exceeded its reviewed command count.
    ObservationBudgetExceeded,
    /// The engine emitted more events than the reviewed command budget.
    EventBudgetExceeded {
        /// Reviewed upper bound for the concrete player command.
        maximum: u64,
        /// Number of events returned by the engine transition.
        actual: u64,
    },
}

impl RuntimeError {
    /// Returns a stable adapter code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::SessionNotOpen => "session_not_open",
            Self::SessionPoisoned => "session_poisoned",
            Self::Query(error) => error.code(),
            Self::Engine(_) => "canonical_engine_failed",
            Self::EventOffsetOverflow => "event_offset_overflow",
            Self::ObservationBudgetExceeded => "observation_budget_exceeded",
            Self::EventBudgetExceeded { .. } => "event_budget_exceeded",
        }
    }
}

impl core::fmt::Display for RuntimeError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::SessionPoisoned => {
                formatter.write_str("session was invalidated by a prior internal failure")
            }
            Self::Query(source) => source.fmt(formatter),
            Self::Engine(source) => source.fmt(formatter),
            Self::EventOffsetOverflow => formatter.write_str("event offset overflow"),
            Self::ObservationBudgetExceeded => {
                formatter.write_str("observed command budget exceeded")
            }
            Self::EventBudgetExceeded { maximum, actual } => write!(
                formatter,
                "event budget exceeded: maximum {maximum}, actual {actual}"
            ),
        }
    }
}

impl std::error::Error for RuntimeError {}
