use aonw_content::RulesetDefinition;
use aonw_domain::{GameState, Unit};

use super::{EffectiveCombatStats, stats};

/// Returns current authoritative maximum health, including persistent modifiers
/// but independent of a particular opponent and terrain.
#[must_use]
pub fn unit_max_hit_points(
    state: &GameState,
    ruleset: &RulesetDefinition,
    unit: &Unit,
) -> Option<u32> {
    persistent_unit_stats(state, ruleset, unit).map(|stats| stats.hit_points)
}

fn persistent_unit_stats(
    state: &GameState,
    ruleset: &RulesetDefinition,
    unit: &Unit,
) -> Option<EffectiveCombatStats> {
    stats::for_unit(
        state,
        ruleset,
        unit,
        stats::UnitCombatSituation {
            opponent: None,
            defended_city: None,
            attacker: false,
            terrain_tags: &[],
            opponent_terrain_tags: &[],
        },
    )
}

pub(crate) fn unit_base_attack(ruleset: &RulesetDefinition, unit: &Unit) -> Option<i32> {
    stats::base_for_unit(ruleset, unit).map(|(attack, _, _)| attack)
}
