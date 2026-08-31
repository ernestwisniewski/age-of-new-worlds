use aonw_domain::{
    DiplomaticScoreChangeReason, DiplomaticScoreEntry, PlayerId, PlayerPair, UnitKind,
};

use super::{canonical_hp, experience_gain, observer_id};

#[test]
fn experience_and_health_helpers_cover_boundary_values() {
    let ruleset = aonw_content::RulesetDefinition::standard();
    assert_eq!(experience_gain(ruleset, UnitKind::Worker, true, true), 0);
    assert_eq!(experience_gain(ruleset, UnitKind::Warrior, true, true), 3);
    assert_eq!(canonical_hp(10, 10), None);
    assert_eq!(canonical_hp(-5, 10), Some(1));
}

#[test]
fn observer_identity_is_independent_of_normalized_pair_order() {
    let attacker = player("middle");
    let lower = player("alpha");
    let upper = player("zulu");
    let lower_entry = entry(PlayerPair::new(lower.clone(), attacker.clone()).expect("pair"));
    let upper_entry = entry(PlayerPair::new(attacker.clone(), upper.clone()).expect("pair"));

    assert_eq!(observer_id(&lower_entry, &attacker), &lower);
    assert_eq!(observer_id(&upper_entry, &attacker), &upper);
}

fn entry(pair: PlayerPair) -> DiplomaticScoreEntry {
    DiplomaticScoreEntry::try_new(
        pair,
        1,
        -1,
        -1,
        DiplomaticScoreChangeReason::WarmongerPenalty,
        Some("source".to_owned()),
    )
    .expect("score entry")
}

fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player")
}
