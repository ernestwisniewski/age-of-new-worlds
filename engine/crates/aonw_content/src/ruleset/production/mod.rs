use aonw_domain::{CityBuildingType, CitySpecializationType, PaceProfile, UnitKind, WonderType};
use serde::Serialize;

use crate::{ResourceType, TerrainType};

use super::EconomyYield;

mod building;
mod canonical;
mod unit;
mod wonder;

use building::STANDARD_BUILDINGS;
use unit::STANDARD_UNITS;
use wonder::STANDARD_WONDERS;

/// One current map or resource precondition for city production.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase", tag = "kind", content = "values")]
pub enum ProductionRequirement {
    CoastalAccess,
    ResourceAny(&'static [ResourceType]),
    AdjacentRiver,
    AdjacentMountain,
    HostTerrainAny(&'static [TerrainType]),
}

/// One alternative stockpile reservation used by unit production.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StrategicResourceCost {
    oil: i64,
    aluminium: i64,
}

impl StrategicResourceCost {
    pub(super) const fn new(oil: i64, aluminium: i64) -> Self {
        Self { oil, aluminium }
    }

    /// Returns required Oil.
    #[must_use]
    pub const fn oil(self) -> i64 {
        self.oil
    }

    /// Returns required Aluminium.
    #[must_use]
    pub const fn aluminium(self) -> i64 {
        self.aluminium
    }

    /// Returns whether this alternative reserves no strategic resource.
    #[must_use]
    pub const fn is_empty(self) -> bool {
        self.oil == 0 && self.aluminium == 0
    }
}

/// Content-owned construction rule for one building.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct BuildingProductionDefinition {
    pub(super) building: CityBuildingType,
    pub(super) base_cost: i64,
    pub(super) requirements: &'static [ProductionRequirement],
    pub(super) yield_delta: EconomyYield,
    pub(super) river_yield_per_hex: EconomyYield,
    pub(super) max_river_applications: u32,
    pub(super) science_per_turn: i64,
    pub(super) max_controlled_hexes_delta: i64,
    pub(super) food_deposit_basis_points: u32,
}

impl BuildingProductionDefinition {
    /// Returns building identity.
    #[must_use]
    pub const fn building(self) -> CityBuildingType {
        self.building
    }
    /// Returns unpaced production cost.
    #[must_use]
    pub const fn base_cost(self) -> i64 {
        self.base_cost
    }
    /// Returns all conjunctive production requirements.
    #[must_use]
    pub const fn requirements(self) -> &'static [ProductionRequirement] {
        self.requirements
    }
    /// Returns flat per-turn city yield after completion.
    #[must_use]
    pub const fn yield_delta(self) -> EconomyYield {
        self.yield_delta
    }
    /// Returns yield applied once per controlled river hex.
    #[must_use]
    pub const fn river_yield_per_hex(self) -> EconomyYield {
        self.river_yield_per_hex
    }
    /// Returns the maximum number of river-yield applications.
    #[must_use]
    pub const fn max_river_applications(self) -> u32 {
        self.max_river_applications
    }
    /// Returns flat per-turn science after completion.
    #[must_use]
    pub const fn science_per_turn(self) -> i64 {
        self.science_per_turn
    }
    /// Returns territory-capacity increase after completion.
    #[must_use]
    pub const fn max_controlled_hexes_delta(self) -> i64 {
        self.max_controlled_hexes_delta
    }
    /// Returns food-deposit multiplier where ten thousand equals one.
    #[must_use]
    pub const fn food_deposit_basis_points(self) -> u32 {
        self.food_deposit_basis_points
    }
}

/// Content-owned construction rule for one unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct UnitProductionDefinition {
    pub(super) unit: UnitKind,
    pub(super) base_cost: i64,
    pub(super) upkeep: i64,
    pub(super) supply_cost: i64,
    pub(super) presence_resources: &'static [ResourceType],
    pub(super) strategic_cost_options: &'static [StrategicResourceCost],
}

impl UnitProductionDefinition {
    /// Returns unit identity.
    #[must_use]
    pub const fn unit(self) -> UnitKind {
        self.unit
    }
    /// Returns unpaced production cost.
    #[must_use]
    pub const fn base_cost(self) -> i64 {
        self.base_cost
    }
    /// Returns the base per-turn gold upkeep before free-unit allocation.
    #[must_use]
    pub const fn upkeep(self) -> i64 {
        self.upkeep
    }
    /// Returns empire supply consumed by a produced or queued unit.
    #[must_use]
    pub const fn supply_cost(self) -> i64 {
        self.supply_cost
    }
    /// Returns alternative presence resources; any visible controlled value is enough.
    #[must_use]
    pub const fn presence_resources(self) -> &'static [ResourceType] {
        self.presence_resources
    }
    /// Returns ordered alternative stockpile reservations.
    #[must_use]
    pub const fn strategic_cost_options(self) -> &'static [StrategicResourceCost] {
        self.strategic_cost_options
    }
}

/// Content-owned construction and completion rule for one world wonder.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WonderProductionDefinition {
    pub(super) wonder: WonderType,
    pub(super) base_cost: i64,
    pub(super) requirements: &'static [ProductionRequirement],
    pub(super) host_yield: EconomyYield,
    pub(super) empire_yield_per_city: EconomyYield,
    pub(super) empire_science_per_city: i64,
    pub(super) empire_gold_basis_points: u32,
    pub(super) empire_production_basis_points: u32,
    pub(super) stability_delta: i64,
    pub(super) grant_free_active_technology: bool,
    pub(super) production_burst: i64,
    pub(super) grant_gold: i64,
}

impl WonderProductionDefinition {
    /// Returns wonder identity.
    #[must_use]
    pub const fn wonder(self) -> WonderType {
        self.wonder
    }
    /// Returns unpaced production cost.
    #[must_use]
    pub const fn base_cost(self) -> i64 {
        self.base_cost
    }
    /// Returns all conjunctive location/resource requirements.
    #[must_use]
    pub const fn requirements(self) -> &'static [ProductionRequirement] {
        self.requirements
    }
    /// Returns yield applied only to the hosting city.
    #[must_use]
    pub const fn host_yield(self) -> EconomyYield {
        self.host_yield
    }
    /// Returns yield applied to every city of the owner.
    #[must_use]
    pub const fn empire_yield_per_city(self) -> EconomyYield {
        self.empire_yield_per_city
    }
    /// Returns science applied to every city of the owner.
    #[must_use]
    pub const fn empire_science_per_city(self) -> i64 {
        self.empire_science_per_city
    }
    /// Returns empire gold multiplier where ten thousand equals one.
    #[must_use]
    pub const fn empire_gold_basis_points(self) -> u32 {
        self.empire_gold_basis_points
    }
    /// Returns empire production multiplier where ten thousand equals one.
    #[must_use]
    pub const fn empire_production_basis_points(self) -> u32 {
        self.empire_production_basis_points
    }
    /// Returns stability credited to the owner while the wonder exists.
    #[must_use]
    pub const fn stability_delta(self) -> i64 {
        self.stability_delta
    }
    /// Returns whether completion unlocks the owner's current active technology.
    #[must_use]
    pub const fn grants_free_active_technology(self) -> bool {
        self.grant_free_active_technology
    }
    /// Returns production overflow granted to the host at completion.
    #[must_use]
    pub const fn production_burst(self) -> i64 {
        self.production_burst
    }
    /// Returns gold credited at completion.
    #[must_use]
    pub const fn grant_gold(self) -> i64 {
        self.grant_gold
    }
}

/// Hash-addressed production, project, rush, pace, and supply balance.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProductionBalance {
    buildings: &'static [BuildingProductionDefinition],
    units: &'static [UnitProductionDefinition],
    wonders: &'static [WonderProductionDefinition],
    rush_gold_per_production: i64,
    wealth_project_divisor: i64,
    research_project_divisor: i64,
    supply_density_numerator: u32,
    supply_density_denominator: u32,
    minimum_map_supply: i64,
    maximum_map_supply: i64,
}

impl ProductionBalance {
    pub(super) const STANDARD: Self = Self {
        buildings: &STANDARD_BUILDINGS,
        units: &STANDARD_UNITS,
        wonders: &STANDARD_WONDERS,
        rush_gold_per_production: 2,
        wealth_project_divisor: 2,
        research_project_divisor: 12,
        supply_density_numerator: 22,
        supply_density_denominator: 100,
        minimum_map_supply: 12,
        maximum_map_supply: 28,
    };

    /// Returns the complete canonical building catalog.
    #[must_use]
    pub const fn buildings(self) -> &'static [BuildingProductionDefinition] {
        self.buildings
    }
    /// Returns the complete canonical unit-production catalog.
    #[must_use]
    pub const fn units(self) -> &'static [UnitProductionDefinition] {
        self.units
    }
    /// Returns the complete canonical wonder catalog.
    #[must_use]
    pub const fn wonders(self) -> &'static [WonderProductionDefinition] {
        self.wonders
    }
    /// Finds one building definition.
    #[must_use]
    pub fn building(self, value: CityBuildingType) -> Option<BuildingProductionDefinition> {
        self.buildings
            .iter()
            .copied()
            .find(|item| item.building == value)
    }
    /// Finds one unit definition.
    #[must_use]
    pub fn unit(self, value: UnitKind) -> Option<UnitProductionDefinition> {
        self.units.iter().copied().find(|item| item.unit == value)
    }
    /// Finds one wonder definition.
    #[must_use]
    pub fn wonder(self, value: WonderType) -> Option<WonderProductionDefinition> {
        self.wonders
            .iter()
            .copied()
            .find(|item| item.wonder == value)
    }
    /// Returns paced building or wonder cost, rounded upward without floats.
    #[must_use]
    pub fn building_cost(self, base: i64, pace: PaceProfile) -> Option<i64> {
        let basis_points = match pace {
            PaceProfile::Unlimited => 14_500,
            PaceProfile::Standard60 => 8_500,
            PaceProfile::Normal90 => 9_200,
            PaceProfile::Long120 => 10_000,
        };
        scale_cost(base, basis_points)
    }
    /// Returns paced unit cost, rounded upward without floats.
    #[must_use]
    pub fn unit_cost(self, base: i64, pace: PaceProfile) -> Option<i64> {
        let basis_points = match pace {
            PaceProfile::Unlimited => 13_000,
            PaceProfile::Standard60 => 8_000,
            PaceProfile::Normal90 => 9_000,
            PaceProfile::Long120 => 10_000,
        };
        scale_cost(base, basis_points)
    }
    /// Returns gold charged for one rushed production point.
    #[must_use]
    pub const fn rush_gold_per_production(self) -> i64 {
        self.rush_gold_per_production
    }
    /// Returns project conversion divisor.
    #[must_use]
    pub const fn project_divisor(self, research: bool) -> i64 {
        if research {
            self.research_project_divisor
        } else {
            self.wealth_project_divisor
        }
    }
    /// Returns supply-density fixed-point fraction.
    #[must_use]
    pub const fn supply_density(self) -> (u32, u32) {
        (
            self.supply_density_numerator,
            self.supply_density_denominator,
        )
    }
    /// Returns inclusive map supply clamps.
    #[must_use]
    pub const fn map_supply_bounds(self) -> (i64, i64) {
        (self.minimum_map_supply, self.maximum_map_supply)
    }
    /// Returns specialization prerequisite building.
    #[must_use]
    pub const fn specialization_building(
        self,
        specialization: CitySpecializationType,
    ) -> CityBuildingType {
        match specialization {
            CitySpecializationType::Growth => CityBuildingType::Granary,
            CitySpecializationType::Industry => CityBuildingType::Workshop,
            CitySpecializationType::Commerce => CityBuildingType::MerchantHall,
            CitySpecializationType::Science => CityBuildingType::Archive,
            CitySpecializationType::Military => CityBuildingType::Barracks,
        }
    }
}

fn scale_cost(base: i64, basis_points: i64) -> Option<i64> {
    if base <= 0 {
        return Some(0);
    }
    base.checked_mul(basis_points)?
        .checked_add(9_999)?
        .checked_div(10_000)
        .map(|value| value.max(1))
}
