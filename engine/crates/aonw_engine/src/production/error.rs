use crate::CommandRejectionCode;

/// Production query or transition failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ProductionError {
    /// Stable normal command/query rejection.
    Rejected(CommandRejectionCode),
    /// Content or an engine-produced update violated current invariants.
    InvalidState(Box<str>),
}

impl ProductionError {
    /// Returns the stable boundary code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Rejected(code) => code.as_str(),
            Self::InvalidState(_) => "production_state_invalid",
        }
    }
}

impl From<CommandRejectionCode> for ProductionError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

impl core::fmt::Display for ProductionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(code) => code.fmt(formatter),
            Self::InvalidState(message) => formatter.write_str(message),
        }
    }
}

impl std::error::Error for ProductionError {}
