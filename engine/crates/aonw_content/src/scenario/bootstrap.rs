use aonw_domain::{GameState, StateRevision, Unit};

use crate::{MapDefinition, RulesetDefinition};

use super::{ScenarioBootstrapError, ScenarioDefinition};

impl ScenarioDefinition {
    /// Materializes the scenario as revision-zero canonical state.
    ///
    /// # Errors
    ///
    /// Returns an error if referenced content differs from the validated scenario
    /// or if a unit/state invariant cannot be established.
    pub fn bootstrap(
        &self,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<GameState, ScenarioBootstrapError> {
        let map_hash = map
            .content_hash()
            .map_err(|error| ScenarioBootstrapError::ContentHash(error.to_string().into()))?;
        if map.map_id() != &*self.map_id || map_hash != self.map_hash {
            return Err(ScenarioBootstrapError::ContentMismatch("map"));
        }
        let ruleset_hash = ruleset
            .content_hash()
            .map_err(|error| ScenarioBootstrapError::ContentHash(error.to_string().into()))?;
        if ruleset.ruleset_id() != &*self.ruleset_id || ruleset_hash != self.ruleset_hash {
            return Err(ScenarioBootstrapError::ContentMismatch("ruleset"));
        }
        let units = self
            .initial_units
            .iter()
            .map(|initial| {
                let definition = ruleset.unit(initial.kind()).ok_or(
                    ScenarioBootstrapError::MissingUnitDefinition(initial.kind()),
                )?;
                Unit::builder(
                    initial.id().clone(),
                    initial.owner_player_id().clone(),
                    initial.kind(),
                    initial.name(),
                    initial.position(),
                    definition.maximum_movement(false),
                )
                .build()
                .map_err(ScenarioBootstrapError::InvalidUnit)
            })
            .collect::<Result<Vec<_>, _>>()?;
        GameState::try_new(
            StateRevision::INITIAL,
            1,
            map.bounds(),
            ruleset.occupancy_policy(),
            units,
        )
        .map_err(ScenarioBootstrapError::InvalidState)
    }
}
