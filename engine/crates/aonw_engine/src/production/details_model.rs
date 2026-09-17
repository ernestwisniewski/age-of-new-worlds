use aonw_content::{CombatStats, EconomyYield, ProductionRequirement, ResourceType};
use aonw_domain::{CityId, CityProductionTarget, MovementUnits, StrategicResourceStockpile};

use super::{ProductionOption, ProductionOptionsQuery};
use crate::{EffectiveCombatStats, YieldValue};

/// Revision-bound inspection of one production target in an owned city.
#[derive(Clone, Copy, Debug)]
pub struct ProductionDetailsQuery<'query> {
    pub(super) city: ProductionOptionsQuery<'query>,
    pub(super) target: CityProductionTarget,
}

impl<'query> ProductionDetailsQuery<'query> {
    /// Creates a read-only target inspection.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city: &'query CityId,
        target: CityProductionTarget,
    ) -> Self {
        Self {
            city: ProductionOptionsQuery::new(expected_revision, city),
            target,
        }
    }
}

/// Exact local result, with no foreign construction or city information.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionDetails {
    /// Revision used for every value.
    pub revision: u64,
    /// City whose owner is the authenticated recipient.
    pub city_id: CityId,
    /// The same cost, forecast and availability as the production catalog.
    pub option: ProductionOption,
    /// Typed rule content and current local impact.
    pub effects: ProductionTargetEffects,
}

/// Effects for an inspected target; project output is already in its forecast.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ProductionTargetEffects {
    /// Building rules and before/after settlement output.
    Building(BuildingProductionDetails),
    /// Fresh unit statistics and empire supply allocation.
    Unit(UnitProductionDetails),
    /// Wonder rules without another owner's completion details.
    Wonder(WonderProductionDetails),
    /// Continuous projects have no additional construction effects.
    Project,
}

/// One conjunctive site requirement, evaluated by the command's own predicate.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionRequirementStatus {
    /// Content requirement, including alternative resource or terrain identities.
    pub requirement: ProductionRequirement,
    /// Whether the controlled city currently satisfies this requirement.
    pub met: bool,
}

/// Output from the current settlement rules, before target-specific queue bonuses.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionCityOutput {
    /// Gross food, production, gold and defense from tiles and passive effects.
    pub gross_yield: YieldValue,
    /// Food deposited after population consumption, building and stability rules.
    pub food_deposit: i64,
    /// Passive production after stability and empire multipliers.
    pub production: i64,
    /// Passive gold after technology, empire and stability multipliers.
    pub gold: i64,
    /// Passive science after building diminishing returns and the city cap.
    pub science: i64,
    /// Current maximum controlled territory.
    pub max_controlled_hexes: i64,
}

/// Building content and its conditional effect at the current city's state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct BuildingProductionDetails {
    /// All current location prerequisites.
    pub requirements: Box<[ProductionRequirementStatus]>,
    /// Flat gross city contribution from this building alone.
    pub flat_yield: EconomyYield,
    /// Additional contribution per controlled river hex.
    pub river_yield_per_hex: EconomyYield,
    /// Maximum number of river contributions permitted by content.
    pub max_river_applications: u32,
    /// River contributions that apply to this city's present territory.
    pub river_applications: u32,
    /// Nominal science, before the city's diminishing returns and science cap.
    pub science_per_turn: i64,
    /// Increase of the city's territory capacity.
    pub max_controlled_hexes_delta: i64,
    /// Food-deposit multiplier; 10,000 means unchanged.
    pub food_deposit_basis_points: u32,
    /// Actual present passive output, including completed buildings.
    pub current: ProductionCityOutput,
    /// Passive output if this building is completed without other state changes.
    /// Already completed buildings have the same current and completed output.
    pub completed: ProductionCityOutput,
}

/// Fresh-unit content and persistent owner modifiers, independent of a battlefield.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitProductionDetails {
    /// Unmodified content statistics, without army, veterancy or terrain effects.
    pub base_combat: CombatStats,
    /// Persistent owner technology applied by the combat calculation.
    pub effective_combat: EffectiveCombatStats,
    /// Full movement allowance without a carried artifact.
    pub maximum_movement: MovementUnits,
    /// Base gold upkeep before empire-wide free-unit allocation.
    pub base_upkeep: i64,
    /// Supply consumed by this unit.
    pub supply_cost: i64,
    /// Current empire capacity from the production command's supply budget.
    pub supply_capacity: i64,
    /// Supply used excluding the queue being replaced in this city.
    pub supply_used_without_city_queue: i64,
    /// Alternative resources whose presence permits production.
    pub presence_resources: &'static [ResourceType],
    /// Whether the command's presence-resource condition is currently met.
    pub presence_resources_met: bool,
    /// Whether the unit's spawn-coast condition is currently met.
    pub coast_met: bool,
    /// Strategic stockpile alternatives in canonical order.
    pub resource_options: Box<[StrategicResourceStockpile]>,
    /// Affordable alternatives after refunding this city's existing reservation.
    pub affordable_resource_option_indices: Box<[u32]>,
}

/// Public wonder rules, with requirements evaluated only for the recipient's city.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WonderProductionDetails {
    /// All current location prerequisites.
    pub requirements: Box<[ProductionRequirementStatus]>,
    /// Passive contribution to the hosting city.
    pub host_yield: EconomyYield,
    /// Passive contribution to every owned city.
    pub empire_yield_per_city: EconomyYield,
    /// Additional science in every owned city.
    pub empire_science_per_city: i64,
    /// Extra empire gold multiplier in basis points.
    pub empire_gold_basis_points: u32,
    /// Extra empire production multiplier in basis points.
    pub empire_production_basis_points: u32,
    /// Stability change on completion.
    pub stability_delta: i64,
    /// Whether completion grants the active technology.
    pub grants_free_active_technology: bool,
    /// Production granted to other owned city queues on completion.
    pub production_burst: i64,
    /// Treasury grant on completion.
    pub grant_gold: i64,
}
