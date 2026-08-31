use crate::{CommandRejectionCode, TechnologyQueryError};

/// Research query or transition failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ResearchError {
    /// Stable normal command/query rejection.
    Rejected(CommandRejectionCode),
    /// The immutable technology catalog is incomplete or arithmetic overflowed.
    Technology(TechnologyQueryError),
    /// A checked canonical research transition failed.
    Transition(aonw_domain::ResearchTransitionError),
    /// Canonical state could not provide a bounded research input.
    InvalidState(Box<str>),
}

impl ResearchError {
    /// Returns the stable boundary code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Rejected(code) => code.as_str(),
            Self::Technology(_) => "technology_query_invalid",
            Self::Transition(_) | Self::InvalidState(_) => "research_state_invalid",
        }
    }
}

impl From<CommandRejectionCode> for ResearchError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

impl From<TechnologyQueryError> for ResearchError {
    fn from(value: TechnologyQueryError) -> Self {
        Self::Technology(value)
    }
}

impl From<aonw_domain::ResearchTransitionError> for ResearchError {
    fn from(value: aonw_domain::ResearchTransitionError) -> Self {
        Self::Transition(value)
    }
}

impl core::fmt::Display for ResearchError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(code) => code.fmt(formatter),
            Self::Technology(error) => error.fmt(formatter),
            Self::Transition(error) => error.fmt(formatter),
            Self::InvalidState(message) => formatter.write_str(message),
        }
    }
}

impl std::error::Error for ResearchError {}
