use aonw_content::TechnologyEffect;
use aonw_domain::TechnologyId;

use super::{
    TechnologyCombatModifier, TechnologyCombatStat, TechnologyEffectSummary, TechnologyQueryError,
};

pub(super) fn scaled_combat_delta(
    base: i32,
    basis_points: u32,
    technology_id: TechnologyId,
) -> Result<i32, TechnologyQueryError> {
    if base <= 0 || basis_points == 0 {
        return Ok(0);
    }
    let numerator = i64::from(base)
        .checked_mul(i64::from(basis_points))
        .ok_or(TechnologyQueryError::EffectOverflow(technology_id))?;
    let rounded = (numerator + 5_000) / 10_000;
    i32::try_from(rounded.max(1)).map_err(|_| TechnologyQueryError::EffectOverflow(technology_id))
}

pub(super) fn push_combat_modifier(
    modifiers: &mut Vec<TechnologyCombatModifier>,
    technology: &str,
    effect: &str,
    target: TechnologyCombatStat,
    delta: i32,
) {
    if delta != 0 {
        modifiers.push(TechnologyCombatModifier {
            label: format!("tech.{technology}.{effect}").into(),
            target,
            delta,
        });
    }
}

pub(super) fn apply_effect(
    summary: &mut TechnologyEffectSummary,
    technology_id: TechnologyId,
    effect: TechnologyEffect,
) -> Result<(), TechnologyQueryError> {
    let overflow = || TechnologyQueryError::EffectOverflow(technology_id);
    match effect {
        TechnologyEffect::StrategicResourceProduction { resource, amount } => {
            let current = summary
                .strategic_resource_production
                .entry(resource.domain())
                .or_default();
            *current = current.checked_add(amount).ok_or_else(overflow)?;
        }
        TechnologyEffect::GlobalGoldMultiplier { basis_points } => {
            summary.global_gold_multiplier_basis_points = summary
                .global_gold_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::CityDefenseBonus { amount } => {
            summary.city_defense_bonus = summary
                .city_defense_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyProductionMultiplier { basis_points } => {
            summary.army_production_multiplier_basis_points = summary
                .army_production_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyStrengthMultiplier { basis_points } => {
            summary.army_strength_multiplier_basis_points = summary
                .army_strength_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyCombatStatsBonus {
            attack,
            defense,
            hit_points,
        } => {
            summary.army_attack_bonus = summary
                .army_attack_bonus
                .checked_add(attack)
                .ok_or_else(overflow)?;
            summary.army_defense_bonus = summary
                .army_defense_bonus
                .checked_add(defense)
                .ok_or_else(overflow)?;
            summary.army_hit_points_bonus = summary
                .army_hit_points_bonus
                .checked_add(hit_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::MaxControlledHexesBonus { amount } => {
            summary.max_controlled_hexes_bonus = summary
                .max_controlled_hexes_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::CityScienceBonus { amount } => {
            summary.city_science_bonus = summary
                .city_science_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
    }
    Ok(())
}
