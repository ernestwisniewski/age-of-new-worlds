use crate::CommandRejectionCode;

/// Artifact query or transition failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ArtifactError {
    /// Stable normal command rejection.
    Rejected(CommandRejectionCode),
    /// Canonical state or an engine-produced update violated an invariant.
    InvalidState(Box<str>),
}

impl ArtifactError {
    /// Returns the stable boundary code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Rejected(code) => code.as_str(),
            Self::InvalidState(_) => "artifact_state_invalid",
        }
    }
}

impl From<CommandRejectionCode> for ArtifactError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

impl core::fmt::Display for ArtifactError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(code) => code.fmt(formatter),
            Self::InvalidState(message) => formatter.write_str(message),
        }
    }
}

impl std::error::Error for ArtifactError {}
