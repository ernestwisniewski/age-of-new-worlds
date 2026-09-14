use aonw_content::RulesetDefinition;
use aonw_domain::{GameState, MovementStep, Unit};

/// A private persisted itinerary with authoritative presentation metadata.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OwnedRouteView<T> {
    route: T,
    step_turns: Box<[u32]>,
    road_step_indices: Box<[u32]>,
}

impl<T> OwnedRouteView<T> {
    pub(super) fn new(
        state: &GameState,
        ruleset: &RulesetDefinition,
        unit: &Unit,
        route: T,
        steps: &[MovementStep],
    ) -> Option<Box<Self>> {
        let step_turns = aonw_engine::stored_route_step_turns(unit, ruleset, steps)?.collect();
        let road_step_indices =
            aonw_engine::route_road_step_indices(state, ruleset, unit, steps).collect();
        Some(Box::new(Self {
            route,
            step_turns,
            road_step_indices,
        }))
    }

    /// Returns the unchanged canonical itinerary.
    #[must_use]
    pub const fn route(&self) -> &T {
        &self.route
    }

    /// Returns zero for traversed steps and calendar turns from the current position.
    #[must_use]
    pub const fn step_turns(&self) -> &[u32] {
        &self.step_turns
    }

    /// Returns destination indices of known operational road edges for this unit.
    #[must_use]
    pub const fn road_step_indices(&self) -> &[u32] {
        &self.road_step_indices
    }
}
