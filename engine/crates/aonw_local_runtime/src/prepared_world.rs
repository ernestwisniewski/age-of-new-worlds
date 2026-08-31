use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::GameState;
use aonw_engine::CompiledMovementMap;

use crate::OpenSessionError;

#[derive(Clone, Debug)]
pub(crate) struct PreparedWorld {
    movement_map: CompiledMovementMap,
}

impl PreparedWorld {
    pub(crate) fn try_new(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        state: &GameState,
    ) -> Result<Self, OpenSessionError> {
        if map.bounds() != state.bounds() {
            return Err(OpenSessionError::MapBoundsMismatch);
        }
        if ruleset.occupancy_policy() != state.occupancy_policy() {
            return Err(OpenSessionError::OccupancyPolicyMismatch);
        }
        let movement_map = CompiledMovementMap::compile_owned(map, ruleset)
            .map_err(|error| OpenSessionError::ContentHash(error.to_string().into()))?;
        Ok(Self { movement_map })
    }

    pub(crate) const fn map(&self) -> &MapDefinition {
        self.movement_map.map()
    }

    pub(crate) const fn ruleset(&self) -> &RulesetDefinition {
        self.movement_map.ruleset()
    }

    pub(crate) const fn map_hash(&self) -> ContentHash {
        self.movement_map.map_hash()
    }

    pub(crate) const fn ruleset_hash(&self) -> ContentHash {
        self.movement_map.ruleset_hash()
    }

    pub(crate) const fn movement_map(&self) -> &CompiledMovementMap {
        &self.movement_map
    }
}
