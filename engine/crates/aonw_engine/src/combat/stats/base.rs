use aonw_content::RulesetDefinition;
use aonw_domain::{TroopKind, Unit, UnitKind};

// Base combat classification includes the commander's army, before situational,
// technology and veterancy modifiers. Combat and turn navigation share this source.
pub(crate) fn for_unit(ruleset: &RulesetDefinition, unit: &Unit) -> Option<(i32, i32, u32)> {
    let base = ruleset.unit(unit.kind())?.combat();
    let (mut attack, mut defense, mut hit_points) =
        (base.attack(), base.defense(), base.hit_points());
    if unit.kind() == UnitKind::Commander {
        for troop in unit.army() {
            let (troop_attack, troop_defense, troop_health): (i32, i32, u32) = match troop.kind() {
                TroopKind::Warrior => (2, 2, 3),
                TroopKind::Archer => (2, 1, 2),
                TroopKind::Settler => (0, 1, 1),
            };
            let count = troop.count();
            let signed_count = i32::try_from(count).ok()?;
            attack = attack.checked_add(troop_attack.checked_mul(signed_count)?)?;
            defense = defense.checked_add(troop_defense.checked_mul(signed_count)?)?;
            hit_points = hit_points.checked_add(troop_health.checked_mul(count)?)?;
        }
    }
    Some((attack, defense, hit_points))
}

#[cfg(test)]
mod tests {
    use super::*;
    use aonw_domain::{ArmyTroop, HexCoord, MovementUnits, PlayerId, UnitId};

    #[test]
    fn army_statistics_reject_overflow_without_panicking() {
        for count in [1_500_000_000, u32::MAX] {
            let unit = Unit::builder(
                UnitId::new("commander").expect("id"),
                PlayerId::new("player").expect("id"),
                UnitKind::Commander,
                "Commander",
                HexCoord::new(0, 0),
                MovementUnits::new(10),
            )
            .with_army([ArmyTroop::new(TroopKind::Warrior, count)])
            .build()
            .expect("unit");
            assert!(for_unit(RulesetDefinition::standard(), &unit).is_none());
        }
    }
}
