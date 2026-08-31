use aonw_domain::{GameStateBuildError, UnitBuildError, UnitKind};

use super::MAX_SCENARIO_UNITS;

/// Failure raised while decoding current scenario content.
#[derive(Debug)]
pub enum ScenarioLoadError {
    /// Input exceeds the allocation boundary.
    TooLarge {
        /// Actual byte count.
        actual: usize,
        /// Maximum accepted byte count.
        maximum: usize,
    },
    /// JSON violates the strict scenario shape.
    Json(serde_json::Error),
    /// The schema version is not current.
    UnsupportedVersion(u16),
    /// The document references different immutable content.
    ContentMismatch(&'static str),
    /// The scenario exceeds its entity boundary.
    TooManyUnits(usize),
    /// One identifier or unit kind is invalid.
    InvalidField {
        /// Contract path.
        path: Box<str>,
        /// Validation message.
        message: Box<str>,
    },
    /// Domain validation rejected the decoded scenario.
    Validation(ScenarioValidationError),
}

impl core::fmt::Display for ScenarioLoadError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(
                    formatter,
                    "scenario has {actual} bytes; maximum is {maximum}"
                )
            }
            Self::Json(source) => source.fmt(formatter),
            Self::UnsupportedVersion(version) => {
                write!(formatter, "unsupported scenario version {version}")
            }
            Self::ContentMismatch(kind) => {
                write!(formatter, "scenario references a different {kind}")
            }
            Self::TooManyUnits(count) => {
                write!(
                    formatter,
                    "scenario has {count} units; maximum is {MAX_SCENARIO_UNITS}"
                )
            }
            Self::InvalidField { path, message } => write!(formatter, "{path}: {message}"),
            Self::Validation(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ScenarioLoadError {}

/// Failure raised while constructing immutable scenario content.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioValidationError {
    path: Box<str>,
    message: Box<str>,
}

impl ScenarioValidationError {
    pub(super) fn new(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self {
            path: path.into(),
            message: message.into(),
        }
    }
}

impl core::fmt::Display for ScenarioValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(formatter, "{}: {}", self.path, self.message)
    }
}

impl std::error::Error for ScenarioValidationError {}

/// Failure raised while materializing a scenario into canonical state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ScenarioBootstrapError {
    /// Supplied content does not match the scenario identity.
    ContentMismatch(&'static str),
    /// A referenced content hash could not be computed.
    ContentHash(Box<str>),
    /// A unit definition disappeared from the referenced ruleset.
    MissingUnitDefinition(UnitKind),
    /// An initial unit violates entity invariants.
    InvalidUnit(UnitBuildError),
    /// Initial units violate aggregate invariants.
    InvalidState(GameStateBuildError),
}

impl core::fmt::Display for ScenarioBootstrapError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ContentMismatch(kind) => write!(
                formatter,
                "scenario {kind} identity does not match supplied content"
            ),
            Self::ContentHash(source) => {
                write!(formatter, "cannot hash referenced content: {source}")
            }
            Self::MissingUnitDefinition(kind) => {
                write!(formatter, "ruleset has no definition for {kind:?}")
            }
            Self::InvalidUnit(source) => write!(formatter, "invalid initial unit: {source}"),
            Self::InvalidState(source) => write!(formatter, "invalid initial state: {source}"),
        }
    }
}

impl std::error::Error for ScenarioBootstrapError {}
