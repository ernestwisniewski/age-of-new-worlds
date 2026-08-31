use aonw_content::UnitProductionDefinition;
use aonw_domain::{City, CityProductionTarget, GameState};

use super::ProductionError;
use super::support::invalid;
use crate::EngineContext;
use crate::economy::rules::query_city_yield;
use crate::movement::{MovementCost, terrain_entry_cost};

pub(super) struct UnitSupplyBudget {
    capacity: i64,
    used: i64,
}

impl UnitSupplyBudget {
    pub(super) fn permits(
        &self,
        requested: UnitProductionDefinition,
    ) -> Result<bool, ProductionError> {
        self.used
            .checked_add(requested.supply_cost())
            .map(|used| used <= self.capacity)
            .ok_or_else(|| invalid("requested supply overflow"))
    }
}

pub(super) fn unit_supply_budget(
    state: &GameState,
    context: EngineContext<'_>,
    replacing_city: &City,
) -> Result<UnitSupplyBudget, ProductionError> {
    let player = replacing_city.owner_player_id();
    let raw_capacity = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .try_fold(0_i64, |total, city| {
            let yield_value = query_city_yield(
                state,
                context,
                crate::CityYieldQuery::new(state.revision().get(), city.id()),
            )
            .map_err(|error| invalid(error.to_string()))?
            .total();
            let city_supply = city
                .population()
                .checked_add(yield_value.food)
                .ok_or_else(|| invalid("city supply overflow"))?
                .max(0);
            total
                .checked_add(city_supply)
                .ok_or_else(|| invalid("player supply overflow"))
        })?;
    let capacity = raw_capacity.min(map_supply_capacity(context)?);
    let unit_supply = state
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() == player)
        .try_fold(0_i64, |total, unit| {
            let cost = context
                .ruleset()
                .production()
                .unit(unit.kind())
                .map_or(0, UnitProductionDefinition::supply_cost);
            total
                .checked_add(cost)
                .ok_or_else(|| invalid("unit supply overflow"))
        })?;
    let queued_supply = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player && city.id() != replacing_city.id())
        .filter_map(|city| city.production_queue())
        .filter_map(|queue| match queue.target() {
            CityProductionTarget::Unit(unit) => Some(unit),
            CityProductionTarget::Building(_)
            | CityProductionTarget::Project(_)
            | CityProductionTarget::Wonder(_) => None,
        })
        .try_fold(0_i64, |total, unit| {
            let cost = context
                .ruleset()
                .production()
                .unit(unit)
                .map_or(0, UnitProductionDefinition::supply_cost);
            total
                .checked_add(cost)
                .ok_or_else(|| invalid("queued supply overflow"))
        })?;
    let used = unit_supply
        .checked_add(queued_supply)
        .ok_or_else(|| invalid("requested supply overflow"))?;
    Ok(UnitSupplyBudget { capacity, used })
}

fn map_supply_capacity(context: EngineContext<'_>) -> Result<i64, ProductionError> {
    let domain = aonw_domain::UnitMovementDomain::Land;
    let land = context.compiled_movement_map().map_or_else(
        || {
            context
                .map()
                .tiles()
                .iter()
                .filter(|tile| {
                    matches!(terrain_entry_cost(tile, domain), MovementCost::Passable(_))
                })
                .count()
        },
        |compiled| compiled.passable_tile_count(domain),
    );
    let land = i64::try_from(land).map_err(|_| invalid("map land count overflow"))?;
    let players = match context.map().map_id().trim().to_ascii_lowercase().as_str() {
        "verdantia" | "dravonia" => 4_i64,
        "myranth" | "terenos" => 3_i64,
        _ if context.map().tiles().len() >= 540 => 4_i64,
        _ if context.map().tiles().len() >= 220 => 3_i64,
        _ => 2_i64,
    };
    let (density_numerator, density_denominator) = context.ruleset().production().supply_density();
    let denominator = players
        .checked_mul(i64::from(density_denominator))
        .ok_or_else(|| invalid("map supply denominator overflow"))?;
    let numerator = land
        .checked_mul(i64::from(density_numerator))
        .ok_or_else(|| invalid("map supply numerator overflow"))?;
    let rounded = numerator
        .checked_add(denominator / 2)
        .and_then(|value| value.checked_div(denominator))
        .ok_or_else(|| invalid("map supply rounding overflow"))?;
    let (minimum, maximum) = context.ruleset().production().map_supply_bounds();
    Ok(rounded.clamp(minimum, maximum))
}
