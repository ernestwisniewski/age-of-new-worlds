use aonw_domain::{City, CitySpecializationType, GameState};

use crate::{CityYieldQuery, EngineContext, TechnologyUnlockQuery, YieldValue};

use super::EconomyTurnError;

const BASIS_POINTS: i64 = 10_000;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) struct CityTurnOutput {
    pub(crate) food_deposit: i64,
    pub(crate) growth_cost: i64,
    pub(crate) gold: i64,
    pub(crate) production: i64,
}

pub(crate) fn city_turn_output(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<CityTurnOutput, EconomyTurnError> {
    let tile = crate::economy::query_city_yield(
        state,
        context,
        CityYieldQuery::new(state.revision().get(), city.id()),
    )
    .map_err(error)?
    .total();
    let building = building_yield(context, city)?;
    let (wonder, wonder_gold, wonder_production) = wonder_yield(state, context, city)?;
    let specialization = specialization_yield(city.specialization());
    let (technology, technology_gold) = technology_yield(state, context, city)?;
    let gross = checked_sum([tile, building, wonder, specialization, technology])?;
    let gold = add_scaled(gross.gold, technology_gold)?;
    let gold = add_scaled(gold, wonder_gold)?;
    let stability = state
        .economy()
        .player_stability_net()
        .get(city.owner_player_id())
        .copied()
        .unwrap_or_default();
    let modifier = context.ruleset().economy().stability_modifier(stability);
    let gold = scale_floor(gold, i64::from(modifier.gold_basis_points()))?.max(0);
    let production = scale_floor(
        gross.production.max(0),
        i64::from(modifier.production_basis_points()),
    )?;
    let production = add_scaled(production, wonder_production)?;
    let population_food = context
        .ruleset()
        .economy()
        .food_upkeep_per_population()
        .checked_mul(city.population())
        .ok_or_else(|| error("population food upkeep overflow"))?;
    let net_food = gross
        .food
        .checked_sub(population_food)
        .ok_or_else(|| error("city food calculation overflow"))?
        .max(0);
    let food_deposit = if modifier.halts_growth() {
        0
    } else {
        food_after_buildings(context, city, net_food)?
            .checked_add(modifier.food_bonus())
            .ok_or_else(|| error("city food deposit overflow"))?
    };
    let pace = state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile();
    let growth_cost = context
        .ruleset()
        .economy()
        .paced_growth_cost(city.population(), city.territory_hex_count(), pace)
        .ok_or_else(|| error("city growth cost overflow"))?;
    Ok(CityTurnOutput {
        food_deposit,
        growth_cost,
        gold,
        production,
    })
}

fn building_yield(context: EngineContext<'_>, city: &City) -> Result<YieldValue, EconomyTurnError> {
    let river_count = territory(city)
        .filter(|coordinate| {
            context.map().tile_at(*coordinate).is_some_and(|tile| {
                tile.terrain_tags()
                    .contains(&aonw_content::TerrainType::River)
            })
        })
        .count();
    city.buildings()
        .iter()
        .try_fold(YieldValue::default(), |total, building| {
            let definition = context
                .ruleset()
                .production()
                .building(*building)
                .ok_or_else(|| error("completed building is absent from production content"))?;
            let applications = river_count.min(definition.max_river_applications() as usize);
            let river = scale_whole(
                from_content(definition.river_yield_per_hex()),
                i64::try_from(applications).map_err(error)?,
            )?;
            checked_add(total, from_content(definition.yield_delta()))
                .and_then(|value| checked_add(value, river))
        })
}

fn wonder_yield(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<(YieldValue, u32, u32), EconomyTurnError> {
    let registry = state.wonder_registry().completed_by();
    let mut value = YieldValue::default();
    let mut gold = 0_u32;
    let mut production = 0_u32;
    for (wonder, owner) in registry {
        if owner != city.owner_player_id() {
            continue;
        }
        let definition = context
            .ruleset()
            .production()
            .wonder(*wonder)
            .ok_or_else(|| error("completed wonder is absent from production content"))?;
        value = checked_add(value, from_content(definition.empire_yield_per_city()))?;
        if state
            .cities()
            .iter()
            .find(|candidate| candidate.wonders().contains(wonder))
            .is_some_and(|host| host.id() == city.id())
        {
            value = checked_add(value, from_content(definition.host_yield()))?;
        }
        gold = gold
            .checked_add(definition.empire_gold_basis_points())
            .ok_or_else(|| error("wonder gold multiplier overflow"))?;
        production = production
            .checked_add(definition.empire_production_basis_points())
            .ok_or_else(|| error("wonder production multiplier overflow"))?;
    }
    Ok((value, gold, production))
}

fn technology_yield(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<(YieldValue, u32), EconomyTurnError> {
    let empty = aonw_domain::PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(city.owner_player_id())
        .unwrap_or(&empty);
    let effects = TechnologyUnlockQuery::new(context.ruleset(), research)
        .effect_summary()
        .map_err(error)?;
    let production = territory(city).try_fold(0_i64, |total, coordinate| {
        crate::economy::rules::resources_at(state, context, coordinate)
            .into_iter()
            .try_fold(total, |sum, resource| {
                sum.checked_add(i64::from(
                    effects
                        .strategic_resource_production
                        .get(&resource)
                        .copied()
                        .unwrap_or_default(),
                ))
                .ok_or_else(|| error("technology production overflow"))
            })
    })?;
    Ok((
        YieldValue::new(0, production, 0, i64::from(effects.city_defense_bonus)),
        effects.global_gold_multiplier_basis_points,
    ))
}

fn food_after_buildings(
    context: EngineContext<'_>,
    city: &City,
    mut food: i64,
) -> Result<i64, EconomyTurnError> {
    for building in city.buildings() {
        let basis_points = context
            .ruleset()
            .production()
            .building(*building)
            .ok_or_else(|| error("completed building is absent from production content"))?
            .food_deposit_basis_points();
        food = scale_floor(food, i64::from(basis_points))?;
    }
    Ok(food)
}

const fn specialization_yield(value: Option<CitySpecializationType>) -> YieldValue {
    match value {
        Some(CitySpecializationType::Growth) => YieldValue::new(2, 0, 0, 0),
        Some(CitySpecializationType::Industry) => YieldValue::new(0, 2, 0, 0),
        Some(CitySpecializationType::Commerce) => YieldValue::new(0, 0, 3, 0),
        Some(CitySpecializationType::Military) => YieldValue::new(0, 1, 0, 2),
        Some(CitySpecializationType::Science) | None => YieldValue::new(0, 0, 0, 0),
    }
}

fn territory(city: &City) -> impl Iterator<Item = aonw_domain::HexCoord> + '_ {
    std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
}

const fn from_content(value: aonw_content::EconomyYield) -> YieldValue {
    YieldValue::new(
        value.food(),
        value.production(),
        value.gold(),
        value.defense(),
    )
}

fn checked_sum(
    values: impl IntoIterator<Item = YieldValue>,
) -> Result<YieldValue, EconomyTurnError> {
    values
        .into_iter()
        .try_fold(YieldValue::default(), checked_add)
}

fn checked_add(left: YieldValue, right: YieldValue) -> Result<YieldValue, EconomyTurnError> {
    Ok(YieldValue::new(
        left.food
            .checked_add(right.food)
            .ok_or_else(|| error("city food yield overflow"))?,
        left.production
            .checked_add(right.production)
            .ok_or_else(|| error("city production yield overflow"))?,
        left.gold
            .checked_add(right.gold)
            .ok_or_else(|| error("city gold yield overflow"))?,
        left.defense
            .checked_add(right.defense)
            .ok_or_else(|| error("city defense yield overflow"))?,
    ))
}

fn scale_whole(value: YieldValue, multiplier: i64) -> Result<YieldValue, EconomyTurnError> {
    Ok(YieldValue::new(
        value
            .food
            .checked_mul(multiplier)
            .ok_or_else(|| error("city food yield overflow"))?,
        value
            .production
            .checked_mul(multiplier)
            .ok_or_else(|| error("city production yield overflow"))?,
        value
            .gold
            .checked_mul(multiplier)
            .ok_or_else(|| error("city gold yield overflow"))?,
        value
            .defense
            .checked_mul(multiplier)
            .ok_or_else(|| error("city defense yield overflow"))?,
    ))
}

fn add_scaled(value: i64, basis_points: u32) -> Result<i64, EconomyTurnError> {
    value
        .checked_add(scale_floor(value, i64::from(basis_points))?)
        .ok_or_else(|| error("city multiplier overflow"))
}

fn scale_floor(value: i64, basis_points: i64) -> Result<i64, EconomyTurnError> {
    value
        .checked_mul(basis_points)
        .and_then(|numerator| numerator.checked_div(BASIS_POINTS))
        .ok_or_else(|| error("city multiplier overflow"))
}

fn error(value: impl core::fmt::Display) -> EconomyTurnError {
    EconomyTurnError::new(value)
}
