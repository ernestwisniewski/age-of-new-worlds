use std::collections::BTreeSet;

use aonw_content::MapDefinition;
use aonw_domain::{
    City, CityFoundingJob, Diplomacy, FogOfWar, GameState, HexCoord, InteractionState,
    StateRevision, Unit,
};

use super::model::{
    CityExpansionCandidate, CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions,
    CityFoundingOptionsQuery, CityWorkedHexOptions, CityWorkedHexOptionsQuery, FoundCityCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};
use crate::{CommandRejectionCode, EngineContext, TechnologyQueryError, TechnologyUnlockQuery};

mod founding;
mod scoring;

pub(super) use founding::founding_job_is_valid;
use founding::{
    can_complete_founding, selectable_founding_hexes, territory_connected,
    valid_founding_candidate, validate_controlled_hexes, validate_founder_start,
};
use scoring::{expansion_score, worked_score};

/// Corrupt content/state failure or a normal city command rejection.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum CityRuleError {
    Rejected(CommandRejectionCode),
    Technology(TechnologyQueryError),
}

impl From<CommandRejectionCode> for CityRuleError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

/// Atomic replacement produced by a state-changing city command.
pub(crate) enum CityMutation {
    Identity,
    Update(Box<CityUpdate>),
}

pub(crate) struct CityUpdate {
    pub(crate) revision: StateRevision,
    pub(crate) units: Vec<Unit>,
    pub(crate) cities: Vec<City>,
    pub(crate) interaction: InteractionState,
    pub(crate) fog_of_war: FogOfWar,
    pub(crate) diplomacy: Diplomacy,
}

pub(crate) fn apply_found_city(
    state: &GameState,
    context: EngineContext<'_>,
    command: FoundCityCommand<'_>,
) -> Result<CityMutation, CityRuleError> {
    validate_revision(state, command.expected_revision())?;
    let founder = validate_founder_start(state, context, command.founder_unit_id())?;
    validate_controlled_hexes(
        founder.position(),
        command.controlled_hexes(),
        state.cities(),
        context.map(),
        context.ruleset().city().founding_controlled_hexes(),
        context.ruleset().city().founding_max_radius(),
    )?;
    let revision = next_revision(state)?;
    let turns = context.ruleset().city().founding_turns();
    let mut controlled_hexes = command.controlled_hexes().to_vec();
    controlled_hexes.sort_unstable();
    let job = CityFoundingJob::new(founder.position(), controlled_hexes, turns, turns);
    let updated = founder.with_city_founding_job(Some(job));
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated);
    let interaction = if state
        .interaction()
        .city_founding_draft()
        .is_some_and(|draft| draft.unit_id() == founder.id())
    {
        state.interaction().clone().with_city_founding_draft(None)
    } else {
        state.interaction().clone()
    };
    Ok(CityMutation::Update(Box::new(CityUpdate {
        revision,
        units,
        cities: state.cities().to_vec(),
        interaction,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
    })))
}

pub(crate) fn apply_toggle_worked_hex(
    state: &GameState,
    context: EngineContext<'_>,
    command: ToggleWorkedHexCommand<'_>,
) -> Result<CityMutation, CityRuleError> {
    validate_revision(state, command.expected_revision())?;
    let city = validate_city_control(state, context, command.city_id())?;
    if command.target() == city.center() || !city.controlled_hexes().contains(&command.target()) {
        return Err(CommandRejectionCode::WorkedHexUnavailable.into());
    }
    let limit = context.ruleset().city().worked_hex_limit(city.population());
    let mut selected = normalized_manual_hexes(city, limit);
    if let Ok(index) = selected.binary_search(&command.target()) {
        selected.remove(index);
    } else {
        if selected.len() >= usize::try_from(limit).unwrap_or(usize::MAX) {
            return Err(CommandRejectionCode::WorkedHexLimitReached.into());
        }
        selected.push(command.target());
        selected.sort_unstable();
    }
    let revision = next_revision(state)?;
    let mut cities = state.cities().to_vec();
    replace_city(&mut cities, city.with_worked_hexes(selected));
    Ok(unchanged_environment_update(state, revision, cities))
}

pub(crate) fn apply_select_expansion(
    state: &GameState,
    context: EngineContext<'_>,
    command: SelectCityExpansionHexCommand<'_>,
) -> Result<CityMutation, CityRuleError> {
    validate_revision(state, command.expected_revision())?;
    let city = validate_city_control(state, context, command.city_id())?;
    let candidates = expansion_candidates(state, context, city, state.cities())?;
    if !candidates
        .iter()
        .any(|candidate| candidate.coordinate() == command.target())
    {
        return Err(CommandRejectionCode::CityExpansionHexUnavailable.into());
    }
    if city.preferred_expansion_hex() == Some(command.target()) {
        return Ok(CityMutation::Identity);
    }
    let revision = next_revision(state)?;
    let mut cities = state.cities().to_vec();
    replace_city(
        &mut cities,
        city.with_preferred_expansion_hex(Some(command.target())),
    );
    Ok(unchanged_environment_update(state, revision, cities))
}

pub(crate) fn query_founding(
    state: &GameState,
    context: EngineContext<'_>,
    query: CityFoundingOptionsQuery<'_>,
) -> Result<CityFoundingOptions, CityRuleError> {
    validate_revision(state, query.expected_revision())?;
    let founder = validate_founder_start(state, context, query.founder_unit_id())?;
    let balance = context.ruleset().city();
    let mut selected = state
        .interaction()
        .city_founding_draft()
        .filter(|draft| {
            draft.unit_id() == founder.id()
                && draft.owner_player_id() == founder.owner_player_id()
                && draft.center() == founder.position()
        })
        .map_or_else(Vec::new, |draft| draft.controlled_hexes().to_vec());
    if selected.len() > usize::try_from(balance.founding_controlled_hexes()).unwrap_or(usize::MAX)
        || selected.iter().copied().collect::<BTreeSet<_>>().len() != selected.len()
        || !territory_connected(founder.position(), &selected)
        || selected.iter().any(|coordinate| {
            !valid_founding_candidate(
                founder.position(),
                *coordinate,
                state.cities(),
                context.map(),
                balance.founding_max_radius(),
            )
        })
    {
        return Err(CommandRejectionCode::CityControlledHexesInvalid.into());
    }
    selected.sort_unstable();
    let available = selectable_founding_hexes(
        founder.position(),
        &selected,
        state.cities(),
        context.map(),
        balance.founding_controlled_hexes(),
        balance.founding_max_radius(),
    );
    if selected.is_empty()
        && !can_complete_founding(
            founder.position(),
            &selected,
            state.cities(),
            context.map(),
            balance.founding_controlled_hexes(),
            balance.founding_max_radius(),
        )
    {
        return Err(CommandRejectionCode::CityControlledHexesInvalid.into());
    }
    Ok(CityFoundingOptions::new(
        founder.id().clone(),
        founder.position(),
        selected,
        available,
        balance.founding_controlled_hexes(),
        balance.founding_max_radius(),
    ))
}

pub(crate) fn query_worked_hexes(
    state: &GameState,
    context: EngineContext<'_>,
    query: CityWorkedHexOptionsQuery<'_>,
) -> Result<CityWorkedHexOptions, CityRuleError> {
    validate_revision(state, query.expected_revision())?;
    let city = validate_city_control(state, context, query.city_id())?;
    let limit = context.ruleset().city().worked_hex_limit(city.population());
    let selected = normalized_manual_hexes(city, limit);
    let effective = effective_worked_hexes(
        city,
        context.map(),
        &selected,
        limit,
        &context.ruleset().economy(),
    );
    let mut controlled = city.controlled_hexes().to_vec();
    controlled.sort_unstable();
    Ok(CityWorkedHexOptions::new(
        city.id().clone(),
        city.center(),
        controlled,
        selected,
        effective,
        limit,
    ))
}

pub(crate) fn query_expansion(
    state: &GameState,
    context: EngineContext<'_>,
    query: CityExpansionOptionsQuery<'_>,
) -> Result<CityExpansionOptions, CityRuleError> {
    validate_revision(state, query.expected_revision())?;
    let city = validate_city_control(state, context, query.city_id())?;
    let candidates = expansion_candidates(state, context, city, state.cities())?;
    let mut controlled = city.controlled_hexes().to_vec();
    controlled.sort_unstable();
    Ok(CityExpansionOptions::new(
        city.id().clone(),
        controlled,
        city.preferred_expansion_hex(),
        candidates,
    ))
}

fn validate_revision(state: &GameState, expected: u64) -> Result<(), CityRuleError> {
    if state.revision().get() == expected {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}

fn validate_city_control<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    city_id: &aonw_domain::CityId,
) -> Result<&'state City, CityRuleError> {
    let city = state
        .city(city_id)
        .ok_or(CommandRejectionCode::CityNotFound)?;
    if !context.can_act() || city.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::CityNotControlled.into());
    }
    Ok(city)
}

pub(crate) fn normalized_manual_hexes(city: &City, limit: u32) -> Vec<HexCoord> {
    let mut selected = city
        .worked_hexes()
        .iter()
        .copied()
        .filter(|coordinate| *coordinate != city.center() && city.controls(*coordinate))
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();
    selected.truncate(usize::try_from(limit).unwrap_or(usize::MAX));
    selected
}

pub(crate) fn effective_worked_hexes(
    city: &City,
    map: &MapDefinition,
    selected: &[HexCoord],
    limit: u32,
    economy: &aonw_content::EconomyBalance,
) -> Vec<HexCoord> {
    let limit = usize::try_from(limit).unwrap_or(usize::MAX);
    let mut effective = selected.to_vec();
    if effective.len() >= limit {
        return effective;
    }
    let selected = selected.iter().copied().collect::<BTreeSet<_>>();
    let mut candidates = city
        .controlled_hexes()
        .iter()
        .copied()
        .filter(|coordinate| !selected.contains(coordinate))
        .map(|coordinate| {
            (
                coordinate,
                map.tile_at(coordinate)
                    .map_or(i32::MIN, |tile| worked_score(tile, economy)),
            )
        })
        .collect::<Vec<_>>();
    candidates
        .sort_unstable_by(|left, right| right.1.cmp(&left.1).then_with(|| left.0.cmp(&right.0)));
    effective.extend(
        candidates
            .into_iter()
            .take(limit.saturating_sub(effective.len()))
            .map(|candidate| candidate.0),
    );
    effective.sort_unstable();
    effective
}

pub(crate) fn expansion_after_growth(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    cities: &[City],
) -> Result<Option<HexCoord>, CityRuleError> {
    let candidates = expansion_candidates(state, context, city, cities)?;
    Ok(city
        .preferred_expansion_hex()
        .and_then(|preferred| {
            candidates
                .iter()
                .any(|candidate| candidate.coordinate() == preferred)
                .then_some(preferred)
        })
        .or_else(|| candidates.first().map(|candidate| candidate.coordinate())))
}

fn expansion_candidates(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    cities: &[City],
) -> Result<Vec<CityExpansionCandidate>, CityRuleError> {
    let technology_bonus = match state.research().players().get(city.owner_player_id()) {
        Some(research) => {
            TechnologyUnlockQuery::new(context.ruleset(), research)
                .effect_summary()
                .map_err(CityRuleError::Technology)?
                .max_controlled_hexes_bonus
        }
        None => 0,
    };
    let maximum = city.max_hexes().saturating_add(i64::from(technology_bonus));
    if i64::try_from(city.territory_hex_count()).unwrap_or(i64::MAX) >= maximum {
        return Ok(Vec::new());
    }
    let mut seen = BTreeSet::new();
    let mut candidates = Vec::new();
    for owned in std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied()) {
        for target in owned.neighbors() {
            if !seen.insert(target) || !can_claim_expansion(city, target, cities, context.map()) {
                continue;
            }
            let tile = context
                .map()
                .tile_at(target)
                .expect("claimable expansion has map tile");
            candidates.push(CityExpansionCandidate::new(
                target,
                expansion_score(tile, &context.ruleset().economy()),
                u32::try_from(city.center().distance_to(target)).unwrap_or(u32::MAX),
            ));
        }
    }
    candidates.sort_unstable_by(|left, right| {
        right
            .score()
            .cmp(&left.score())
            .then_with(|| left.distance().cmp(&right.distance()))
            .then_with(|| left.coordinate().cmp(&right.coordinate()))
    });
    Ok(candidates)
}

fn can_claim_expansion(
    city: &City,
    target: HexCoord,
    cities: &[City],
    map: &MapDefinition,
) -> bool {
    if map.tile_at(target).is_none()
        || city.controls(target)
        || cities.iter().any(|candidate| candidate.controls(target))
        || city.center().distance_to(target)
            > u64::try_from(city.territory_radius()).unwrap_or_default()
    {
        return false;
    }
    let territory = std::iter::once(city.center())
        .chain(city.controlled_hexes().iter().copied())
        .collect::<BTreeSet<_>>();
    if !target
        .neighbors()
        .any(|neighbor| territory.contains(&neighbor))
    {
        return false;
    }
    let distance = city.center().distance_to(target);
    if distance <= 1 {
        return true;
    }
    target
        .neighbors()
        .filter(|neighbor| {
            city.controlled_hexes().contains(neighbor)
                && city.center().distance_to(*neighbor) == distance.saturating_sub(1)
        })
        .take(2)
        .count()
        >= 2
}

fn next_revision(state: &GameState) -> Result<StateRevision, CityRuleError> {
    state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow.into())
}

fn replace_unit(units: &mut [Unit], replacement: Unit) {
    let index = units
        .iter()
        .position(|unit| unit.id() == replacement.id())
        .expect("validated founder remains in canonical state");
    units[index] = replacement;
}

fn replace_city(cities: &mut [City], replacement: City) {
    let index = cities
        .iter()
        .position(|city| city.id() == replacement.id())
        .expect("validated city remains in canonical state");
    cities[index] = replacement;
}

fn unchanged_environment_update(
    state: &GameState,
    revision: StateRevision,
    cities: Vec<City>,
) -> CityMutation {
    CityMutation::Update(Box::new(CityUpdate {
        revision,
        units: state.units().to_vec(),
        cities,
        interaction: state.interaction().clone(),
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
    }))
}
