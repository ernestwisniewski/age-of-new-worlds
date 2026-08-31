use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, CityId, CityProductionTarget, CityProjectType, EconomyAccountChange, EconomyState,
    FogOfWar, GameState, PlayerId, ProductionStateUpdate, Unit,
};
use std::collections::BTreeMap;

use super::ProductionError;
use super::spawn::produced_unit;
use super::support::{invalid, pace, replace_city};
use super::wonder::resolve_completed_for_player;
use super::yield_rules::{production_per_turn, target_production};
use crate::{CityBuiltBuildingEvent, CityProducedUnitEvent, DomainEvent, EngineContext};

/// State and ordered events produced by the current production turn phase.
pub(crate) struct ProductionTurnPhase {
    pub(crate) state: GameState,
    pub(crate) events: Vec<DomainEvent>,
    pub(crate) research_project_science: Vec<ResearchProjectScience>,
}

/// One city-owned science contribution produced by a continuous project.
pub(crate) struct ResearchProjectScience {
    pub(crate) player_id: PlayerId,
    pub(crate) city_id: CityId,
    pub(crate) amount: i64,
}

/// Calculates current continuous research-project output without mutating state.
pub(crate) fn selected_research_project_science(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
) -> Result<Vec<ResearchProjectScience>, ProductionError> {
    let divisor = context.ruleset().production().project_divisor(true);
    state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .filter(|city| {
            city.production_queue().is_some_and(|queue| {
                queue.target() == CityProductionTarget::Project(CityProjectType::Research)
            })
        })
        .map(|city| {
            let production = production_per_turn(
                state,
                context,
                city,
                CityProductionTarget::Project(CityProjectType::Research),
            )?;
            Ok(ResearchProjectScience {
                player_id: player.clone(),
                city_id: city.id().clone(),
                amount: project_output(production, divisor)?,
            })
        })
        .collect()
}

/// Advances every scoped player's production in canonical player and city order.
pub(crate) fn advance_turn_production(
    prepared: crate::economy::PreparedEconomyTurn,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<ProductionTurnPhase, ProductionError> {
    let crate::economy::PreparedEconomyTurn {
        mut state,
        production_by_city,
        gold_by_player,
        mut city_events_by_city,
    } = prepared;
    let mut events = Vec::new();
    let mut research_project_science = Vec::new();
    for player in scope {
        if !state
            .cities()
            .iter()
            .any(|city| city.owner_player_id() == player && city.production_queue().is_some())
        {
            for city in state
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() == player)
            {
                if let Some(city_events) = city_events_by_city.remove(city.id()) {
                    events.extend(city_events);
                }
            }
            continue;
        }
        let context = EngineContext::canonical(player, map, ruleset);
        let advanced = advance_player(
            &state,
            context,
            player,
            &production_by_city,
            &mut city_events_by_city,
        )?;
        let wonders = resolve_completed_for_player(
            &state,
            context,
            advanced.cities,
            advanced.economy,
            player,
        )?;
        events.extend(advanced.events);
        research_project_science.extend(advanced.research_project_science);
        events.extend(wonders.events);
        let update = ProductionStateUpdate {
            revision: state.revision(),
            units: advanced.units,
            cities: wonders.cities,
            economy: wonders.economy,
            knowledge: wonders.knowledge,
            fog_of_war: advanced.fog,
            diplomacy: advanced.diplomacy,
        };
        state = state
            .into_after_production(update)
            .map_err(|error| invalid(error.to_string()))?;
    }
    state = crate::economy::settle_turn_income_and_upkeep(state, ruleset, scope, &gold_by_player)
        .map_err(|error| invalid(error.to_string()))?;
    Ok(ProductionTurnPhase {
        state,
        events,
        research_project_science,
    })
}

struct PlayerProductionAdvance {
    units: Vec<Unit>,
    cities: Vec<City>,
    economy: EconomyState,
    fog: FogOfWar,
    diplomacy: aonw_domain::Diplomacy,
    events: Vec<DomainEvent>,
    research_project_science: Vec<ResearchProjectScience>,
}

fn advance_player(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    production_by_city: &BTreeMap<CityId, i64>,
    city_events_by_city: &mut BTreeMap<CityId, Vec<DomainEvent>>,
) -> Result<PlayerProductionAdvance, ProductionError> {
    let mut advance = PlayerProductionAdvance {
        units: state.units().to_vec(),
        cities: state.cities().to_vec(),
        economy: state.economy().clone(),
        fog: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        events: Vec::new(),
        research_project_science: Vec::new(),
    };
    for index in 0..advance.cities.len() {
        let city = advance.cities[index].clone();
        if city.owner_player_id() != player {
            continue;
        }
        if let Some(events) = city_events_by_city.remove(city.id()) {
            advance.events.extend(events);
        }
        let Some(queue) = city.production_queue() else {
            continue;
        };
        let production = production_by_city
            .get(city.id())
            .copied()
            .ok_or_else(|| invalid("prepared city production is missing"))?;
        let production = target_production(state, context, &city, queue.target(), production)?;
        match queue.target() {
            CityProductionTarget::Project(project) => {
                apply_project(
                    state,
                    context,
                    &city,
                    &mut advance.economy,
                    &mut advance.research_project_science,
                    project,
                    production,
                )?;
            }
            CityProductionTarget::Building(building) => advance_finite(
                &mut advance,
                state,
                context,
                &city,
                FiniteProductionTarget::Building(building),
                production,
            )?,
            CityProductionTarget::Unit(unit) => advance_finite(
                &mut advance,
                state,
                context,
                &city,
                FiniteProductionTarget::Unit(unit),
                production,
            )?,
            CityProductionTarget::Wonder(wonder) => advance_finite(
                &mut advance,
                state,
                context,
                &city,
                FiniteProductionTarget::Wonder(wonder),
                production,
            )?,
        }
    }
    Ok(advance)
}

fn apply_project(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    economy: &mut EconomyState,
    research_project_science: &mut Vec<ResearchProjectScience>,
    project: CityProjectType,
    production: i64,
) -> Result<(), ProductionError> {
    let divisor = context
        .ruleset()
        .production()
        .project_divisor(project == CityProjectType::Research);
    let output = project_output(production, divisor)?;
    match project {
        CityProjectType::Wealth => {
            let gold_change = (output > 0).then_some(EconomyAccountChange::Gold {
                player: city.owner_player_id().clone(),
                delta: output,
            });
            *economy = economy
                .try_after_changes(
                    state.match_lifecycle().identity(),
                    state.bounds(),
                    gold_change,
                )
                .map_err(|error| invalid(error.to_string()))?;
        }
        CityProjectType::Research if output > 0 => {
            research_project_science.push(ResearchProjectScience {
                player_id: city.owner_player_id().clone(),
                city_id: city.id().clone(),
                amount: output,
            });
        }
        CityProjectType::Research => {}
    }
    Ok(())
}

fn project_output(production: i64, divisor: i64) -> Result<i64, ProductionError> {
    if production <= 0 {
        return Ok(0);
    }
    if divisor <= 0 {
        return Err(invalid("project divisor must be positive"));
    }
    production
        .checked_add(divisor - 1)
        .and_then(|value| value.checked_div(divisor))
        .ok_or_else(|| invalid("project output overflow"))
}

fn advance_finite(
    advance: &mut PlayerProductionAdvance,
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: FiniteProductionTarget,
    production: i64,
) -> Result<(), ProductionError> {
    let queue = city
        .production_queue()
        .expect("finite production caller preserves queue");
    let cost = target_cost(state, context, target)?;
    let invested = if queue.invested_production() >= cost {
        queue.invested_production()
    } else {
        queue
            .invested_production()
            .checked_add(production.max(0))
            .ok_or_else(|| invalid("turn production investment overflow"))?
    };
    let queue = queue
        .try_with_invested_production(invested)
        .map_err(|error| invalid(error.to_string()))?;
    let advanced_city = city
        .try_with_production(Some(queue), city.production_overflow())
        .map_err(|error| invalid(error.to_string()))?;
    replace_city(&mut advance.cities, advanced_city.clone())?;
    if invested < cost {
        return Ok(());
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
            replace_city(&mut advance.cities, completed)?;
            advance
                .events
                .push(DomainEvent::CityBuiltBuilding(CityBuiltBuildingEvent::new(
                    city.id().clone(),
                    building,
                )));
        }
        FiniteProductionTarget::Unit(kind) => {
            if let Some(unit) = produced_unit(
                context,
                &advanced_city,
                kind,
                &advance.units,
                state.occupancy_policy(),
            )? {
                let unit_id = unit.id().clone();
                let owner = unit.owner_player_id().clone();
                advance.units.push(unit);
                let completed = advanced_city
                    .try_with_production(None, overflow)
                    .map_err(|error| invalid(error.to_string()))?;
                replace_city(&mut advance.cities, completed)?;
                advance
                    .events
                    .push(DomainEvent::CityProducedUnit(CityProducedUnitEvent::new(
                        city.id().clone(),
                        kind,
                        unit_id,
                    )));
                let units = advance.units.iter().collect::<Vec<_>>();
                advance.fog = crate::movement::recompute_after_move(
                    &advance.fog,
                    context.map(),
                    &owner,
                    &units,
                    &advance.cities,
                );
                advance.diplomacy = crate::movement::merge_discovered_contacts(
                    &advance.diplomacy,
                    &advance.fog,
                    &units,
                    &advance.cities,
                );
            }
        }
        FiniteProductionTarget::Wonder(_) => return Ok(()),
    }
    Ok(())
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

#[derive(Clone, Copy)]
enum FiniteProductionTarget {
    Building(aonw_domain::CityBuildingType),
    Unit(aonw_domain::UnitKind),
    Wonder(aonw_domain::WonderType),
}

#[cfg(test)]
mod tests {
    use super::project_output;

    #[test]
    fn project_output_is_ceiled_bounded_and_fail_closed() {
        assert_eq!(project_output(0, 2).expect("zero output"), 0);
        assert_eq!(project_output(3, 2).expect("ceiled output"), 2);
        assert_eq!(project_output(5, 12).expect("research output"), 1);
        assert_eq!(project_output(13, 12).expect("research output"), 2);
        assert!(project_output(3, 0).is_err());
        assert!(project_output(i64::MAX, 2).is_err());
    }
}
