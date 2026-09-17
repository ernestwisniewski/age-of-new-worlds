use aonw_content::{
    BuildingProductionDefinition, ProductionRequirement, WonderProductionDefinition,
};
use aonw_domain::{City, CityProductionTarget, GameState, UnitKind};

use super::details_model::{
    BuildingProductionDetails, ProductionCityOutput, ProductionDetails, ProductionDetailsQuery,
    ProductionRequirementStatus, ProductionTargetEffects, UnitProductionDetails,
    WonderProductionDetails,
};
use super::options::{building_option, unit_option, wonder_option};
use super::rules::{presence_resource_available, requirement_met, unit_has_required_coast};
use super::supply::unit_supply_budget;
use super::support::{controlled_city, invalid, technology_for, validate_revision};
use super::yield_rules::ProductionRates;
use super::{ProductionAvailability, ProductionError, ProductionOption};
use crate::{EngineContext, GameEngine};

impl GameEngine {
    /// Inspects one target using the same owner, revision and rule checks as production.
    /// Unavailable targets remain inspectable without disclosing any foreign city.
    ///
    /// # Errors
    ///
    /// Rejects stale revisions, uncontrolled cities and invalid or overflowing content.
    pub fn production_details(
        state: &GameState,
        context: EngineContext<'_>,
        query: ProductionDetailsQuery<'_>,
    ) -> Result<ProductionDetails, ProductionError> {
        validate_revision(state, query.city.expected_revision())?;
        let city = controlled_city(state, context, query.city.city_id())?;
        let rates = ProductionRates::prepare(state, context, city)?;
        let (option, effects) = inspect_target(state, context, city, query.target, &rates)?;
        Ok(ProductionDetails {
            revision: state.revision().get(),
            city_id: city.id().clone(),
            option,
            effects,
        })
    }
}

fn inspect_target(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
    rates: &ProductionRates,
) -> Result<(ProductionOption, ProductionTargetEffects), ProductionError> {
    let balance = context.ruleset().production();
    let technology = technology_for(state, context, city);
    match target {
        CityProductionTarget::Building(building) => {
            let definition = balance
                .building(building)
                .ok_or_else(|| invalid("unknown building content"))?;
            Ok((
                building_option(state, context, city, technology, definition, rates)?,
                ProductionTargetEffects::Building(building_details(
                    state, context, city, definition,
                )?),
            ))
        }
        CityProductionTarget::Unit(unit) => unit_details(state, context, city, unit, rates),
        CityProductionTarget::Wonder(wonder) => {
            let definition = balance
                .wonder(wonder)
                .ok_or_else(|| invalid("unknown wonder content"))?;
            Ok((
                wonder_option(state, context, city, technology, definition, rates)?,
                ProductionTargetEffects::Wonder(wonder_details(state, context, city, definition)),
            ))
        }
        CityProductionTarget::Project(_) => Ok((
            ProductionOption::new(
                target,
                0,
                None,
                super::forecast::forecast(state, context, city, target, 0, rates)?,
                ProductionAvailability::for_target(city, technology, target),
            ),
            ProductionTargetEffects::Project,
        )),
    }
}

fn building_details(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    definition: BuildingProductionDefinition,
) -> Result<BuildingProductionDetails, ProductionError> {
    let current = city_output(state, context, city)?;
    let completed = if city.buildings().contains(&definition.building()) {
        current
    } else {
        let completed_city = city
            .try_with_completed_building(
                definition.building(),
                definition.max_controlled_hexes_delta(),
            )
            .map_err(|error| invalid(error.to_string()))?;
        city_output(state, context, &completed_city)?
    };
    let river_count = crate::economy::city_river_hex_count(context, city);
    let river_applications =
        u32::try_from(river_count.min(definition.max_river_applications() as usize))
            .map_err(|error| invalid(error.to_string()))?;
    Ok(BuildingProductionDetails {
        requirements: requirements(state, context, city, definition.requirements()),
        flat_yield: definition.yield_delta(),
        river_yield_per_hex: definition.river_yield_per_hex(),
        max_river_applications: definition.max_river_applications(),
        river_applications,
        science_per_turn: definition.science_per_turn(),
        max_controlled_hexes_delta: definition.max_controlled_hexes_delta(),
        food_deposit_basis_points: definition.food_deposit_basis_points(),
        current,
        completed,
    })
}

fn city_output(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<ProductionCityOutput, ProductionError> {
    let output = crate::economy::city_turn_output(state, context, city)
        .map_err(|error| invalid(error.to_string()))?;
    Ok(ProductionCityOutput {
        gross_yield: output.gross_yield,
        food_deposit: output.food_deposit,
        production: output.production,
        gold: output.gold,
        science: crate::research::passive_city_science(state, context, city)
            .map_err(|error| invalid(error.to_string()))?,
        max_controlled_hexes: crate::city::territory_capacity(state, context, city)
            .map_err(|error| invalid(format!("{error:?}")))?,
    })
}

fn requirements(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    requirements: &[ProductionRequirement],
) -> Box<[ProductionRequirementStatus]> {
    let technology = technology_for(state, context, city);
    requirements
        .iter()
        .copied()
        .map(|requirement| ProductionRequirementStatus {
            requirement,
            met: requirement_met(state, context, city, technology, requirement),
        })
        .collect()
}

fn unit_details(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    kind: UnitKind,
    rates: &ProductionRates,
) -> Result<(ProductionOption, ProductionTargetEffects), ProductionError> {
    let definition = context
        .ruleset()
        .production()
        .unit(kind)
        .ok_or_else(|| invalid("unknown unit production content"))?;
    let unit = context
        .ruleset()
        .unit(kind)
        .ok_or_else(|| invalid("unknown unit content"))?;
    let supply = unit_supply_budget(state, context, city)?;
    let option = unit_option(
        state,
        context,
        city,
        technology_for(state, context, city),
        &supply,
        definition,
        rates,
    )?;
    let effects = UnitProductionDetails {
        base_combat: unit.combat(),
        effective_combat: crate::combat::new_unit_stats(
            state,
            context.ruleset(),
            city.owner_player_id(),
            kind,
        )
        .ok_or_else(|| invalid("unit combat statistics overflow"))?,
        maximum_movement: crate::maximum_movement_units(context.ruleset(), kind, false),
        base_upkeep: definition.upkeep(),
        supply_cost: definition.supply_cost(),
        supply_capacity: supply.capacity(),
        supply_used_without_city_queue: supply.used(),
        presence_resources: definition.presence_resources(),
        presence_resources_met: presence_resource_available(
            state,
            context,
            city.owner_player_id(),
            definition,
        ),
        coast_met: unit_has_required_coast(context, city, kind),
        resource_options: option.resource_options().into(),
        affordable_resource_option_indices: option.affordable_resource_option_indices().into(),
    };
    Ok((option.option(), ProductionTargetEffects::Unit(effects)))
}

fn wonder_details(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    definition: WonderProductionDefinition,
) -> WonderProductionDetails {
    WonderProductionDetails {
        requirements: requirements(state, context, city, definition.requirements()),
        host_yield: definition.host_yield(),
        empire_yield_per_city: definition.empire_yield_per_city(),
        empire_science_per_city: definition.empire_science_per_city(),
        empire_gold_basis_points: definition.empire_gold_basis_points(),
        empire_production_basis_points: definition.empire_production_basis_points(),
        stability_delta: definition.stability_delta(),
        grants_free_active_technology: definition.grants_free_active_technology(),
        production_burst: definition.production_burst(),
        grant_gold: definition.grant_gold(),
    }
}
