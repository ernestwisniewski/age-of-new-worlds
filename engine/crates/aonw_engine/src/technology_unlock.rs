use std::collections::BTreeMap;

use aonw_content::{RulesetDefinition, TechnologyDefinition, TechnologyEffect, TechnologyUnlock};
use aonw_domain::{
    CityBuildingType, FieldImprovementKind, PaceProfile, PlayerResearchState, ResourceType,
    TechnologyId, UnitKind, WonderType,
};

mod effect;

use effect::{apply_effect, push_combat_modifier, scaled_combat_delta};

const BASIS_POINTS: u128 = 10_000;

/// Read-only availability of one technology for a player.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TechnologyAvailability {
    Unlocked,
    Active,
    Available,
    LockedByPrerequisites,
    LockedByTechnology,
}

/// Aggregated ruleset effects from all unlocked technologies.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TechnologyEffectSummary {
    /// Production added per controlled strategic resource.
    pub strategic_resource_production: BTreeMap<ResourceType, i32>,
    /// Global gold multiplier in basis points.
    pub global_gold_multiplier_basis_points: u32,
    /// Flat city-defense bonus.
    pub city_defense_bonus: i32,
    /// Army production multiplier in basis points.
    pub army_production_multiplier_basis_points: u32,
    /// Army strength multiplier in basis points.
    pub army_strength_multiplier_basis_points: u32,
    /// Flat army attack bonus.
    pub army_attack_bonus: i32,
    /// Flat army defense bonus.
    pub army_defense_bonus: i32,
    /// Flat army hit-point bonus.
    pub army_hit_points_bonus: i32,
    /// Additional controlled hexes per city.
    pub max_controlled_hexes_bonus: i32,
    /// Flat science bonus per city.
    pub city_science_bonus: i32,
}

/// Combat statistic changed by one ruleset-owned technology effect.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TechnologyCombatStat {
    /// Attack strength.
    Attack,
    /// Defense strength.
    Defense,
    /// Maximum hit points.
    HitPoints,
}

/// One exact ordered technology modifier consumed by combat.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TechnologyCombatModifier {
    /// Stable content label.
    pub label: Box<str>,
    /// Affected combat statistic.
    pub target: TechnologyCombatStat,
    /// Signed additive delta after any fixed-point scaling.
    pub delta: i32,
}

/// Invalid technology-query input or incomplete ruleset content.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TechnologyQueryError {
    TechnologyNotInRuleset(TechnologyId),
    CostOverflow(TechnologyId),
    EffectOverflow(TechnologyId),
}

impl core::fmt::Display for TechnologyQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TechnologyNotInRuleset(id) => {
                write!(formatter, "technology is absent from ruleset: {id:?}")
            }
            Self::CostOverflow(id) => write!(formatter, "research cost exceeds u32 for {id:?}"),
            Self::EffectOverflow(id) => write!(formatter, "technology effects overflow for {id:?}"),
        }
    }
}

impl std::error::Error for TechnologyQueryError {}

/// Single authoritative read-only query for research prerequisites and gates.
#[derive(Clone, Copy, Debug)]
pub struct TechnologyUnlockQuery<'query> {
    ruleset: &'query RulesetDefinition,
    research: &'query PlayerResearchState,
}

impl<'query> TechnologyUnlockQuery<'query> {
    /// Binds immutable ruleset content to one player's canonical research state.
    #[must_use]
    pub const fn new(
        ruleset: &'query RulesetDefinition,
        research: &'query PlayerResearchState,
    ) -> Self {
        Self { ruleset, research }
    }

    /// Returns availability after checking unlocked, exclusions, prerequisites, then active state.
    ///
    /// # Errors
    ///
    /// Returns an error when the ruleset omits the requested technology.
    pub fn availability(
        self,
        technology_id: TechnologyId,
    ) -> Result<TechnologyAvailability, TechnologyQueryError> {
        if self.is_unlocked(technology_id) {
            return Ok(TechnologyAvailability::Unlocked);
        }
        let definition = self.definition(technology_id)?;
        if definition
            .blocked_by()
            .iter()
            .any(|blocked| self.is_unlocked(blocked.domain()))
        {
            return Ok(TechnologyAvailability::LockedByTechnology);
        }
        if !definition
            .prerequisites()
            .iter()
            .all(|required| self.is_unlocked(required.domain()))
        {
            return Ok(TechnologyAvailability::LockedByPrerequisites);
        }
        if self.research.active_technology_id() == Some(technology_id) {
            return Ok(TechnologyAvailability::Active);
        }
        Ok(TechnologyAvailability::Available)
    }

    /// Computes the content-defined cost using deterministic fixed-point arithmetic.
    ///
    /// A fulfilled boost applies the definition's first discount only when that
    /// technology actually declares a boost.
    ///
    /// # Errors
    ///
    /// Returns an error for a missing definition or a result above `u32`.
    pub fn effective_cost(
        self,
        technology_id: TechnologyId,
        city_count: u32,
        fulfilled_boost: bool,
    ) -> Result<u32, TechnologyQueryError> {
        let definition = self.definition(technology_id)?;
        let discount = if fulfilled_boost {
            definition
                .boosts()
                .iter()
                .map(|boost| boost.discount_basis_points())
                .max()
                .unwrap_or(0)
        } else {
            0
        };
        self.effective_cost_with_discount(
            technology_id,
            city_count,
            discount,
            PaceProfile::Unlimited,
        )
    }

    /// Computes the exact cost for a concrete boost discount and match pace.
    /// Zero cities use the same base multiplier as one city, matching the
    /// canonical selection rule.
    ///
    /// # Errors
    ///
    /// Returns an error for missing content or checked arithmetic overflow.
    pub fn effective_cost_with_discount(
        self,
        technology_id: TechnologyId,
        city_count: u32,
        boost_discount_basis_points: u32,
        pace: PaceProfile,
    ) -> Result<u32, TechnologyQueryError> {
        let definition = self.definition(technology_id)?;
        let balance = self.ruleset.technology_cost_balance();
        let city_multiplier = BASIS_POINTS
            + u128::from(city_count.saturating_sub(1))
                * u128::from(balance.city_scaling_basis_points());
        let boost_multiplier = BASIS_POINTS - u128::from(boost_discount_basis_points.min(10_000));
        let era_multiplier = u128::from(balance.era_multiplier_basis_points(definition.era()));
        let numerator = u128::from(definition.base_cost())
            * city_multiplier
            * boost_multiplier
            * era_multiplier;
        let denominator = BASIS_POINTS * BASIS_POINTS * BASIS_POINTS;
        let rounded_up = numerator.div_ceil(denominator).max(1);
        let base = u32::try_from(rounded_up)
            .map_err(|_| TechnologyQueryError::CostOverflow(technology_id))?;
        balance
            .paced_cost(base, pace)
            .ok_or(TechnologyQueryError::CostOverflow(technology_id))
    }

    /// Returns the complete capability breakdown for a technology.
    ///
    /// # Errors
    ///
    /// Returns an error when the ruleset omits the requested technology.
    pub fn unlock_breakdown(
        self,
        technology_id: TechnologyId,
    ) -> Result<&'static [TechnologyUnlock], TechnologyQueryError> {
        Ok(self.definition(technology_id)?.unlocks())
    }

    /// Returns the technology that gates a building, or `None` for a base building.
    #[must_use]
    pub fn unlocking_technology_for_building(
        self,
        building: CityBuildingType,
    ) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::Building(value) if value.domain() == building)
        })
    }

    /// Returns whether a building is legal for the player research state.
    #[must_use]
    pub fn is_building_unlocked(self, building: CityBuildingType) -> bool {
        if building == CityBuildingType::Granary {
            return true;
        }
        self.unlocking_technology_for_building(building)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology that gates a field improvement.
    #[must_use]
    pub fn unlocking_technology_for_improvement(
        self,
        improvement: FieldImprovementKind,
    ) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::Improvement(value) if value.domain() == improvement)
        })
    }

    /// Returns whether a worker improvement is legal for the player research state.
    #[must_use]
    pub fn is_improvement_unlocked(self, improvement: FieldImprovementKind) -> bool {
        self.unlocking_technology_for_improvement(improvement)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology that gates a producible unit kind.
    #[must_use]
    pub fn unlocking_technology_for_unit(self, unit: UnitKind) -> Option<TechnologyId> {
        self.unlocking_technology(
            |unlock| matches!(unlock, TechnologyUnlock::Unit(value) if value.domain() == unit),
        )
    }

    /// Returns whether a city may produce a unit for the player research state.
    #[must_use]
    pub fn is_unit_unlocked(self, unit: UnitKind) -> bool {
        let Some(definition) = self.ruleset.unit(unit) else {
            return false;
        };
        if !definition.capabilities().producible_by_cities() {
            return false;
        }
        match self.unlocking_technology_for_unit(unit) {
            Some(technology) => self.is_unlocked(technology),
            None => matches!(
                unit,
                UnitKind::Warrior | UnitKind::Settler | UnitKind::Worker | UnitKind::Scout
            ),
        }
    }

    /// Returns the technology that gates a wonder.
    #[must_use]
    pub fn unlocking_technology_for_wonder(self, wonder: WonderType) -> Option<TechnologyId> {
        self.unlocking_technology(
            |unlock| matches!(unlock, TechnologyUnlock::Wonder(value) if value.domain() == wonder),
        )
    }

    /// Returns whether a wonder is legal for the player research state.
    #[must_use]
    pub fn is_wonder_unlocked(self, wonder: WonderType) -> bool {
        self.unlocking_technology_for_wonder(wonder)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology required to reveal a strategic resource.
    #[must_use]
    pub fn revealing_technology_for_resource(self, resource: ResourceType) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::ResourceVisibility(value) if value.domain() == resource)
        })
    }

    /// Returns whether resource identity may be disclosed to this player.
    #[must_use]
    pub fn is_resource_revealed(self, resource: ResourceType) -> bool {
        match resource {
            ResourceType::Horses
            | ResourceType::Coal
            | ResourceType::Oil
            | ResourceType::Aluminium
            | ResourceType::Uranium => self
                .revealing_technology_for_resource(resource)
                .is_some_and(|technology| self.is_unlocked(technology)),
            _ => true,
        }
    }

    /// Returns whether one canonical technology is already unlocked.
    #[must_use]
    pub fn is_technology_unlocked(self, technology_id: TechnologyId) -> bool {
        self.is_unlocked(technology_id)
    }

    /// Aggregates all unlocked technology modifiers without local combat tables.
    ///
    /// # Errors
    ///
    /// Returns an error if unlocked content is absent or additive values overflow.
    pub fn effect_summary(self) -> Result<TechnologyEffectSummary, TechnologyQueryError> {
        let mut summary = TechnologyEffectSummary::default();
        for technology_id in self.research.unlocked_technology_ids() {
            let definition = self.definition(*technology_id)?;
            for effect in definition.effects() {
                apply_effect(&mut summary, *technology_id, *effect)?;
            }
        }
        Ok(summary)
    }

    /// Returns exact per-technology combat modifiers in canonical label order.
    ///
    /// # Errors
    ///
    /// Returns an error if unlocked content is missing or scaled strength
    /// exceeds the canonical integer range.
    pub fn combat_modifiers(
        self,
        base_attack: i32,
        army_unit: bool,
        include_city_defense: bool,
    ) -> Result<Vec<TechnologyCombatModifier>, TechnologyQueryError> {
        let mut definitions = self
            .research
            .unlocked_technology_ids()
            .iter()
            .map(|technology| self.definition(*technology))
            .collect::<Result<Vec<_>, _>>()?;
        definitions.sort_unstable_by(|left, right| {
            left.label()
                .cmp(right.label())
                .then_with(|| left.id().cmp(&right.id()))
        });
        let mut modifiers = Vec::new();
        for definition in definitions {
            for effect in definition.effects() {
                match *effect {
                    TechnologyEffect::ArmyStrengthMultiplier { basis_points } => {
                        let delta =
                            scaled_combat_delta(base_attack, basis_points, definition.id())?;
                        push_combat_modifier(
                            &mut modifiers,
                            definition.label(),
                            "armyStrength",
                            TechnologyCombatStat::Attack,
                            delta,
                        );
                    }
                    TechnologyEffect::CityDefenseBonus { amount } if include_city_defense => {
                        push_combat_modifier(
                            &mut modifiers,
                            definition.label(),
                            "cityDefense",
                            TechnologyCombatStat::Defense,
                            amount,
                        );
                    }
                    TechnologyEffect::ArmyCombatStatsBonus {
                        attack,
                        defense,
                        hit_points,
                    } if army_unit => {
                        push_combat_modifier(
                            &mut modifiers,
                            definition.label(),
                            "armyAttack",
                            TechnologyCombatStat::Attack,
                            attack,
                        );
                        push_combat_modifier(
                            &mut modifiers,
                            definition.label(),
                            "armyDefense",
                            TechnologyCombatStat::Defense,
                            defense,
                        );
                        push_combat_modifier(
                            &mut modifiers,
                            definition.label(),
                            "armyHitPoints",
                            TechnologyCombatStat::HitPoints,
                            hit_points,
                        );
                    }
                    TechnologyEffect::StrategicResourceProduction { .. }
                    | TechnologyEffect::GlobalGoldMultiplier { .. }
                    | TechnologyEffect::CityDefenseBonus { .. }
                    | TechnologyEffect::ArmyProductionMultiplier { .. }
                    | TechnologyEffect::ArmyCombatStatsBonus { .. }
                    | TechnologyEffect::MaxControlledHexesBonus { .. }
                    | TechnologyEffect::CityScienceBonus { .. } => {}
                }
            }
        }
        Ok(modifiers)
    }

    pub(crate) fn definition(
        self,
        technology_id: TechnologyId,
    ) -> Result<TechnologyDefinition, TechnologyQueryError> {
        self.ruleset
            .technology(technology_id)
            .ok_or(TechnologyQueryError::TechnologyNotInRuleset(technology_id))
    }

    fn is_unlocked(self, technology_id: TechnologyId) -> bool {
        self.research
            .unlocked_technology_ids()
            .contains(&technology_id)
    }

    fn unlocking_technology(
        self,
        matches_unlock: impl Fn(TechnologyUnlock) -> bool,
    ) -> Option<TechnologyId> {
        self.ruleset.technologies().iter().find_map(|definition| {
            definition
                .unlocks()
                .iter()
                .copied()
                .any(&matches_unlock)
                .then(|| definition.id())
        })
    }
}
