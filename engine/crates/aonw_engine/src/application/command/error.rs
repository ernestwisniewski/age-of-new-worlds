use aonw_domain::{DiplomacyStateBuildError, GameStateBuildError, TurnLifecycleBuildError};

/// Failure indicating corrupt internal state rather than a rejected command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalEngineError {
    /// A referenced content identity could not be computed.
    ContentHash(Box<str>),
    /// Applying the result violates an aggregate invariant.
    State(GameStateBuildError),
    /// Applying a lifecycle result violates lifecycle invariants.
    TurnLifecycle(TurnLifecycleBuildError),
    /// Applying combat diplomacy violates diplomacy invariants.
    Diplomacy(DiplomacyStateBuildError),
    /// A diplomacy command produced an invalid checked update.
    DiplomacyCommand(crate::DiplomacyError),
    /// Technology content referenced by canonical city rules is incomplete.
    Technology(crate::TechnologyQueryError),
    /// A validated city-founding job could not construct canonical state.
    CityFounding(Box<str>),
    /// A validated worker job could not construct canonical infrastructure.
    Worker(Box<str>),
    /// A production transition violated current content or state invariants.
    Production(crate::ProductionError),
    /// An artifact transition violated current state invariants.
    Artifact(crate::ArtifactError),
    /// A research transition violated current content or state invariants.
    Research(crate::ResearchError),
    /// Objective progression overflowed or produced invalid canonical state.
    Objective(Box<str>),
    /// Economy progression overflowed or produced invalid canonical state.
    Economy(Box<str>),
    /// Match-outcome resolution overflowed or encountered incomplete content.
    Outcome(crate::OutcomeResolutionError),
}

impl core::fmt::Display for CanonicalEngineError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
            Self::State(source) => source.fmt(formatter),
            Self::TurnLifecycle(source) => source.fmt(formatter),
            Self::Diplomacy(source) => source.fmt(formatter),
            Self::DiplomacyCommand(source) => source.fmt(formatter),
            Self::Technology(source) => source.fmt(formatter),
            Self::CityFounding(source) => write!(formatter, "city founding failed: {source}"),
            Self::Worker(source) => write!(formatter, "worker progression failed: {source}"),
            Self::Production(source) => write!(formatter, "production failed: {source}"),
            Self::Artifact(source) => write!(formatter, "artifact failed: {source}"),
            Self::Research(source) => write!(formatter, "research failed: {source}"),
            Self::Objective(source) => write!(formatter, "objective progression failed: {source}"),
            Self::Economy(source) => write!(formatter, "economy progression failed: {source}"),
            Self::Outcome(source) => write!(formatter, "outcome resolution failed: {source}"),
        }
    }
}

impl std::error::Error for CanonicalEngineError {}
