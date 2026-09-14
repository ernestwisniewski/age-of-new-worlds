use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{CityId, GameState, PlayerId};

use crate::{CanonicalEngineError, DomainEvent};

#[cfg(test)]
mod tests;

pub(super) struct CityPhase {
    pub(super) state: GameState,
    pub(super) events: Vec<DomainEvent>,
    pub(super) founded_city_ids: Vec<CityId>,
}

pub(super) fn advance_city_phase(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<CityPhase, CanonicalEngineError> {
    let Some(update) = crate::city::advance_city_founding(&state, map, ruleset, scope)
        .map_err(CanonicalEngineError::CityFounding)?
    else {
        return Ok(CityPhase {
            state,
            events: Vec::new(),
            founded_city_ids: Vec::new(),
        });
    };
    let crate::city::CityFoundingTurnUpdate {
        state: update,
        events,
        founded_city_ids,
    } = update;
    let state = state
        .into_after_city_founding(update)
        .map_err(CanonicalEngineError::State)?;
    Ok(CityPhase {
        state,
        events,
        founded_city_ids,
    })
}
