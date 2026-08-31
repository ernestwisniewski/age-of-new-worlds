use std::fmt;

use crate::{CanonicalFixture, CanonicalFixtureInput, CanonicalFixtureOutput, JsonDifference};

/// Engine-specific executor for the canonical fixture contract.
///
/// The committed expected result is intentionally not passed to the executor.
pub trait CanonicalFixtureExecutor {
    /// Executor-specific failure.
    type Error;

    /// Executes one complete canonical input through exactly one engine backend.
    ///
    /// # Errors
    ///
    /// Returns [`Self::Error`] if no complete typed output can be produced.
    fn execute(
        &self,
        fixture_id: &str,
        capability: &str,
        input: &CanonicalFixtureInput,
    ) -> Result<CanonicalFixtureOutput, Self::Error>;
}

/// Failure produced while executing or comparing one canonical fixture.
#[derive(Debug)]
pub enum FixtureRunError<ExecutionError> {
    /// The engine failed before producing a complete output.
    Execution {
        /// Fixture identifier.
        fixture_id: Box<str>,
        /// Engine-specific error.
        source: ExecutionError,
    },
    /// The engine output differs from the expected result.
    Mismatch {
        /// Fixture identifier.
        fixture_id: Box<str>,
        /// Bounded structural differences.
        differences: Vec<JsonDifference>,
    },
}

impl<ExecutionError> FixtureRunError<ExecutionError> {
    /// Returns the failing fixture identifier.
    #[must_use]
    pub fn fixture_id(&self) -> &str {
        match self {
            Self::Execution { fixture_id, .. } | Self::Mismatch { fixture_id, .. } => fixture_id,
        }
    }

    /// Returns structural differences for a result mismatch.
    #[must_use]
    pub fn differences(&self) -> Option<&[JsonDifference]> {
        match self {
            Self::Mismatch { differences, .. } => Some(differences),
            Self::Execution { .. } => None,
        }
    }
}

impl<ExecutionError: fmt::Display> fmt::Display for FixtureRunError<ExecutionError> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Execution { fixture_id, source } => {
                write!(
                    formatter,
                    "fixture {fixture_id} failed to execute: {source}"
                )
            }
            Self::Mismatch {
                fixture_id,
                differences,
            } => write!(
                formatter,
                "fixture {fixture_id} differs from the expected result at {} location(s)",
                differences.len()
            ),
        }
    }
}

impl<ExecutionError> std::error::Error for FixtureRunError<ExecutionError>
where
    ExecutionError: std::error::Error + 'static,
{
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Execution { source, .. } => Some(source),
            Self::Mismatch { .. } => None,
        }
    }
}

/// Executes and verifies one canonical fixture.
///
/// # Errors
///
/// Returns an execution error or bounded structural result differences.
pub fn verify_canonical_fixture<Executor: CanonicalFixtureExecutor>(
    fixture: &CanonicalFixture,
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    let actual = executor
        .execute(fixture.id(), fixture.capability(), fixture.input())
        .map_err(|source| FixtureRunError::Execution {
            fixture_id: fixture.id().into(),
            source,
        })?;
    let differences = fixture.differences(&actual);
    if differences.is_empty() {
        return Ok(());
    }
    Err(FixtureRunError::Mismatch {
        fixture_id: fixture.id().into(),
        differences,
    })
}

/// Executes a canonical corpus in sorted loader order.
///
/// # Errors
///
/// Returns the first execution failure or result mismatch.
pub fn verify_canonical_corpus<Executor: CanonicalFixtureExecutor>(
    fixtures: &[CanonicalFixture],
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    fixtures
        .iter()
        .try_for_each(|fixture| verify_canonical_fixture(fixture, executor))
}
