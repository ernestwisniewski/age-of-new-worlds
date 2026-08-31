use aonw_domain::{
    City, CityProductionQueue, CityProductionTarget, EconomyAccountChange, GameState,
    ProductionStateUpdate, StrategicResourceStockpile,
};

use super::ProductionError;
use super::model::{
    SetCitySpecializationCommand, StartBuildingCommand, StartCityProjectCommand,
    StartUnitProductionCommand, StartWonderCommand,
};
use super::rules::{building_rejection, evaluate_unit, wonder_rejection};
use super::support::{
    controlled_city, invalid, next_revision, pace, replace_city, technology_for, validate_revision,
};
use crate::DomainEvent;
use crate::EngineContext;

/// Atomic replacement produced by one city-production command.
pub(crate) enum ProductionMutation {
    Identity,
    Update {
        update: Box<ProductionStateUpdate>,
        events: Box<[DomainEvent]>,
    },
}

impl ProductionMutation {
    pub(super) fn update(update: ProductionStateUpdate) -> Self {
        Self::Update {
            update: Box::new(update),
            events: Box::new([]),
        }
    }

    pub(super) fn with_events(update: ProductionStateUpdate, events: Vec<DomainEvent>) -> Self {
        Self::Update {
            update: Box::new(update),
            events: events.into_boxed_slice(),
        }
    }
}

pub(crate) fn apply_start_building(
    state: &GameState,
    context: EngineContext<'_>,
    command: StartBuildingCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    let technology = technology_for(state, context, city);
    if let Some(rejection) =
        building_rejection(state, context, city, technology, command.building())?
    {
        return Err(rejection.into());
    }
    let definition = context
        .ruleset()
        .production()
        .building(command.building())
        .ok_or_else(|| invalid("building is absent from production content"))?;
    let cost = context
        .ruleset()
        .production()
        .building_cost(definition.base_cost(), pace(state))
        .ok_or_else(|| invalid("building production cost overflow"))?;
    queue_target(
        state,
        city,
        CityProductionTarget::Building(command.building()),
        cost,
        &StrategicResourceStockpile::default(),
    )
}

pub(crate) fn apply_start_unit(
    state: &GameState,
    context: EngineContext<'_>,
    command: StartUnitProductionCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    let technology = technology_for(state, context, city);
    let definition = context
        .ruleset()
        .production()
        .unit(command.unit())
        .ok_or_else(|| invalid("unit is absent from production content"))?;
    let evaluation = evaluate_unit(
        state,
        context,
        city,
        technology,
        None,
        definition,
        command.resource_option_index(),
    )?;
    if let Some(rejection) = evaluation.rejection {
        return Err(rejection.into());
    }
    let allocation = evaluation
        .selected_allocation
        .ok_or_else(|| invalid("available unit option has no resource allocation"))?;
    let cost = context
        .ruleset()
        .production()
        .unit_cost(definition.base_cost(), pace(state))
        .ok_or_else(|| invalid("unit production cost overflow"))?;
    queue_target(
        state,
        city,
        CityProductionTarget::Unit(command.unit()),
        cost,
        &allocation,
    )
}

pub(crate) fn apply_start_project(
    state: &GameState,
    context: EngineContext<'_>,
    command: StartCityProjectCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    queue_target(
        state,
        city,
        CityProductionTarget::Project(command.project()),
        0,
        &StrategicResourceStockpile::default(),
    )
}

pub(crate) fn apply_start_wonder(
    state: &GameState,
    context: EngineContext<'_>,
    command: StartWonderCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    let technology = technology_for(state, context, city);
    if let Some(rejection) = wonder_rejection(state, context, city, technology, command.wonder())? {
        return Err(rejection.into());
    }
    let definition = context
        .ruleset()
        .production()
        .wonder(command.wonder())
        .ok_or_else(|| invalid("wonder is absent from production content"))?;
    let cost = context
        .ruleset()
        .production()
        .building_cost(definition.base_cost(), pace(state))
        .ok_or_else(|| invalid("wonder production cost overflow"))?;
    queue_target(
        state,
        city,
        CityProductionTarget::Wonder(command.wonder()),
        cost,
        &StrategicResourceStockpile::default(),
    )
}

pub(crate) fn apply_set_specialization(
    state: &GameState,
    context: EngineContext<'_>,
    command: SetCitySpecializationCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    let technology = technology_for(state, context, city);
    let required = context
        .ruleset()
        .production()
        .specialization_building(command.specialization());
    if let Some(rejection) =
        super::rules::specialization_rejection(city, technology, command.specialization(), required)
    {
        return Err(rejection.into());
    }
    let revision = next_revision(state)?;
    let mut cities = state.cities().to_vec();
    replace_city(
        &mut cities,
        city.with_specialization(Some(command.specialization())),
    )?;
    Ok(ProductionMutation::update(production_update(
        state,
        revision,
        cities,
        state.economy().clone(),
    )))
}

fn queue_target(
    state: &GameState,
    city: &City,
    target: CityProductionTarget,
    cost: i64,
    allocation: &StrategicResourceStockpile,
) -> Result<ProductionMutation, ProductionError> {
    if city
        .production_queue()
        .is_some_and(|queue| queue.target() == target && queue.resource_allocation() == allocation)
    {
        return Ok(ProductionMutation::Identity);
    }
    let investment = city.production_queue().map_or_else(
        || rollover_investment(city.production_overflow(), cost),
        CityProductionQueue::invested_production,
    );
    let queue = CityProductionQueue::try_new(target, investment, allocation.clone())
        .map_err(|error| invalid(error.to_string()))?;
    let overflow = if city.production_queue().is_none() {
        0
    } else {
        city.production_overflow()
    };
    let updated_city = city
        .try_with_production(Some(queue), overflow)
        .map_err(|error| invalid(error.to_string()))?;
    let mut changes = Vec::new();
    if let Some(current) = city.production_queue() {
        resource_changes(
            &mut changes,
            city.owner_player_id(),
            current.resource_allocation(),
            1,
        );
    }
    resource_changes(&mut changes, city.owner_player_id(), allocation, -1);
    let economy = state
        .economy()
        .try_after_changes(state.match_lifecycle().identity(), state.bounds(), changes)
        .map_err(|error| invalid(error.to_string()))?;
    let revision = next_revision(state)?;
    let mut cities = state.cities().to_vec();
    replace_city(&mut cities, updated_city)?;
    Ok(ProductionMutation::update(production_update(
        state, revision, cities, economy,
    )))
}

fn resource_changes(
    changes: &mut Vec<EconomyAccountChange>,
    player: &aonw_domain::PlayerId,
    allocation: &StrategicResourceStockpile,
    direction: i64,
) {
    changes.extend(allocation.amounts().iter().map(|(resource, amount)| {
        EconomyAccountChange::StrategicResource {
            player: player.clone(),
            resource: *resource,
            delta: amount.saturating_mul(direction),
        }
    }));
}

pub(super) fn production_update(
    state: &GameState,
    revision: aonw_domain::StateRevision,
    cities: Vec<City>,
    economy: aonw_domain::EconomyState,
) -> ProductionStateUpdate {
    ProductionStateUpdate {
        revision,
        units: state.units().to_vec(),
        cities,
        economy,
        knowledge: state.knowledge().clone(),
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
    }
}

const fn rollover_investment(stored_overflow: i64, production_cost: i64) -> i64 {
    if stored_overflow <= 0 || production_cost <= 1 {
        0
    } else {
        let cap = production_cost / 2;
        if stored_overflow < cap {
            stored_overflow
        } else {
            cap
        }
    }
}
