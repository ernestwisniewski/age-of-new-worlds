use std::io::{self, Write};

use aonw_domain::{
    MovementUnits, PlayerCountry, TechnologyId, UnitKind, UnitMovementDomain, UnitOccupancyPolicy,
};
use serde::Serialize;
use sha2::{Digest, Sha256};

use crate::{ContentHash, ScienceBalance, TechnologyCostBalance, TechnologyDefinition};

mod diplomacy;
pub use diplomacy::DiplomacyBalance;
mod outcome;
pub use outcome::OutcomeBalance;
mod worker;
pub use worker::{WorkerBalance, WorkerImprovementDefinition, WorkerYield};

/// Capabilities fixed by a ruleset for one unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UnitCapabilities {
    /// Traversal category.
    pub movement_domain: UnitMovementDomainValue,
    flags: u8,
}

impl UnitCapabilities {
    const PRODUCIBLE: u8 = 1 << 0;
    const GAINS_EXPERIENCE: u8 = 1 << 1;
    const MILITARY: u8 = 1 << 2;
    const RECON: u8 = 1 << 3;
    const USES_TRADE_ROUTES: u8 = 1 << 4;

    /// Returns whether cities may produce the unit.
    #[must_use]
    pub const fn producible_by_cities(self) -> bool {
        self.flags & Self::PRODUCIBLE != 0
    }
    /// Returns whether the unit gains combat experience.
    #[must_use]
    pub const fn gains_experience(self) -> bool {
        self.flags & Self::GAINS_EXPERIENCE != 0
    }
    /// Returns whether the unit participates in combat as military.
    #[must_use]
    pub const fn military(self) -> bool {
        self.flags & Self::MILITARY != 0
    }
    /// Returns whether the unit has recon behavior.
    #[must_use]
    pub const fn recon(self) -> bool {
        self.flags & Self::RECON != 0
    }
    /// Returns whether manual movement is replaced by trade routes.
    #[must_use]
    pub const fn uses_trade_routes(self) -> bool {
        self.flags & Self::USES_TRADE_ROUTES != 0
    }
}

/// Stable serialized movement domain owned by content.
#[allow(dead_code, missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitMovementDomainValue {
    Land,
    Naval,
    Air,
}

impl UnitMovementDomainValue {
    /// Maps content configuration to the framework-independent domain value.
    #[must_use]
    pub const fn domain(self) -> UnitMovementDomain {
        match self {
            Self::Land => UnitMovementDomain::Land,
            Self::Naval => UnitMovementDomain::Naval,
            Self::Air => UnitMovementDomain::Air,
        }
    }
}

/// Immutable ruleset entry for one canonical unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UnitDefinition {
    kind: UnitKindValue,
    maximum_movement_units: u32,
    artifact_movement_units: u32,
    score_value: u32,
    capabilities: UnitCapabilities,
    combat: CombatStats,
}

impl UnitDefinition {
    /// Returns the unit kind.
    #[must_use]
    pub const fn kind(self) -> UnitKind {
        self.kind.domain()
    }
    /// Returns capabilities.
    #[must_use]
    pub const fn capabilities(self) -> UnitCapabilities {
        self.capabilities
    }
    /// Returns canonical base combat statistics.
    #[must_use]
    pub const fn combat(self) -> CombatStats {
        self.combat
    }
    /// Returns the base empire-score value of one surviving unit.
    #[must_use]
    pub const fn score_value(self) -> u32 {
        self.score_value
    }
    /// Returns movement allowance for the current carried-artifact state.
    #[must_use]
    pub const fn maximum_movement(self, carries_artifact: bool) -> MovementUnits {
        MovementUnits::new(if carries_artifact {
            self.artifact_movement_units
        } else {
            self.maximum_movement_units
        })
    }
}

/// Immutable base combat statistics for one unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CombatStats {
    attack: i32,
    defense: i32,
    hit_points: u32,
    range: u32,
    mobility: u32,
}

impl CombatStats {
    /// Returns base attack strength.
    #[must_use]
    pub const fn attack(self) -> i32 {
        self.attack
    }
    /// Returns base defense strength.
    #[must_use]
    pub const fn defense(self) -> i32 {
        self.defense
    }
    /// Returns maximum hit points.
    #[must_use]
    pub const fn hit_points(self) -> u32 {
        self.hit_points
    }
    /// Returns maximum attack range in hexes.
    #[must_use]
    pub const fn range(self) -> u32 {
        self.range
    }
    /// Returns combat mobility used by retreat rules.
    #[must_use]
    pub const fn mobility(self) -> u32 {
        self.mobility
    }
}

/// Immutable standard combat balance shared by preview and resolution.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CombatBalance {
    variance: u32,
    ranged_retaliation_percent: u32,
    retreat_threshold_percent: u32,
    defended_city_unit_defense_bonus: i32,
    mixed_commander_army_attack_bonus: i32,
    city: CombatStats,
}

impl CombatBalance {
    /// Returns symmetric random damage variance.
    #[must_use]
    pub const fn variance(self) -> u32 {
        self.variance
    }
    /// Returns ranged retaliation strength in percent.
    #[must_use]
    pub const fn ranged_retaliation_percent(self) -> u32 {
        self.ranged_retaliation_percent
    }
    /// Returns the strict retreat threshold in percent of maximum health.
    #[must_use]
    pub const fn retreat_threshold_percent(self) -> u32 {
        self.retreat_threshold_percent
    }
    /// Returns the bonus for a unit defending an owned city center.
    #[must_use]
    pub const fn defended_city_unit_defense_bonus(self) -> i32 {
        self.defended_city_unit_defense_bonus
    }
    /// Returns the commander bonus for a mixed warrior/archer army.
    #[must_use]
    pub const fn mixed_commander_army_attack_bonus(self) -> i32 {
        self.mixed_commander_army_attack_bonus
    }
    /// Returns canonical city combat statistics.
    #[must_use]
    pub const fn city(self) -> CombatStats {
        self.city
    }
}

/// Stable serialized unit kind owned by content canonicalization.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
enum UnitKindValue {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

impl UnitKindValue {
    const fn domain(self) -> UnitKind {
        match self {
            Self::Commander => UnitKind::Commander,
            Self::Warrior => UnitKind::Warrior,
            Self::Archer => UnitKind::Archer,
            Self::Settler => UnitKind::Settler,
            Self::Worker => UnitKind::Worker,
            Self::Merchant => UnitKind::Merchant,
            Self::Scout => UnitKind::Scout,
            Self::Spearman => UnitKind::Spearman,
            Self::Cavalry => UnitKind::Cavalry,
            Self::Catapult => UnitKind::Catapult,
            Self::HeavyInfantry => UnitKind::HeavyInfantry,
            Self::FieldCannon => UnitKind::FieldCannon,
            Self::Rifleman => UnitKind::Rifleman,
            Self::Tank => UnitKind::Tank,
            Self::ScoutShip => UnitKind::ScoutShip,
            Self::Warship => UnitKind::Warship,
            Self::ReconPlane => UnitKind::ReconPlane,
        }
    }
}

/// Immutable, hash-addressed simulation rules.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RulesetDefinition {
    schema_version: u16,
    ruleset_id: &'static str,
    occupancy_policy: UnitOccupancyPolicyValue,
    combat: CombatBalance,
    city: CityBalance,
    diplomacy: DiplomacyBalance,
    economy: EconomyBalance,
    outcome: OutcomeBalance,
    production: ProductionBalance,
    worker: WorkerBalance,
    city_name_sets: &'static [CityNameSet],
    unit_definitions: &'static [UnitDefinition],
    science_balance: ScienceBalance,
    technology_cost_balance: TechnologyCostBalance,
    technology_definitions: &'static [TechnologyDefinition],
}

impl RulesetDefinition {
    /// Returns the built-in ruleset matching current movement behavior.
    #[must_use]
    pub const fn standard() -> &'static Self {
        &STANDARD_RULESET
    }

    /// Returns the stable identifier.
    #[must_use]
    pub fn ruleset_id(&self) -> &str {
        self.ruleset_id
    }

    /// Returns the unit occupancy policy.
    #[must_use]
    pub const fn occupancy_policy(&self) -> UnitOccupancyPolicy {
        self.occupancy_policy.domain()
    }

    /// Returns immutable combat balance.
    #[must_use]
    pub const fn combat(&self) -> CombatBalance {
        self.combat
    }

    /// Returns immutable city and territory balance.
    #[must_use]
    pub const fn city(&self) -> CityBalance {
        self.city
    }

    /// Returns immutable diplomacy proposal and relation balance.
    #[must_use]
    pub const fn diplomacy(&self) -> DiplomacyBalance {
        self.diplomacy
    }

    /// Returns immutable city economy and growth balance.
    #[must_use]
    pub const fn economy(&self) -> EconomyBalance {
        self.economy
    }

    /// Returns immutable empire-score balance.
    #[must_use]
    pub const fn outcome(&self) -> OutcomeBalance {
        self.outcome
    }

    /// Returns immutable production costs, requirements, and effects.
    #[must_use]
    pub const fn production(&self) -> ProductionBalance {
        self.production
    }

    /// Returns immutable worker and infrastructure balance.
    #[must_use]
    pub const fn worker(&self) -> WorkerBalance {
        self.worker
    }

    /// Returns a deterministic country name, cycling with a numeric suffix.
    #[must_use]
    pub fn city_name(&self, country: PlayerCountry, sequence: usize) -> String {
        let names = self
            .city_name_sets
            .iter()
            .copied()
            .find(|set| set.country() == country)
            .or_else(|| self.city_name_sets.first().copied())
            .map_or(&[][..], CityNameSet::names);
        let Some(base) = names.get(sequence.saturating_sub(1) % names.len().max(1)) else {
            return format!("city_{}", sequence.max(1));
        };
        let cycle = sequence.saturating_sub(1) / names.len();
        if cycle == 0 {
            (*base).to_owned()
        } else {
            format!("{base} {}", cycle.saturating_add(1))
        }
    }

    /// Finds a definition by canonical kind.
    #[must_use]
    pub fn unit(&self, kind: UnitKind) -> Option<UnitDefinition> {
        self.unit_definitions
            .iter()
            .copied()
            .find(|definition| definition.kind() == kind)
    }

    /// Returns every technology in canonical catalog order.
    #[must_use]
    pub const fn technologies(&self) -> &'static [TechnologyDefinition] {
        self.technology_definitions
    }

    /// Finds a technology definition by canonical identity.
    #[must_use]
    pub fn technology(&self, id: TechnologyId) -> Option<TechnologyDefinition> {
        self.technology_definitions
            .iter()
            .copied()
            .find(|definition| definition.id() == id)
    }

    /// Returns deterministic research-cost balance.
    #[must_use]
    pub const fn technology_cost_balance(&self) -> TechnologyCostBalance {
        self.technology_cost_balance
    }

    /// Returns deterministic per-turn science balance.
    #[must_use]
    pub const fn science_balance(&self) -> ScienceBalance {
        self.science_balance
    }

    /// Returns the configured movement allowance for one unit.
    #[must_use]
    pub fn maximum_movement(
        &self,
        kind: UnitKind,
        carries_artifact: bool,
    ) -> Option<MovementUnits> {
        self.unit(kind)
            .map(|definition| definition.maximum_movement(carries_artifact))
    }

    /// Computes SHA-256 over stable compact ruleset JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical serialization fails.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(&mut writer, self)?;
        Ok(ContentHash(writer.0.finalize().into()))
    }

    /// Computes SHA-256 over the canonical technology balance and catalog.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical serialization fails.
    pub fn technology_catalog_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(
            &mut writer,
            &CanonicalTechnologyCatalog {
                science_balance: self.science_balance,
                cost_balance: self.technology_cost_balance,
                definitions: self.technology_definitions,
            },
        )?;
        Ok(ContentHash(writer.0.finalize().into()))
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CanonicalTechnologyCatalog {
    science_balance: ScienceBalance,
    cost_balance: TechnologyCostBalance,
    definitions: &'static [TechnologyDefinition],
}

/// Stable serialized occupancy policy owned by content.
#[allow(dead_code, missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
enum UnitOccupancyPolicyValue {
    Exclusive,
    FriendlyStacking,
}

impl UnitOccupancyPolicyValue {
    const fn domain(self) -> UnitOccupancyPolicy {
        match self {
            Self::Exclusive => UnitOccupancyPolicy::Exclusive,
            Self::FriendlyStacking => UnitOccupancyPolicy::FriendlyStacking,
        }
    }
}

struct HashWriter(Sha256);
impl Write for HashWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.0.update(buffer);
        Ok(buffer.len())
    }
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

mod standard;

mod city;
use city::PlayerCountryValue;
pub use city::{CityBalance, CityNameSet};

mod economy;
pub use economy::{EconomyBalance, EconomyYield, StabilityModifierDefinition, StabilityValues};

mod production;
pub use production::{
    BuildingProductionDefinition, ProductionBalance, ProductionRequirement, StrategicResourceCost,
    UnitProductionDefinition, WonderProductionDefinition,
};

use standard::STANDARD_RULESET;
#[cfg(test)]
use standard::STANDARD_UNITS;

#[cfg(test)]
mod tests;
