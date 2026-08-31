mod bootstrap;
mod canonical;
mod codec;
mod error;
mod model;

pub use error::{ScenarioBootstrapError, ScenarioLoadError, ScenarioValidationError};
pub use model::{ScenarioDefinition, ScenarioUnitDefinition};

pub(super) const MAX_SCENARIO_UNITS: usize = 4096;

#[cfg(test)]
mod tests;
