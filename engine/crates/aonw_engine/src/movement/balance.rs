use aonw_content::RulesetDefinition;
use aonw_domain::{MovementUnits, UnitKind};

/// Returns the per-turn movement allowance used by the standard ruleset.
#[must_use]
pub fn maximum_movement_units(
    ruleset: &RulesetDefinition,
    kind: UnitKind,
    carries_artifact: bool,
) -> MovementUnits {
    ruleset
        .unit(kind)
        .map_or(MovementUnits::ZERO, |definition| {
            definition.maximum_movement(carries_artifact)
        })
}

#[cfg(test)]
mod tests {
    use aonw_domain::{MovementUnits, UnitKind};

    use super::maximum_movement_units;
    use aonw_content::RulesetDefinition;

    #[test]
    fn standard_allowances_match_the_ruleset_balance() {
        assert_eq!(
            maximum_movement_units(RulesetDefinition::standard(), UnitKind::Commander, false),
            MovementUnits::new(10)
        );
        assert_eq!(
            maximum_movement_units(RulesetDefinition::standard(), UnitKind::Warrior, false),
            MovementUnits::new(6)
        );
        assert_eq!(
            maximum_movement_units(RulesetDefinition::standard(), UnitKind::FieldCannon, false),
            MovementUnits::new(4)
        );
        assert_eq!(
            maximum_movement_units(RulesetDefinition::standard(), UnitKind::ReconPlane, false),
            MovementUnits::new(14)
        );
        assert_eq!(
            maximum_movement_units(RulesetDefinition::standard(), UnitKind::ReconPlane, true),
            MovementUnits::new(4)
        );
    }
}
