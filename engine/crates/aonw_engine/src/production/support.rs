use aonw_domain::{City, GameState, PlayerResearchState};

use super::ProductionError;
use crate::{CommandRejectionCode, EngineContext, TechnologyUnlockQuery};

pub(super) fn controlled_city<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    city_id: &aonw_domain::CityId,
) -> Result<&'state City, ProductionError> {
    let city = state
        .city(city_id)
        .ok_or(CommandRejectionCode::CityNotFound)?;
    if !context.can_act() || city.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::CityNotControlled.into());
    }
    Ok(city)
}

pub(super) fn validate_revision(state: &GameState, expected: u64) -> Result<(), ProductionError> {
    if state.revision().get() == expected {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}

pub(super) fn next_revision(
    state: &GameState,
) -> Result<aonw_domain::StateRevision, ProductionError> {
    state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow.into())
}

pub(super) fn replace_city(cities: &mut [City], updated: City) -> Result<(), ProductionError> {
    let city = cities
        .iter_mut()
        .find(|city| city.id() == updated.id())
        .ok_or_else(|| invalid("validated production city disappeared"))?;
    *city = updated;
    Ok(())
}

pub(super) fn technology_for<'query>(
    state: &'query GameState,
    context: EngineContext<'query>,
    city: &City,
) -> TechnologyUnlockQuery<'query> {
    let research = state
        .research()
        .players()
        .get(city.owner_player_id())
        .unwrap_or_else(|| empty_research());
    TechnologyUnlockQuery::new(context.ruleset(), research)
}

fn empty_research() -> &'static PlayerResearchState {
    static EMPTY: std::sync::LazyLock<PlayerResearchState> =
        std::sync::LazyLock::new(PlayerResearchState::default);
    &EMPTY
}

pub(super) fn city_territory(city: &City) -> impl Iterator<Item = aonw_domain::HexCoord> + '_ {
    std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
}

pub(super) fn spawn_candidates<'city>(
    context: EngineContext<'_>,
    city: &'city City,
) -> impl Iterator<Item = aonw_domain::HexCoord> + 'city {
    let center = city.center();
    let mut candidates = vec![center];
    for coordinate in center
        .neighbors()
        .filter(|coordinate| context.map().tile_at(*coordinate).is_some())
        .chain(city.controlled_hexes().iter().copied())
    {
        if !candidates.contains(&coordinate) {
            candidates.push(coordinate);
        }
    }
    candidates.into_iter()
}

pub(super) fn pace(state: &GameState) -> aonw_domain::PaceProfile {
    state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile()
}

pub(super) fn invalid(message: impl Into<Box<str>>) -> ProductionError {
    ProductionError::InvalidState(message.into())
}
