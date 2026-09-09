use std::collections::BTreeSet;

use aonw_domain::{FogVisibility, GameState, HexCoord};

use crate::{EngineContext, GameEngine};

/// Revision-bound request for recipient-safe city planning markings.
#[derive(Clone, Copy, Debug)]
pub struct CityPlanningQuery {
    expected_revision: u64,
}

impl CityPlanningQuery {
    /// Creates a request without client-supplied visibility or ownership.
    #[must_use]
    pub const fn new(expected_revision: u64) -> Self {
        Self { expected_revision }
    }
}

/// Discovered planning candidates, not a promise that a founding command is legal.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityPlanning {
    /// Unclaimed disclosed terrain satisfying city-center terrain and distance rules.
    pub city_sites: Vec<HexCoord>,
    /// Discovered tiles unclaimed by any city known to the recipient.
    /// Terrain alone does not constrain territory growth.
    pub growth_tiles: Vec<HexCoord>,
}

/// Failure of a revision-bound city planning request.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CityPlanningError {
    /// The request does not match the authoritative revision.
    StaleRevision,
    /// The authenticated actor is not a participant.
    PlayerNotInMatch,
}

impl CityPlanningError {
    /// Returns a stable query rejection code.
    #[must_use]
    pub const fn code(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::PlayerNotInMatch => "city_planning_player_not_in_match",
        }
    }
}

impl core::fmt::Display for CityPlanningError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.code())
    }
}

impl std::error::Error for CityPlanningError {}

impl GameEngine {
    /// Returns optional map markings using only cities known to this recipient.
    /// Hidden foreign cities cannot change the candidates, including distance
    /// exclusions on nearby discovered tiles. Commands still validate full state.
    ///
    /// # Errors
    ///
    /// Rejects stale revisions and actors outside the match.
    pub fn city_planning(
        state: &GameState,
        context: EngineContext<'_>,
        query: CityPlanningQuery,
    ) -> Result<CityPlanning, CityPlanningError> {
        if state.revision().get() != query.expected_revision {
            return Err(CityPlanningError::StaleRevision);
        }
        let actor = context.actor_player_id();
        if !state.match_lifecycle().identity().contains(actor) {
            return Err(CityPlanningError::PlayerNotInMatch);
        }
        let known = |hex| state.fog_of_war().visibility(actor, hex) != FogVisibility::Hidden;
        let cities = state
            .cities()
            .iter()
            .filter(|city| city.owner_player_id() == actor || known(city.center()))
            .collect::<Vec<_>>();
        let claimed = cities
            .iter()
            .flat_map(|city| {
                std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
            })
            .collect::<BTreeSet<_>>();
        let minimum = u64::from(context.ruleset().city().minimum_center_distance());
        let mut result = CityPlanning {
            city_sites: Vec::new(),
            growth_tiles: Vec::new(),
        };
        for tile in context.map().tiles() {
            let hex = tile.coordinate();
            if !known(hex) || claimed.contains(&hex) {
                continue;
            }
            result.growth_tiles.push(hex);
            if crate::city::can_found_on_terrain(tile.yield_terrain())
                && cities
                    .iter()
                    .all(|city| city.center().distance_to(hex) >= minimum)
            {
                result.city_sites.push(hex);
            }
        }
        result.city_sites.sort_unstable();
        result.growth_tiles.sort_unstable();
        Ok(result)
    }
}
