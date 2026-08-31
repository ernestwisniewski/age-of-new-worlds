use std::collections::BTreeMap;

use aonw_content::{
    ProductionRequirement, StrategicResourceCost, TerrainType, UnitProductionDefinition,
};
use aonw_domain::{
    City, CityBuildingType, CityProductionQueue, CityProductionTarget, CityProjectType,
    CitySpecializationType, GameState, PlayerResearchState, ResourceType,
    StrategicResourceStockpile, TechnologyId, UnitKind, WonderType,
};

use super::ProductionError;
use super::model::{
    CitySpecializationOption, ProductionOption, ProductionOptions, ProductionOptionsQuery,
    UnitProductionOption,
};
use super::supply::{UnitSupplyBudget, unit_supply_budget};
use super::support::{
    city_territory, controlled_city, invalid, pace, spawn_candidates, technology_for,
    validate_revision,
};
use crate::economy::rules::{domain_resource, resources_at};
use crate::{CommandRejectionCode, EngineContext, TechnologyUnlockQuery};

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
            ))
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let units = production
        .units()
        .iter()
        .copied()
        .map(|definition| unit_option(state, context, city, technology, &supply, definition))
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let projects = PROJECTS
        .into_iter()
        .map(|project| ProductionOption::new(CityProductionTarget::Project(project), 0, None))
        .collect::<Vec<_>>();
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
            ))
        })
        .collect::<Result<Vec<_>, ProductionError>>()?;
    let specializations = SPECIALIZATIONS
        .into_iter()
        .map(|specialization| {
            let required = production.specialization_building(specialization);
            CitySpecializationOption::new(
                specialization,
                required,
                specialization_rejection(city, technology, specialization, required),
            )
        })
        .collect::<Vec<_>>();
    let queue = city.production_queue();
    Ok(ProductionOptions::new(
        state.revision().get(),
        city.id().clone(),
        queue.map(CityProductionQueue::target),
        queue.map_or(0, CityProductionQueue::invested_production),
        city.production_overflow(),
        buildings,
        units,
        projects,
        wonders,
        specializations,
    ))
}

fn unit_option(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    supply: &UnitSupplyBudget,
    definition: UnitProductionDefinition,
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
        ),
        evaluation.resource_options,
        evaluation.affordable_indices,
    ))
}

pub(super) struct UnitEvaluation {
    pub(super) rejection: Option<CommandRejectionCode>,
    resource_options: Vec<StrategicResourceStockpile>,
    affordable_indices: Vec<u32>,
    pub(super) selected_allocation: Option<StrategicResourceStockpile>,
}

pub(super) fn evaluate_unit(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    prepared_supply: Option<&UnitSupplyBudget>,
    definition: UnitProductionDefinition,
    preferred_option: Option<u32>,
) -> Result<UnitEvaluation, ProductionError> {
    let resource_options = definition
        .strategic_cost_options()
        .iter()
        .copied()
        .map(strategic_stockpile)
        .collect::<Result<Vec<_>, _>>()?;
    if preferred_option.is_some_and(|index| {
        usize::try_from(index).map_or(true, |index| index >= resource_options.len())
    }) {
        return Ok(UnitEvaluation {
            rejection: Some(CommandRejectionCode::UnitProductionInvalidResourceOption),
            resource_options,
            affordable_indices: Vec::new(),
            selected_allocation: None,
        });
    }
    let affordable_indices = resource_options
        .iter()
        .enumerate()
        .filter(|(_, option)| resource_option_is_covered(state, city, option))
        .filter_map(|(index, _)| u32::try_from(index).ok())
        .collect::<Vec<_>>();
    let selected_allocation = if resource_options.is_empty() {
        Some(StrategicResourceStockpile::default())
    } else if let Some(index) = preferred_option {
        affordable_indices
            .contains(&index)
            .then(|| resource_options[usize::try_from(index).expect("validated index")].clone())
    } else {
        affordable_indices
            .first()
            .and_then(|index| usize::try_from(*index).ok())
            .map(|index| resource_options[index].clone())
    };
    let rejection = if !technology.is_unit_unlocked(definition.unit()) {
        Some(CommandRejectionCode::UnitProductionNotAvailable)
    } else if !presence_resource_available(state, context, city.owner_player_id(), definition) {
        Some(CommandRejectionCode::UnitProductionRequiresResource)
    } else if selected_allocation.is_none() {
        Some(CommandRejectionCode::UnitProductionMissingStrategicResource)
    } else if !unit_has_required_coast(context, city, definition.unit()) {
        Some(CommandRejectionCode::UnitProductionRequiresCoast)
    } else if !match prepared_supply {
        Some(supply) => supply.permits(definition)?,
        None => unit_supply_budget(state, context, city)?.permits(definition)?,
    } {
        Some(CommandRejectionCode::UnitSupplyLimitReached)
    } else {
        None
    };
    Ok(UnitEvaluation {
        rejection,
        resource_options,
        affordable_indices,
        selected_allocation,
    })
}

pub(super) fn building_rejection(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    building: CityBuildingType,
) -> Result<Option<CommandRejectionCode>, ProductionError> {
    let definition = context
        .ruleset()
        .production()
        .building(building)
        .ok_or_else(|| invalid("building is absent from production content"))?;
    Ok((!technology.is_building_unlocked(building)
        || city.buildings().contains(&building)
        || !definition
            .requirements()
            .iter()
            .all(|requirement| requirement_met(state, context, city, technology, *requirement)))
    .then_some(CommandRejectionCode::BuildingNotAvailable))
}

pub(super) fn wonder_rejection(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    wonder: WonderType,
) -> Result<Option<CommandRejectionCode>, ProductionError> {
    let definition = context
        .ruleset()
        .production()
        .wonder(wonder)
        .ok_or_else(|| invalid("wonder is absent from production content"))?;
    let completed = state.wonder_registry().completed_by().contains_key(&wonder);
    let city_builds_wonder = matches!(
        city.production_queue().map(CityProductionQueue::target),
        Some(CityProductionTarget::Wonder(_))
    );
    let player_builds_wonder = state.cities().iter().any(|candidate| {
        candidate.id() != city.id()
            && candidate.owner_player_id() == city.owner_player_id()
            && matches!(
                candidate
                    .production_queue()
                    .map(CityProductionQueue::target),
                Some(CityProductionTarget::Wonder(_))
            )
    });
    Ok((completed
        || !technology.is_wonder_unlocked(wonder)
        || !definition
            .requirements()
            .iter()
            .all(|requirement| requirement_met(state, context, city, technology, *requirement))
        || city_builds_wonder
        || player_builds_wonder)
        .then_some(CommandRejectionCode::WonderNotAvailable))
}

pub(super) fn specialization_rejection(
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    specialization: CitySpecializationType,
    required: CityBuildingType,
) -> Option<CommandRejectionCode> {
    if !technology.is_technology_unlocked(TechnologyId::Specialization) {
        Some(CommandRejectionCode::CitySpecializationLocked)
    } else if city.specialization() == Some(specialization) {
        Some(CommandRejectionCode::CitySpecializationUnchanged)
    } else if !city.buildings().contains(&required) {
        Some(CommandRejectionCode::CitySpecializationMissingBuilding)
    } else {
        None
    }
}

fn requirement_met(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    technology: TechnologyUnlockQuery<'_>,
    requirement: ProductionRequirement,
) -> bool {
    match requirement {
        ProductionRequirement::CoastalAccess => city_territory(city).any(|coordinate| {
            context.map().tile_at(coordinate).is_some_and(|tile| {
                tile.terrain_tags()
                    .iter()
                    .any(|terrain| matches!(terrain, TerrainType::Coast | TerrainType::Ocean))
            })
        }),
        ProductionRequirement::ResourceAny(required) => city_territory(city).any(|coordinate| {
            resources_at(state, context, coordinate)
                .iter()
                .any(|resource| {
                    technology.is_resource_revealed(*resource)
                        && required
                            .iter()
                            .any(|required| domain_resource(*required) == *resource)
                })
        }),
        ProductionRequirement::AdjacentRiver => city.center().neighbors().any(|coordinate| {
            context
                .map()
                .tile_at(coordinate)
                .is_some_and(|tile| tile.terrain_tags().contains(&TerrainType::River))
        }),
        ProductionRequirement::AdjacentMountain => city.center().neighbors().any(|coordinate| {
            context
                .map()
                .tile_at(coordinate)
                .is_some_and(|tile| tile.yield_terrain() == TerrainType::Mountain)
        }),
        ProductionRequirement::HostTerrainAny(allowed) => context
            .map()
            .tile_at(city.center())
            .is_some_and(|tile| allowed.contains(&tile.yield_terrain())),
    }
}

fn presence_resource_available(
    state: &GameState,
    context: EngineContext<'_>,
    player: &aonw_domain::PlayerId,
    definition: UnitProductionDefinition,
) -> bool {
    if definition.presence_resources().is_empty() {
        return true;
    }
    let empty = PlayerResearchState::default();
    let research = state.research().players().get(player).unwrap_or(&empty);
    let technology = TechnologyUnlockQuery::new(context.ruleset(), research);
    state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .flat_map(city_territory)
        .any(|coordinate| {
            resources_at(state, context, coordinate)
                .iter()
                .any(|resource| {
                    technology.is_resource_revealed(*resource)
                        && definition
                            .presence_resources()
                            .iter()
                            .any(|required| domain_resource(*required) == *resource)
                })
        })
}

fn unit_has_required_coast(context: EngineContext<'_>, city: &City, unit: UnitKind) -> bool {
    let Some(definition) = context.ruleset().unit(unit) else {
        return false;
    };
    if definition.capabilities().movement_domain.domain() != aonw_domain::UnitMovementDomain::Naval
    {
        return true;
    }
    spawn_candidates(context, city).any(|coordinate| {
        let Some(tile) = context.map().tile_at(coordinate) else {
            return false;
        };
        tile.yield_terrain() == TerrainType::Coast
            && coordinate.neighbors().any(|neighbor| {
                context
                    .map()
                    .tile_at(neighbor)
                    .is_some_and(|neighbor| neighbor.yield_terrain() == TerrainType::Ocean)
            })
    })
}

fn resource_option_is_covered(
    state: &GameState,
    city: &City,
    option: &StrategicResourceStockpile,
) -> bool {
    option.amounts().iter().all(|(resource, required)| {
        let on_hand = state
            .economy()
            .strategic_resources()
            .get(city.owner_player_id())
            .and_then(|stockpile| stockpile.amounts().get(resource))
            .copied()
            .unwrap_or(0);
        let refundable = city
            .production_queue()
            .and_then(|queue| queue.resource_allocation().amounts().get(resource))
            .copied()
            .unwrap_or(0);
        on_hand
            .checked_add(refundable)
            .is_some_and(|available| available >= *required)
    })
}

fn strategic_stockpile(
    cost: StrategicResourceCost,
) -> Result<StrategicResourceStockpile, ProductionError> {
    let mut amounts = BTreeMap::new();
    if cost.oil() > 0 {
        amounts.insert(ResourceType::Oil, cost.oil());
    }
    if cost.aluminium() > 0 {
        amounts.insert(ResourceType::Aluminium, cost.aluminium());
    }
    StrategicResourceStockpile::try_new(amounts).map_err(|error| invalid(error.to_string()))
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
    use aonw_domain::{City, CityId, HexCoord, PlayerId, UnitKind};

    use super::unit_has_required_coast;
    use crate::EngineContext;

    #[test]
    fn naval_coast_check_fails_closed_for_a_city_outside_the_context_map() {
        let map = MapDefinition::try_new(
            "production-coast-unit-test",
            GridLayout::OddQFlatTop,
            1,
            1,
            vec![
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(0, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile"),
            ],
            Vec::new(),
        )
        .expect("map");
        let actor = PlayerId::new("player").expect("player");
        let city = City::new(
            CityId::new("city").expect("city"),
            actor.clone(),
            HexCoord::new(3, 3),
            [],
        );
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

        assert!(!unit_has_required_coast(
            context,
            &city,
            UnitKind::ScoutShip
        ));
    }
}
