mod city_output;
mod stability;

use core::fmt;
use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, CityId, EconomyAccountChange, GameState, PlayerId, ProductionStateUpdate, UnitKind,
};

use crate::{CityClaimedHexEvent, DomainEvent, EngineContext};

use super::{UnitUpkeepBreakdown, UnitUpkeepSource};

pub(crate) use city_output::city_turn_output;
pub(crate) use stability::{
    CombatEconomyOwnerIndex, WarWearinessEventCounts, advance_turn_stability,
    current_stability_breakdown,
};

pub(crate) struct PreparedEconomyTurn {
    pub(crate) state: GameState,
    pub(crate) production_by_city: BTreeMap<CityId, i64>,
    pub(crate) gold_by_player: BTreeMap<PlayerId, i64>,
    pub(crate) city_events_by_city: BTreeMap<CityId, Vec<DomainEvent>>,
}

/// Failure from deterministic per-turn economy progression.
#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct EconomyTurnError(Box<str>);

impl EconomyTurnError {
    pub(super) fn new(value: impl fmt::Display) -> Self {
        Self(value.to_string().into())
    }
}

impl fmt::Display for EconomyTurnError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for EconomyTurnError {}

pub(crate) fn prepare_turn_economy(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
    attacked_city_ids: &BTreeSet<CityId>,
) -> Result<PreparedEconomyTurn, EconomyTurnError> {
    let economy = credit_strategic_resources(&state, map, ruleset, scope)?;
    let mut cities = state.cities().to_vec();
    let mut production_by_city = BTreeMap::new();
    let mut gold_by_player = BTreeMap::<PlayerId, i64>::new();
    let mut city_events_by_city = BTreeMap::<CityId, Vec<DomainEvent>>::new();
    for player in scope {
        let context = EngineContext::canonical(player, map, ruleset);
        for index in 0..cities.len() {
            let city = cities[index].clone();
            if city.owner_player_id() != player {
                continue;
            }
            let output = city_turn_output(&state, context, &city)?;
            production_by_city.insert(city.id().clone(), output.production);
            let gold = gold_by_player.entry(player.clone()).or_default();
            *gold = gold
                .checked_add(output.gold)
                .ok_or_else(|| EconomyTurnError::new("city gold total overflow"))?;
            let (grown, claimed) = grow_city(&state, context, &city, &cities, output)?;
            let grown = recover_city_hit_points(&state, ruleset, grown, attacked_city_ids)?;
            if let Some(coordinate) = claimed {
                city_events_by_city
                    .entry(grown.id().clone())
                    .or_default()
                    .push(DomainEvent::CityClaimedHex(CityClaimedHexEvent::new(
                        grown.id().clone(),
                        coordinate,
                    )));
            }
            cities[index] = grown;
        }
    }
    let state = replace_production_sections(state, cities, economy)?;
    Ok(PreparedEconomyTurn {
        state,
        production_by_city,
        gold_by_player,
        city_events_by_city,
    })
}

fn recover_city_hit_points(
    state: &GameState,
    ruleset: &RulesetDefinition,
    city: City,
    attacked_city_ids: &BTreeSet<CityId>,
) -> Result<City, EconomyTurnError> {
    if attacked_city_ids.contains(city.id()) {
        return Ok(city);
    }
    let maximum = crate::combat::city_max_hit_points(state, ruleset, &city)
        .ok_or_else(|| EconomyTurnError::new("city combat health is unavailable"))?;
    let current = city.hit_points().unwrap_or(maximum).clamp(0, maximum);
    if current >= maximum {
        return Ok(city);
    }
    let recovered = current
        .checked_add(1)
        .ok_or_else(|| EconomyTurnError::new("city hit-point recovery overflow"))?;
    let stored = (recovered < maximum).then_some(recovered);
    let owner = city.owner_player_id().clone();
    Ok(city.after_combat(owner, stored))
}

pub(crate) fn settle_turn_income_and_upkeep(
    state: GameState,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
    gold_by_player: &BTreeMap<PlayerId, i64>,
) -> Result<GameState, EconomyTurnError> {
    let mut changes = Vec::new();
    for player in scope {
        let income = gold_by_player.get(player).copied().unwrap_or_default();
        let upkeep = unit_upkeep_breakdown(&state, ruleset, player)?.total();
        let current = state
            .economy()
            .player_gold()
            .get(player)
            .copied()
            .unwrap_or_default();
        let raw = current
            .checked_add(income)
            .and_then(|value| value.checked_sub(upkeep))
            .ok_or_else(|| EconomyTurnError::new("player gold settlement overflow"))?;
        let next = raw.max(0);
        let delta = next
            .checked_sub(current)
            .ok_or_else(|| EconomyTurnError::new("player gold delta overflow"))?;
        if delta != 0 {
            changes.push(EconomyAccountChange::Gold {
                player: player.clone(),
                delta,
            });
        }
    }
    let economy = state
        .economy()
        .try_after_changes(state.match_lifecycle().identity(), state.bounds(), changes)
        .map_err(EconomyTurnError::new)?;
    let cities = state.cities().to_vec();
    replace_production_sections(state, cities, economy)
}

fn credit_strategic_resources(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<aonw_domain::EconomyState, EconomyTurnError> {
    let mut changes = Vec::new();
    for player in scope {
        let projection = super::rules::strategic_resource_projection_for_player(
            state,
            EngineContext::canonical(player, map, ruleset),
            player,
        )
        .map_err(EconomyTurnError::new)?;
        changes.extend(projection.output().iter().filter_map(|(resource, amount)| {
            (*amount > 0).then_some(EconomyAccountChange::StrategicResource {
                player: player.clone(),
                resource: *resource,
                delta: *amount,
            })
        }));
    }
    state
        .economy()
        .try_after_changes(state.match_lifecycle().identity(), state.bounds(), changes)
        .map_err(EconomyTurnError::new)
}

fn grow_city(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    cities: &[City],
    output: city_output::CityTurnOutput,
) -> Result<(City, Option<aonw_domain::HexCoord>), EconomyTurnError> {
    let stored = city
        .stored_food()
        .checked_add(output.food_deposit)
        .ok_or_else(|| EconomyTurnError::new("city stored food overflow"))?;
    let grew = stored >= output.growth_cost;
    let population = if grew {
        city.population()
            .checked_add(1)
            .ok_or_else(|| EconomyTurnError::new("city population overflow"))?
    } else {
        city.population()
    };
    let stored = if grew {
        stored
            .checked_sub(output.growth_cost)
            .ok_or_else(|| EconomyTurnError::new("city stored food underflow"))?
    } else {
        stored
    };
    let city_balance = context.ruleset().city();
    let mut max_hexes = city.max_hexes();
    let mut radius = city.territory_radius();
    if population >= 10 {
        max_hexes = max_hexes.max(city_balance.late_game_max_hexes());
        radius = radius.max(city_balance.expanded_territory_radius());
    } else if population >= 6 {
        max_hexes = max_hexes.max(city_balance.mid_game_max_hexes());
    }
    let progressed = city
        .try_after_growth(population, stored, max_hexes, radius, None)
        .map_err(EconomyTurnError::new)?;
    let claimed = if grew {
        crate::city::expansion_after_growth(state, context, &progressed, cities)
            .map_err(|error| EconomyTurnError::new(format_args!("{error:?}")))?
    } else {
        None
    };
    let grown = progressed
        .try_after_growth(population, stored, max_hexes, radius, claimed)
        .map_err(EconomyTurnError::new)?;
    Ok((grown, claimed))
}

pub(crate) fn unit_upkeep_breakdown(
    state: &GameState,
    ruleset: &RulesetDefinition,
    player: &PlayerId,
) -> Result<UnitUpkeepBreakdown, EconomyTurnError> {
    let city_count = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .count();
    let free_unit_count = ruleset
        .economy()
        .free_unit_count(city_count)
        .ok_or_else(|| EconomyTurnError::new("free unit count overflow"))?;
    let free = usize::try_from(free_unit_count).map_err(EconomyTurnError::new)?;
    let mut units = state
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() == player)
        .filter_map(|unit| {
            ruleset
                .production()
                .unit(unit.kind())
                .map(|definition| (unit, definition.upkeep()))
        })
        .filter(|(_, upkeep)| *upkeep > 0)
        .collect::<Vec<_>>();
    units.sort_unstable_by(|(left, left_cost), (right, right_cost)| {
        right_cost
            .cmp(left_cost)
            .then_with(|| left.kind().cmp(&right.kind()))
            .then_with(|| left.id().cmp(right.id()))
    });
    let upkeep_bearing_unit_count = i64::try_from(units.len()).map_err(EconomyTurnError::new)?;
    let mut total = 0_i64;
    let mut paid_unit_count = 0_i64;
    let mut paid_workers = 0_i64;
    let mut by_kind = BTreeMap::<UnitKind, (i64, i64)>::new();
    for (unit, base) in units.into_iter().skip(free) {
        let cost = if unit.kind() == UnitKind::Worker {
            paid_workers = paid_workers
                .checked_add(1)
                .ok_or_else(|| EconomyTurnError::new("worker upkeep overflow"))?;
            paid_workers
        } else {
            base
        };
        total = total
            .checked_add(cost)
            .ok_or_else(|| EconomyTurnError::new("unit upkeep overflow"))?;
        paid_unit_count = paid_unit_count
            .checked_add(1)
            .ok_or_else(|| EconomyTurnError::new("paid unit count overflow"))?;
        let group = by_kind.entry(unit.kind()).or_default();
        group.0 = group
            .0
            .checked_add(1)
            .ok_or_else(|| EconomyTurnError::new("paid unit type count overflow"))?;
        group.1 = group
            .1
            .checked_add(cost)
            .ok_or_else(|| EconomyTurnError::new("unit type upkeep overflow"))?;
    }
    let next_worker_upkeep = if upkeep_bearing_unit_count < free_unit_count {
        0
    } else {
        paid_workers
            .checked_add(1)
            .ok_or_else(|| EconomyTurnError::new("next worker upkeep overflow"))?
    };
    let sources = by_kind
        .into_iter()
        .map(|(kind, (count, amount))| UnitUpkeepSource::new(kind, count, amount))
        .collect();
    Ok(UnitUpkeepBreakdown::new(
        upkeep_bearing_unit_count,
        free_unit_count,
        paid_unit_count,
        total,
        next_worker_upkeep,
        sources,
    ))
}

fn replace_production_sections(
    state: GameState,
    cities: Vec<City>,
    economy: aonw_domain::EconomyState,
) -> Result<GameState, EconomyTurnError> {
    let update = ProductionStateUpdate {
        revision: state.revision(),
        units: state.units().to_vec(),
        cities,
        economy,
        knowledge: state.knowledge().clone(),
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
    };
    state
        .into_after_production(update)
        .map_err(EconomyTurnError::new)
}
