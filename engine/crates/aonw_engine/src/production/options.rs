use aonw_content::UnitProductionDefinition;
use aonw_domain::{
    City, CityProductionQueue, CityProductionTarget, CityProjectType, CitySpecializationType,
    GameState,
};

use super::ProductionError;
use super::forecast::forecast;
use super::model::{
    CitySpecializationOption, ProductionOption, ProductionOptions, ProductionOptionsQuery,
    UnitProductionOption,
};
use super::rules::{building_rejection, evaluate_unit, specialization_rejection, wonder_rejection};
use super::supply::{UnitSupplyBudget, unit_supply_budget};
use super::support::{controlled_city, invalid, pace, technology_for, validate_revision};
use super::yield_rules::ProductionRates;
use crate::{EngineContext, TechnologyUnlockQuery};

const SPECIALIZATIONS: [CitySpecializationType; 5] = [
    CitySpecializationType::Growth,
    CitySpecializationType::Industry,
    CitySpecializationType::Commerce,
    CitySpecializationType::Science,
    CitySpecializationType::Military,
];
const PROJECTS: [CityProjectType; 2] = [CityProjectType::Wealth, CityProjectType::Research];

pub(crate) fn query_options(
    state: &GameState,
    context: EngineContext<'_>,
    query: ProductionOptionsQuery<'_>,
) -> Result<ProductionOptions, ProductionError> {
    validate_revision(state, query.expected_revision())?;
    let city = controlled_city(state, context, query.city_id())?;
    let technology = technology_for(state, context, city);
    let rates = ProductionRates::prepare(state, context, city)?;
    let supply = unit_supply_budget(state, context, city)?;
    let production = context.ruleset().production();
    let pace = pace(state);
    let buildings = production
        .buildings()
        .iter()
        .copied()
        .map(|definition| {
            let rejection =
                building_rejection(state, context, city, technology, definition.building())?;
            let cost = production
                .building_cost(definition.base_cost(), pace)
                .ok_or_else(|| invalid("building production cost overflow"))?;
            Ok(ProductionOption::new(
                CityProductionTarget::Building(definition.building()),
                cost,
                rejection,
                forecast(
                    state,
                    context,
                    city,
                    CityProductionTarget::Building(definition.building()),
                    cost,
                    &rates,
                )?,
            ))
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let units = production
        .units()
        .iter()
        .copied()
        .map(|definition| {
            unit_option(
                state, context, city, technology, &supply, definition, &rates,
            )
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let projects = PROJECTS
        .into_iter()
        .map(|project| {
            let target = CityProductionTarget::Project(project);
            Ok(ProductionOption::new(
                target,
                0,
                None,
                forecast(state, context, city, target, 0, &rates)?,
            ))
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let wonders = production
        .wonders()
        .iter()
        .copied()
        .map(|definition| {
            let rejection =
                wonder_rejection(state, context, city, technology, definition.wonder())?;
            let cost = production
                .building_cost(definition.base_cost(), pace)
                .ok_or_else(|| invalid("wonder production cost overflow"))?;
            Ok(ProductionOption::new(
                CityProductionTarget::Wonder(definition.wonder()),
                cost,
                rejection,
                forecast(
                    state,
                    context,
                    city,
                    CityProductionTarget::Wonder(definition.wonder()),
                    cost,
                    &rates,
                )?,
            ))
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let specializations = specialization_options(context, city, technology);
    let queue = city.production_queue();
    Ok(ProductionOptions::new(
        state.revision().get(),
        city.id().clone(),
        queue.map(CityProductionQueue::target),
        queue.map_or(0, CityProductionQueue::invested_production),
        city.production_overflow(),
        super::rush_quote::quote(
            state,
            context,
            city,
            queue.map_or(Ok(0), |queue| rates.for_target(city, queue.target()))?,
        )?,
        buildings,
        units,
        projects,
        wonders,
        specializations,
    ))
}

fn specialization_options(
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
) -> Vec<CitySpecializationOption> {
    SPECIALIZATIONS
        .into_iter()
        .map(|specialization| {
            let required = context
                .ruleset()
                .production()
                .specialization_building(specialization);
            CitySpecializationOption::new(
                specialization,
                required,
                specialization_rejection(city, technology, specialization, required),
            )
        })
        .collect()
}

fn unit_option(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    supply: &UnitSupplyBudget,
    definition: UnitProductionDefinition,
    rates: &ProductionRates,
) -> Result<UnitProductionOption, ProductionError> {
    let evaluation = evaluate_unit(
        state,
        context,
        city,
        technology,
        Some(supply),
        definition,
        None,
    )?;
    let cost = context
        .ruleset()
        .production()
        .unit_cost(definition.base_cost(), pace(state))
        .ok_or_else(|| invalid("unit production cost overflow"))?;
    Ok(UnitProductionOption::new(
        ProductionOption::new(
            CityProductionTarget::Unit(definition.unit()),
            cost,
            evaluation.rejection,
            forecast(
                state,
                context,
                city,
                CityProductionTarget::Unit(definition.unit()),
                cost,
                rates,
            )?,
        ),
        evaluation.resource_options,
        evaluation.affordable_indices,
    ))
}
