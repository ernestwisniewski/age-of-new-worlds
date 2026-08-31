//! Independent canonical fixture infrastructure for the Rust engine.
//!
//! Canonical fixtures own strict DTOs and validated map content without
//! depending on a concrete engine implementation. JSON object order is
//! insignificant, array order remains observable, input sizes are bounded, and
//! expected outputs are never generated or rewritten by the runner.

#![forbid(unsafe_code)]

mod canonical_fixture;
mod canonical_fixture_parser;
mod canonical_loader;
mod canonical_runner;
mod diff;
mod loader_error;
mod unique_json;

pub use canonical_fixture::{
    CANONICAL_FIXTURE_VERSION, CanonicalFixture, CanonicalFixtureInput, CanonicalFixtureOutput,
};
pub use canonical_loader::{CanonicalFixtureLoader, FixtureLimits};
pub use canonical_runner::{
    CanonicalFixtureExecutor, FixtureRunError, verify_canonical_corpus, verify_canonical_fixture,
};
pub use diff::{DifferenceKind, JsonDifference, compare_json};
pub use loader_error::FixtureLoadError;
