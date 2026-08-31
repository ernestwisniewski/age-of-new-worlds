use serde::Serialize;

use aonw_domain::{CityBuildingType, PaceProfile, TechnologyId};

use crate::{ResourceType, TerrainType};

/// Integer city yield used by deterministic economy rules.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EconomyYield {
    food: i64,
    production: i64,
    gold: i64,
    defense: i64,
}

#[allow(missing_docs)]
impl EconomyYield {
    /// Creates one exact integer yield value.
    #[must_use]
    pub const fn new(food: i64, production: i64, gold: i64, defense: i64) -> Self {
        Self {
            food,
            production,
            gold,
            defense,
        }
    }
    #[must_use]
    pub const fn food(self) -> i64 {
        self.food
    }
    #[must_use]
    pub const fn production(self) -> i64 {
        self.production
    }
    #[must_use]
    pub const fn gold(self) -> i64 {
        self.gold
    }
    #[must_use]
    pub const fn defense(self) -> i64 {
        self.defense
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct TerrainYieldDefinition {
    terrain: TerrainType,
    value: EconomyYield,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct ResourceYieldDefinition {
    resource: ResourceType,
    value: EconomyYield,
}

/// Fixed-point stability effects selected from the current stability net.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StabilityModifierDefinition {
    production_basis_points: u32,
    gold_basis_points: u32,
    food_bonus: i64,
    halts_growth: bool,
}

#[allow(missing_docs)]
impl StabilityModifierDefinition {
    #[must_use]
    pub const fn production_basis_points(self) -> u32 {
        self.production_basis_points
    }
    #[must_use]
    pub const fn gold_basis_points(self) -> u32 {
        self.gold_basis_points
    }
    #[must_use]
    pub const fn food_bonus(self) -> i64 {
        self.food_bonus
    }
    #[must_use]
    pub const fn halts_growth(self) -> bool {
        self.halts_growth
    }
}

/// Hash-addressed city economy and growth balance.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EconomyBalance {
    city_center_yield: EconomyYield,
    river_yield: EconomyYield,
    terrain_yields: &'static [TerrainYieldDefinition],
    resource_yields: &'static [ResourceYieldDefinition],
    passive_improvement_numerator: u32,
    passive_improvement_denominator: u32,
    food_upkeep_per_population: i64,
    growth_base_cost: i64,
    growth_cost_per_population: i64,
    growth_cost_per_controlled_hex: i64,
    base_free_units: i64,
    free_units_per_city: i64,
    base_order: i64,
    stability_cost_per_city: i64,
    population_cost_threshold: i64,
    stability_cost_per_population: i64,
    conquered_city_cost: i64,
    cohesion_reach_radius: u32,
    frontier_cost_per_hex: i64,
    disconnected_city_cost: i64,
    war_weariness_cap: i64,
    war_weariness_attack_free_per_turn: u32,
    war_weariness_per_city_lost: i64,
    war_weariness_peace_decay: i64,
    war_weariness_treaty_decay: i64,
    relative_standing_offset: i64,
    hegemony_k_basis_points: u32,
    hegemony_tax_points_per_cost: i64,
    stability_per_order_building: i64,
    stability_per_order_technology: i64,
    stability_per_luxury_resource: i64,
    stability_per_stored_artifact: i64,
    order_buildings: &'static [&'static str],
    order_technologies: &'static [&'static str],
    luxury_resources: &'static [&'static str],
    content_stability_threshold: i64,
    unrest_stability_threshold: i64,
    content_stability: StabilityModifierDefinition,
    stable_stability: StabilityModifierDefinition,
    strained_stability: StabilityModifierDefinition,
    unrest_stability: StabilityModifierDefinition,
}

macro_rules! value {
    ($food:expr, $production:expr, $gold:expr, $defense:expr) => {
        EconomyYield {
            food: $food,
            production: $production,
            gold: $gold,
            defense: $defense,
        }
    };
}

macro_rules! terrain {
    ($terrain:expr, $value:expr) => {
        TerrainYieldDefinition {
            terrain: $terrain,
            value: $value,
        }
    };
}

macro_rules! resource {
    ($resource:expr, $value:expr) => {
        ResourceYieldDefinition {
            resource: $resource,
            value: $value,
        }
    };
}

macro_rules! modifier {
    ($production:expr, $gold:expr, $food:expr, $halts:expr) => {
        StabilityModifierDefinition {
            production_basis_points: $production,
            gold_basis_points: $gold,
            food_bonus: $food,
            halts_growth: $halts,
        }
    };
}

impl EconomyBalance {
    pub(super) const STANDARD: Self = Self {
        city_center_yield: value!(2, 1, 0, 0),
        river_yield: value!(1, 0, 0, 0),
        terrain_yields: &STANDARD_TERRAIN_YIELDS,
        resource_yields: &STANDARD_RESOURCE_YIELDS,
        passive_improvement_numerator: 1,
        passive_improvement_denominator: 2,
        food_upkeep_per_population: 1,
        growth_base_cost: 10,
        growth_cost_per_population: 4,
        growth_cost_per_controlled_hex: 3,
        base_free_units: 2,
        free_units_per_city: 2,
        base_order: 6,
        stability_cost_per_city: 2,
        population_cost_threshold: 6,
        stability_cost_per_population: 1,
        conquered_city_cost: 3,
        cohesion_reach_radius: 4,
        frontier_cost_per_hex: 1,
        disconnected_city_cost: 1,
        war_weariness_cap: 8,
        war_weariness_attack_free_per_turn: 1,
        war_weariness_per_city_lost: 2,
        war_weariness_peace_decay: 1,
        war_weariness_treaty_decay: 2,
        relative_standing_offset: 3,
        hegemony_k_basis_points: 16_000,
        hegemony_tax_points_per_cost: 5,
        stability_per_order_building: 1,
        stability_per_order_technology: 2,
        stability_per_luxury_resource: 1,
        stability_per_stored_artifact: 1,
        order_buildings: &ORDER_BUILDINGS,
        order_technologies: &ORDER_TECHNOLOGIES,
        luxury_resources: &LUXURY_RESOURCES,
        content_stability_threshold: 4,
        unrest_stability_threshold: -4,
        content_stability: modifier!(10_000, 10_000, 1, false),
        stable_stability: modifier!(10_000, 10_000, 0, false),
        strained_stability: modifier!(10_000, 9_000, 0, true),
        unrest_stability: modifier!(7_500, 7_500, 0, true),
    };

    /// Returns the yield of a city center independently of map terrain.
    #[must_use]
    pub const fn city_center_yield(self) -> EconomyYield {
        self.city_center_yield
    }

    /// Returns the additive yield of the river terrain tag.
    #[must_use]
    pub const fn river_yield(self) -> EconomyYield {
        self.river_yield
    }

    /// Finds the base yield for the authored economic terrain.
    #[must_use]
    pub fn terrain_yield(self, terrain: TerrainType) -> EconomyYield {
        self.terrain_yields
            .iter()
            .find(|definition| definition.terrain == terrain)
            .map_or(EconomyYield::default(), |definition| definition.value)
    }

    /// Finds the additive yield for a map resource.
    #[must_use]
    pub fn resource_yield(self, resource: ResourceType) -> EconomyYield {
        self.resource_yields
            .iter()
            .find(|definition| definition.resource == resource)
            .map_or(EconomyYield::default(), |definition| definition.value)
    }

    /// Returns the passive-improvement yield scale as an integer fraction.
    #[must_use]
    pub const fn passive_improvement_scale(self) -> (u32, u32) {
        (
            self.passive_improvement_numerator,
            self.passive_improvement_denominator,
        )
    }

    /// Returns per-population food upkeep.
    #[must_use]
    pub const fn food_upkeep_per_population(self) -> i64 {
        self.food_upkeep_per_population
    }

    /// Computes checked city growth cost.
    #[must_use]
    pub fn growth_cost(self, population: i64, territory_hex_count: usize) -> Option<i64> {
        let territory = i64::try_from(territory_hex_count).ok()?;
        self.growth_cost_per_population
            .checked_mul(population)?
            .checked_add(self.growth_cost_per_controlled_hex.checked_mul(territory)?)?
            .checked_add(self.growth_base_cost)
    }

    /// Computes the paced city growth cost with exact ceiling arithmetic.
    #[must_use]
    pub fn paced_growth_cost(
        self,
        population: i64,
        territory_hex_count: usize,
        pace: PaceProfile,
    ) -> Option<i64> {
        let basis_points = match pace {
            PaceProfile::Unlimited => 11_500,
            PaceProfile::Standard60 => 8_500,
            PaceProfile::Normal90 => 9_200,
            PaceProfile::Long120 => 10_000,
        };
        let base = self.growth_cost(population, territory_hex_count)?;
        base.checked_mul(basis_points)?
            .checked_add(9_999)?
            .checked_div(10_000)
            .map(|value| value.max(1))
    }

    /// Returns free upkeep-bearing units for the current city count.
    #[must_use]
    pub fn free_unit_count(self, city_count: usize) -> Option<i64> {
        self.free_units_per_city
            .checked_mul(i64::try_from(city_count).ok()?)?
            .checked_add(self.base_free_units)
    }

    /// Returns the stability source/cost constants in one content-owned value.
    #[must_use]
    pub const fn stability_values(self) -> StabilityValues {
        StabilityValues {
            base_order: self.base_order,
            cost_per_city: self.stability_cost_per_city,
            population_cost_threshold: self.population_cost_threshold,
            cost_per_population: self.stability_cost_per_population,
            conquered_city_cost: self.conquered_city_cost,
            cohesion_reach_radius: self.cohesion_reach_radius,
            frontier_cost_per_hex: self.frontier_cost_per_hex,
            disconnected_city_cost: self.disconnected_city_cost,
            war_weariness_cap: self.war_weariness_cap,
            war_weariness_attack_free_per_turn: self.war_weariness_attack_free_per_turn,
            war_weariness_per_city_lost: self.war_weariness_per_city_lost,
            war_weariness_peace_decay: self.war_weariness_peace_decay,
            war_weariness_treaty_decay: self.war_weariness_treaty_decay,
            relative_standing_offset: self.relative_standing_offset,
            hegemony_k_basis_points: self.hegemony_k_basis_points,
            hegemony_tax_points_per_cost: self.hegemony_tax_points_per_cost,
            stability_per_order_building: self.stability_per_order_building,
            stability_per_order_technology: self.stability_per_order_technology,
            stability_per_luxury_resource: self.stability_per_luxury_resource,
            stability_per_stored_artifact: self.stability_per_stored_artifact,
        }
    }

    /// Returns the inclusive lower bound of the content stability band.
    #[must_use]
    pub const fn content_stability_threshold(self) -> i64 {
        self.content_stability_threshold
    }

    /// Returns the inclusive upper bound of the unrest stability band.
    #[must_use]
    pub const fn unrest_stability_threshold(self) -> i64 {
        self.unrest_stability_threshold
    }

    /// Returns whether a building contributes order stability.
    #[must_use]
    pub fn is_order_building(self, value: CityBuildingType) -> bool {
        matches!(
            value,
            CityBuildingType::TownHall
                | CityBuildingType::Courthouse
                | CityBuildingType::GovernorsOffice
                | CityBuildingType::Ministries
                | CityBuildingType::Monument
        )
    }

    /// Returns whether a technology contributes order stability.
    #[must_use]
    pub fn is_order_technology(self, value: TechnologyId) -> bool {
        matches!(
            value,
            TechnologyId::Law | TechnologyId::CivilService | TechnologyId::Administration
        )
    }

    /// Returns whether a resource contributes distinct luxury stability.
    #[must_use]
    pub fn is_luxury_resource(self, value: ResourceType) -> bool {
        matches!(
            value,
            ResourceType::Gold
                | ResourceType::Silver
                | ResourceType::Gems
                | ResourceType::Silk
                | ResourceType::Spices
                | ResourceType::Cotton
                | ResourceType::Grapes
                | ResourceType::Ivory
                | ResourceType::Pearls
                | ResourceType::Coffee
                | ResourceType::Cocoa
                | ResourceType::Tobacco
                | ResourceType::Sugar
        )
    }

    /// Resolves stability effects without floating-point arithmetic.
    #[must_use]
    pub const fn stability_modifier(self, stability_net: i64) -> StabilityModifierDefinition {
        if stability_net >= self.content_stability_threshold {
            self.content_stability
        } else if stability_net <= self.unrest_stability_threshold {
            self.unrest_stability
        } else if stability_net < 0 {
            self.strained_stability
        } else {
            self.stable_stability
        }
    }
}

/// Exact content-owned constants used by per-turn stability progression.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StabilityValues {
    pub base_order: i64,
    pub cost_per_city: i64,
    pub population_cost_threshold: i64,
    pub cost_per_population: i64,
    pub conquered_city_cost: i64,
    pub cohesion_reach_radius: u32,
    pub frontier_cost_per_hex: i64,
    pub disconnected_city_cost: i64,
    pub war_weariness_cap: i64,
    pub war_weariness_attack_free_per_turn: u32,
    pub war_weariness_per_city_lost: i64,
    pub war_weariness_peace_decay: i64,
    pub war_weariness_treaty_decay: i64,
    pub relative_standing_offset: i64,
    pub hegemony_k_basis_points: u32,
    pub hegemony_tax_points_per_cost: i64,
    pub stability_per_order_building: i64,
    pub stability_per_order_technology: i64,
    pub stability_per_luxury_resource: i64,
    pub stability_per_stored_artifact: i64,
}

const ORDER_BUILDINGS: [&str; 5] = [
    "townHall",
    "courthouse",
    "governorsOffice",
    "ministries",
    "monument",
];
const ORDER_TECHNOLOGIES: [&str; 3] = ["law", "civilService", "administration"];
const LUXURY_RESOURCES: [&str; 13] = [
    "gold", "silver", "gems", "silk", "spices", "cotton", "grapes", "ivory", "pearls", "coffee",
    "cocoa", "tobacco", "sugar",
];

const ZERO: EconomyYield = value!(0, 0, 0, 0);
const STANDARD_TERRAIN_YIELDS: [TerrainYieldDefinition; 14] = [
    terrain!(TerrainType::Ocean, ZERO),
    terrain!(TerrainType::Coast, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Lake, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Plains, value!(1, 1, 0, 0)),
    terrain!(TerrainType::Grassland, value!(2, 0, 0, 0)),
    terrain!(TerrainType::Desert, ZERO),
    terrain!(TerrainType::Tundra, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Snow, ZERO),
    terrain!(TerrainType::Mountain, ZERO),
    terrain!(TerrainType::Hills, value!(0, 2, 0, 0)),
    terrain!(TerrainType::Wetlands, value!(2, 0, 0, 0)),
    terrain!(TerrainType::Jungle, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Forest, value!(1, 1, 0, 0)),
    terrain!(TerrainType::River, ZERO),
];

const STANDARD_RESOURCE_YIELDS: [ResourceYieldDefinition; 29] = [
    resource!(ResourceType::Wheat, value!(2, 0, 0, 0)),
    resource!(ResourceType::Fish, value!(2, 0, 0, 0)),
    resource!(ResourceType::Deer, value!(1, 1, 0, 0)),
    resource!(ResourceType::Sheep, value!(1, 1, 0, 0)),
    resource!(ResourceType::Rice, value!(2, 0, 0, 0)),
    resource!(ResourceType::Cow, value!(1, 1, 0, 0)),
    resource!(ResourceType::Apple, value!(2, 0, 0, 0)),
    resource!(ResourceType::Banana, value!(2, 0, 0, 0)),
    resource!(ResourceType::Citrus, value!(2, 0, 0, 0)),
    resource!(ResourceType::Gold, ZERO),
    resource!(ResourceType::Silver, ZERO),
    resource!(ResourceType::Gems, ZERO),
    resource!(ResourceType::Silk, ZERO),
    resource!(ResourceType::Spices, ZERO),
    resource!(ResourceType::Cotton, ZERO),
    resource!(ResourceType::Grapes, ZERO),
    resource!(ResourceType::Ivory, ZERO),
    resource!(ResourceType::Pearls, ZERO),
    resource!(ResourceType::Coffee, ZERO),
    resource!(ResourceType::Cocoa, ZERO),
    resource!(ResourceType::Tobacco, ZERO),
    resource!(ResourceType::Sugar, ZERO),
    resource!(ResourceType::Iron, value!(0, 2, 0, 0)),
    resource!(ResourceType::Coal, ZERO),
    resource!(ResourceType::Oil, ZERO),
    resource!(ResourceType::Aluminium, ZERO),
    resource!(ResourceType::Uranium, ZERO),
    resource!(ResourceType::Horses, ZERO),
    resource!(ResourceType::Marble, value!(0, 2, 0, 0)),
];
