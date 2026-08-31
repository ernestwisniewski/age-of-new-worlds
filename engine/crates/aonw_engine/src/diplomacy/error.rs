use crate::CommandRejectionCode;

/// Diplomacy command failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DiplomacyError {
    /// Stable normal command rejection.
    Rejected(CommandRejectionCode),
    /// Canonical diplomacy state rejected an engine-produced update.
    State(aonw_domain::DiplomacyStateBuildError),
    /// Canonical economy rejected an atomic proposal payment.
    Economy(aonw_domain::EconomyStateBuildError),
    /// Pending combat could not be rebuilt after accepted peace.
    Combat(Box<str>),
    /// Checked turn or identifier construction failed.
    InvalidState(Box<str>),
}

impl From<CommandRejectionCode> for DiplomacyError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

impl From<aonw_domain::DiplomacyStateBuildError> for DiplomacyError {
    fn from(value: aonw_domain::DiplomacyStateBuildError) -> Self {
        Self::State(value)
    }
}

impl From<aonw_domain::EconomyStateBuildError> for DiplomacyError {
    fn from(value: aonw_domain::EconomyStateBuildError) -> Self {
        Self::Economy(value)
    }
}

impl core::fmt::Display for DiplomacyError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(code) => code.fmt(formatter),
            Self::State(error) => error.fmt(formatter),
            Self::Economy(error) => error.fmt(formatter),
            Self::Combat(message) | Self::InvalidState(message) => formatter.write_str(message),
        }
    }
}

impl std::error::Error for DiplomacyError {}
