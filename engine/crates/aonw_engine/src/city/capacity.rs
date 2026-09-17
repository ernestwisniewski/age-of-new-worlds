use aonw_domain::{City, GameState};

use super::CityRuleError;
use crate::{EngineContext, TechnologyUnlockQuery};

pub(crate) fn territory_capacity(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<i64, CityRuleError> {
    let technology_bonus = match state.research().players().get(city.owner_player_id()) {
        Some(research) => {
            TechnologyUnlockQuery::new(context.ruleset(), research)
                .effect_summary()
                .map_err(CityRuleError::Technology)?
                .max_controlled_hexes_bonus
        }
        None => 0,
    };
    Ok(city.max_hexes().saturating_add(i64::from(technology_bonus)))
}
