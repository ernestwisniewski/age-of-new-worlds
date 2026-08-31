use aonw_content::RulesetDefinition;

use super::{damage, damage_bounds, retaliation_percent, scale_damage, scaled_bounds};
use crate::EffectiveCombatStats;

#[test]
fn damage_and_retaliation_helpers_cover_boundary_values() {
    assert_eq!(damage(0, 10, 2), 0);
    assert_eq!(damage_bounds(5, 4, 2), (1, 3));
    assert_eq!(scale_damage(0, 50), 0);
    assert_eq!(scale_damage(8, 0), 0);
    assert_eq!(scaled_bounds((4, 8), 50), (2, 4));

    let mut stats = EffectiveCombatStats {
        attack: 0,
        defense: 1,
        hit_points: 1,
        range: 1,
        mobility: 1,
        modifiers: Box::new([]),
    };
    let ruleset = RulesetDefinition::standard();
    assert_eq!(retaliation_percent(&stats, 1, ruleset), None);
    stats.attack = 2;
    assert_eq!(retaliation_percent(&stats, 2, ruleset), None);
    assert_eq!(retaliation_percent(&stats, 1, ruleset), Some(100));
    stats.range = 2;
    assert_eq!(retaliation_percent(&stats, 2, ruleset), Some(50));
}
