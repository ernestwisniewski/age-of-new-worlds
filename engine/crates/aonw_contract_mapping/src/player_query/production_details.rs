use aonw_content::{CombatStats, EconomyYield, ProductionRequirement};
use aonw_contracts::CombatStatsDto;
use aonw_contracts::client::{
    BuildingProductionDetailsDto, ClientQueryResultDto, ProductionBuildingRankDto,
    ProductionCityOutputDto, ProductionRequirementDto, ProductionRequirementStatusDto,
    ProductionTargetEffectsDto, UnitProductionDetailsDto, WonderProductionDetailsDto,
    YieldValueDto,
};
use aonw_engine::{
    BuildingProductionDetails, ProductionBuildingRanks, ProductionCityOutput, ProductionDetails,
    ProductionRequirementStatus, ProductionTargetEffects, UnitProductionDetails,
    WonderProductionDetails,
};
use aonw_projection::SessionStamp;

use super::production::{production_option, stockpile};
use crate::{encode_city_building, encode_client_stamp, encode_map_resource, encode_map_terrain};

/// Encodes selected-target details identically for local and authenticated server sessions.
#[must_use]
pub fn encode_production_details(
    stamp: SessionStamp,
    value: &ProductionDetails,
) -> ClientQueryResultDto {
    ClientQueryResultDto::ProductionDetails {
        stamp: encode_client_stamp(stamp),
        city_id: value.city_id.as_str().to_owned(),
        option: production_option(value.option),
        effects: match &value.effects {
            ProductionTargetEffects::Building(value) => {
                ProductionTargetEffectsDto::Building(building(value))
            }
            ProductionTargetEffects::Unit(value) => ProductionTargetEffectsDto::Unit(unit(value)),
            ProductionTargetEffects::Wonder(value) => {
                ProductionTargetEffectsDto::Wonder(wonder(value))
            }
            ProductionTargetEffects::Project => ProductionTargetEffectsDto::Project,
        },
    }
}

/// Encodes the authoritative catalog priorities without sorting localized labels.
#[must_use]
pub fn encode_production_building_ranks(
    stamp: SessionStamp,
    value: &ProductionBuildingRanks,
) -> ClientQueryResultDto {
    ClientQueryResultDto::ProductionBuildingRanks {
        stamp: encode_client_stamp(stamp),
        city_id: value.city_id.as_str().to_owned(),
        buildings: value
            .buildings
            .iter()
            .map(|rank| ProductionBuildingRankDto {
                building: encode_city_building(rank.building),
                turns_for_score: rank.turns_for_score,
                recommended: rank.recommended,
                best_return: rank.best_return,
                growth: rank.growth,
                industry: rank.industry,
                science: rank.science,
                defense_military: rank.defense_military,
                economy: rank.economy,
            })
            .collect(),
    }
}

fn building(value: &BuildingProductionDetails) -> BuildingProductionDetailsDto {
    BuildingProductionDetailsDto {
        requirements: requirements(&value.requirements),
        flat_yield: content_yield(value.flat_yield),
        river_yield_per_hex: content_yield(value.river_yield_per_hex),
        max_river_applications: value.max_river_applications,
        river_applications: value.river_applications,
        science_per_turn: value.science_per_turn,
        max_controlled_hexes_delta: value.max_controlled_hexes_delta,
        food_deposit_basis_points: value.food_deposit_basis_points,
        current: city_output(value.current),
        completed: city_output(value.completed),
    }
}

fn unit(value: &UnitProductionDetails) -> UnitProductionDetailsDto {
    UnitProductionDetailsDto {
        base_combat: base_combat(value.base_combat),
        effective_combat: crate::client_projection::encode_combat_stats(&value.effective_combat),
        maximum_movement_units: value.maximum_movement.get(),
        base_upkeep: value.base_upkeep,
        supply_cost: value.supply_cost,
        supply_capacity: value.supply_capacity,
        supply_used_without_city_queue: value.supply_used_without_city_queue,
        presence_resources: value
            .presence_resources
            .iter()
            .copied()
            .map(encode_map_resource)
            .collect(),
        presence_resources_met: value.presence_resources_met,
        coast_met: value.coast_met,
        resource_options: value.resource_options.iter().map(stockpile).collect(),
        affordable_resource_option_indices: value.affordable_resource_option_indices.to_vec(),
    }
}

fn wonder(value: &WonderProductionDetails) -> WonderProductionDetailsDto {
    WonderProductionDetailsDto {
        requirements: requirements(&value.requirements),
        host_yield: content_yield(value.host_yield),
        empire_yield_per_city: content_yield(value.empire_yield_per_city),
        empire_science_per_city: value.empire_science_per_city,
        empire_gold_basis_points: value.empire_gold_basis_points,
        empire_production_basis_points: value.empire_production_basis_points,
        stability_delta: value.stability_delta,
        grants_free_active_technology: value.grants_free_active_technology,
        production_burst: value.production_burst,
        grant_gold: value.grant_gold,
    }
}

fn city_output(value: ProductionCityOutput) -> ProductionCityOutputDto {
    ProductionCityOutputDto {
        gross_yield: YieldValueDto {
            food: value.gross_yield.food,
            production: value.gross_yield.production,
            gold: value.gross_yield.gold,
            defense: value.gross_yield.defense,
        },
        food_deposit: value.food_deposit,
        production: value.production,
        gold: value.gold,
        science: value.science,
        max_controlled_hexes: value.max_controlled_hexes,
    }
}

fn content_yield(value: EconomyYield) -> YieldValueDto {
    YieldValueDto {
        food: value.food(),
        production: value.production(),
        gold: value.gold(),
        defense: value.defense(),
    }
}

fn base_combat(value: CombatStats) -> CombatStatsDto {
    CombatStatsDto {
        attack: value.attack(),
        defense: value.defense(),
        hit_points: value.hit_points(),
        range: value.range(),
        mobility: value.mobility(),
        modifiers: Vec::new(),
    }
}

fn requirements(values: &[ProductionRequirementStatus]) -> Vec<ProductionRequirementStatusDto> {
    values
        .iter()
        .map(|value| ProductionRequirementStatusDto {
            met: value.met,
            requirement: match value.requirement {
                ProductionRequirement::CoastalAccess => ProductionRequirementDto::CoastalAccess {},
                ProductionRequirement::AdjacentRiver => ProductionRequirementDto::AdjacentRiver {},
                ProductionRequirement::AdjacentMountain => {
                    ProductionRequirementDto::AdjacentMountain {}
                }
                ProductionRequirement::ResourceAny(resources) => {
                    ProductionRequirementDto::ResourceAny {
                        resources: resources.iter().copied().map(encode_map_resource).collect(),
                    }
                }
                ProductionRequirement::HostTerrainAny(terrains) => {
                    ProductionRequirementDto::HostTerrainAny {
                        terrains: terrains.iter().copied().map(encode_map_terrain).collect(),
                    }
                }
            },
        })
        .collect()
}
