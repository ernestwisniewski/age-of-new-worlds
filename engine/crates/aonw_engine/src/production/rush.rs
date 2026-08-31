use aonw_domain::{
    City, CityProductionTarget, Diplomacy, EconomyAccountChange, EconomyState, FogOfWar, GameState,
    KnowledgeState, ProductionStateUpdate, Unit,
};

use super::ProductionError;
use super::commands::ProductionMutation;
use super::model::RushProductionCommand;
use super::spawn::produced_unit;
use super::support::{
    controlled_city, invalid, next_revision, pace, replace_city, validate_revision,
};
use super::wonder::resolve_completed_for_player;
use super::yield_rules::production_per_turn;
use crate::{
    CityBuiltBuildingEvent, CityProducedUnitEvent, CommandRejectionCode, DomainEvent, EngineContext,
};

pub(crate) fn apply_rush(
    state: &GameState,
    context: EngineContext<'_>,
    command: RushProductionCommand<'_>,
) -> Result<ProductionMutation, ProductionError> {
    validate_revision(state, command.expected_revision())?;
    let city = controlled_city(state, context, command.city_id())?;
    let queue = city
        .production_queue()
        .ok_or(CommandRejectionCode::ProductionQueueEmpty)?;
    let target = finite_target(queue.target())?;
    let cost = target_cost(state, context, target)?;
    let remaining = cost.saturating_sub(queue.invested_production());
    if remaining <= 0 {
        return Err(CommandRejectionCode::RushProductionUnavailable.into());
    }
    let per_turn = production_per_turn(state, context, city, queue.target())?;
    let rushed = remaining.min(per_turn.max(1));
    let price = rushed
        .checked_mul(context.ruleset().production().rush_gold_per_production())
        .ok_or_else(|| invalid("rush gold cost overflow"))?;
    let available = state
        .economy()
        .player_gold()
        .get(city.owner_player_id())
        .copied()
        .unwrap_or(0);
    if rushed <= 0 || price <= 0 || available < price {
        return Err(CommandRejectionCode::RushProductionUnavailable.into());
    }

    let economy = state
        .economy()
        .try_after_changes(
            state.match_lifecycle().identity(),
            state.bounds(),
            [EconomyAccountChange::Gold {
                player: city.owner_player_id().clone(),
                delta: price.saturating_neg(),
            }],
        )
        .map_err(|error| invalid(error.to_string()))?;
    let invested = queue
        .invested_production()
        .checked_add(rushed)
        .ok_or_else(|| invalid("rushed production overflow"))?;
    let advanced_queue = queue
        .try_with_invested_production(invested)
        .map_err(|error| invalid(error.to_string()))?;
    let advanced_city = city
        .try_with_production(Some(advanced_queue), city.production_overflow())
        .map_err(|error| invalid(error.to_string()))?;
    let mut cities = state.cities().to_vec();
    replace_city(&mut cities, advanced_city.clone())?;
    let completion = complete_target(CompletionInput {
        state,
        context,
        city,
        advanced_city: &advanced_city,
        target,
        invested,
        cost,
        cities,
        economy,
    })?;

    let update = ProductionStateUpdate {
        revision: next_revision(state)?,
        units: completion.units,
        cities: completion.cities,
        economy: completion.economy,
        knowledge: completion.knowledge,
        fog_of_war: completion.fog,
        diplomacy: completion.diplomacy,
    };
    Ok(ProductionMutation::with_events(update, completion.events))
}

struct CompletionResolution {
    units: Vec<Unit>,
    cities: Vec<City>,
    economy: EconomyState,
    knowledge: KnowledgeState,
    fog: FogOfWar,
    diplomacy: Diplomacy,
    events: Vec<DomainEvent>,
}

struct CompletionInput<'state, 'context, 'city> {
    state: &'state GameState,
    context: EngineContext<'context>,
    city: &'city City,
    advanced_city: &'city City,
    target: FiniteProductionTarget,
    invested: i64,
    cost: i64,
    cities: Vec<City>,
    economy: EconomyState,
}

fn complete_target(
    input: CompletionInput<'_, '_, '_>,
) -> Result<CompletionResolution, ProductionError> {
    let CompletionInput {
        state,
        context,
        city,
        advanced_city,
        target,
        invested,
        cost,
        cities,
        economy,
    } = input;
    let mut resolution = CompletionResolution {
        units: state.units().to_vec(),
        cities,
        economy,
        knowledge: state.knowledge().clone(),
        fog: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        events: Vec::new(),
    };
    if invested < cost {
        return Ok(resolution);
    }
    let overflow = invested.saturating_sub(cost);
    match target {
        FiniteProductionTarget::Building(building) => {
            let definition = context
                .ruleset()
                .production()
                .building(building)
                .ok_or_else(|| invalid("completed building is absent from content"))?;
            let completed = advanced_city
                .try_with_completed_building(building, definition.max_controlled_hexes_delta())
                .and_then(|city| city.try_with_production(None, overflow))
                .map_err(|error| invalid(error.to_string()))?;
            replace_city(&mut resolution.cities, completed)?;
            resolution
                .events
                .push(DomainEvent::CityBuiltBuilding(CityBuiltBuildingEvent::new(
                    city.id().clone(),
                    building,
                )));
        }
        FiniteProductionTarget::Unit(kind) => {
            if let Some(unit) = produced_unit(
                context,
                advanced_city,
                kind,
                &resolution.units,
                state.occupancy_policy(),
            )? {
                let produced_id = unit.id().clone();
                let owner = unit.owner_player_id().clone();
                resolution.units.push(unit);
                let completed = advanced_city
                    .try_with_production(None, overflow)
                    .map_err(|error| invalid(error.to_string()))?;
                replace_city(&mut resolution.cities, completed)?;
                resolution
                    .events
                    .push(DomainEvent::CityProducedUnit(CityProducedUnitEvent::new(
                        city.id().clone(),
                        kind,
                        produced_id,
                    )));
                let refs = resolution.units.iter().collect::<Vec<_>>();
                resolution.fog = crate::movement::recompute_after_move(
                    &resolution.fog,
                    context.map(),
                    &owner,
                    &refs,
                    &resolution.cities,
                );
                resolution.diplomacy = crate::movement::merge_discovered_contacts(
                    &resolution.diplomacy,
                    &resolution.fog,
                    &refs,
                    &resolution.cities,
                );
            }
        }
        FiniteProductionTarget::Wonder(_) => {
            let resolved = resolve_completed_for_player(
                state,
                context,
                resolution.cities,
                resolution.economy,
                city.owner_player_id(),
            )?;
            resolution.cities = resolved.cities;
            resolution.economy = resolved.economy;
            resolution.knowledge = resolved.knowledge;
            resolution.events = resolved.events;
        }
    }
    Ok(resolution)
}

fn target_cost(
    state: &GameState,
    context: EngineContext<'_>,
    target: FiniteProductionTarget,
) -> Result<i64, ProductionError> {
    let production = context.ruleset().production();
    match target {
        FiniteProductionTarget::Building(building) => production
            .building(building)
            .and_then(|definition| production.building_cost(definition.base_cost(), pace(state))),
        FiniteProductionTarget::Unit(unit) => production
            .unit(unit)
            .and_then(|definition| production.unit_cost(definition.base_cost(), pace(state))),
        FiniteProductionTarget::Wonder(wonder) => production
            .wonder(wonder)
            .and_then(|definition| production.building_cost(definition.base_cost(), pace(state))),
    }
    .ok_or_else(|| invalid("queued production target is absent or its cost overflowed"))
}

fn finite_target(target: CityProductionTarget) -> Result<FiniteProductionTarget, ProductionError> {
    match target {
        CityProductionTarget::Building(building) => Ok(FiniteProductionTarget::Building(building)),
        CityProductionTarget::Unit(unit) => Ok(FiniteProductionTarget::Unit(unit)),
        CityProductionTarget::Wonder(wonder) => Ok(FiniteProductionTarget::Wonder(wonder)),
        CityProductionTarget::Project(_) => Err(CommandRejectionCode::ProjectCannotBeRushed.into()),
    }
}

#[derive(Clone, Copy)]
enum FiniteProductionTarget {
    Building(aonw_domain::CityBuildingType),
    Unit(aonw_domain::UnitKind),
    Wonder(aonw_domain::WonderType),
}
