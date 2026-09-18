use serde::{Deserialize, Serialize};

use crate::client::{MapResourceDto, MapTerrainDto, YieldValueDto};
use crate::{CityBuildingTypeDto, CombatStatsDto, StrategicResourceStockpileDto};

/// Current local site requirements; alternatives are part of public ruleset content.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ProductionRequirementDto {
    CoastalAccess {},
    ResourceAny { resources: Vec<MapResourceDto> },
    AdjacentRiver {},
    AdjacentMountain {},
    HostTerrainAny { terrains: Vec<MapTerrainDto> },
}

/// One production-command predicate evaluated for the controlled city.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionRequirementStatusDto {
    pub requirement: ProductionRequirementDto,
    pub met: bool,
}

/// Current passive city output without queue-specific bonuses or project conversion.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionCityOutputDto {
    pub gross_yield: YieldValueDto,
    pub food_deposit: i64,
    pub production: i64,
    pub gold: i64,
    pub science: i64,
    pub max_controlled_hexes: i64,
}

/// Building effects and exact conditional city output after completion.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct BuildingProductionDetailsDto {
    pub requirements: Vec<ProductionRequirementStatusDto>,
    pub flat_yield: YieldValueDto,
    pub river_yield_per_hex: YieldValueDto,
    pub max_river_applications: u32,
    pub river_applications: u32,
    pub science_per_turn: i64,
    pub max_controlled_hexes_delta: i64,
    pub food_deposit_basis_points: u32,
    pub current: ProductionCityOutputDto,
    pub completed: ProductionCityOutputDto,
}

/// Fresh-unit statistics, persistent owner modifiers and current supply allocation.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitProductionDetailsDto {
    pub base_combat: CombatStatsDto,
    pub effective_combat: CombatStatsDto,
    pub maximum_movement_units: u32,
    pub base_upkeep: i64,
    pub supply_cost: i64,
    pub supply_capacity: i64,
    pub supply_used_without_city_queue: i64,
    pub presence_resources: Vec<MapResourceDto>,
    pub presence_resources_met: bool,
    pub coast_met: bool,
    pub resource_options: Vec<StrategicResourceStockpileDto>,
    pub affordable_resource_option_indices: Vec<u32>,
}

/// Public wonder effects and only the current owned city's local requirements.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct WonderProductionDetailsDto {
    pub requirements: Vec<ProductionRequirementStatusDto>,
    pub host_yield: YieldValueDto,
    pub empire_yield_per_city: YieldValueDto,
    pub empire_science_per_city: i64,
    pub empire_gold_basis_points: u32,
    pub empire_production_basis_points: u32,
    pub stability_delta: i64,
    pub grants_free_active_technology: bool,
    pub production_burst: i64,
    pub grant_gold: i64,
}

/// Closed effect family; projects already expose output through their forecast.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    content = "details",
    rename_all = "camelCase",
    deny_unknown_fields
)]
pub enum ProductionTargetEffectsDto {
    Building(BuildingProductionDetailsDto),
    Unit(UnitProductionDetailsDto),
    Wonder(WonderProductionDetailsDto),
    Project,
}

/// Authoritative descending priorities, then ascending time and localized-name ties.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionBuildingRankDto {
    pub building: CityBuildingTypeDto,
    pub turns_for_score: i64,
    pub recommended: i64,
    pub best_return: i64,
    pub growth: i64,
    pub industry: i64,
    pub science: i64,
    pub defense_military: i64,
    pub economy: i64,
}
