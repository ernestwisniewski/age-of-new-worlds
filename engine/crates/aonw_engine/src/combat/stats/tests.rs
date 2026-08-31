use aonw_content::TerrainType;
use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    ArmyTroop, City, CityId, GameMode, GameState, HexCoord, HexGridBounds, KnowledgeState,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId,
    PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, TechnologyId,
    TroopKind, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, WonderRegistry,
};

use super::{
    UnitCombatSituation, apply, counter_modifiers, for_unit, push, technology_target,
    terrain_modifiers, veterancy_modifiers,
};
use crate::{CombatModifier, CombatModifierKind, CombatStatTarget, TechnologyCombatStat};

#[test]
fn terrain_modifiers_cover_the_complete_canonical_palette() {
    let mut modifiers = Vec::new();
    terrain_modifiers(&TerrainType::ALL, &mut modifiers);

    assert_eq!(modifiers.len(), 7);
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "terrain.mountain.defense" && value.delta == 2)
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "terrain.desert.defense" && value.delta == -1)
    );
    assert!(
        modifiers
            .iter()
            .all(|value| value.target == CombatStatTarget::Defense)
    );
}

#[test]
fn unit_counters_cover_attack_defense_rough_open_and_breakthrough_rules() {
    let tank = unit("tank", UnitKind::Tank, 0);
    let settler = unit("settler", UnitKind::Settler, 0);
    let warrior = unit("warrior", UnitKind::Warrior, 0);
    let mut modifiers = Vec::new();

    counter_modifiers(
        &unit("spearman", UnitKind::Spearman, 0),
        None,
        true,
        &[],
        &[],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("spearman", UnitKind::Spearman, 0),
        Some(&tank),
        true,
        &[],
        &[],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("spearman", UnitKind::Spearman, 0),
        Some(&tank),
        false,
        &[],
        &[],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("archer", UnitKind::Archer, 0),
        Some(&warrior),
        false,
        &[TerrainType::Forest],
        &[],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("cavalry", UnitKind::Cavalry, 0),
        Some(&warrior),
        true,
        &[],
        &[TerrainType::Hills],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("cavalry", UnitKind::Cavalry, 0),
        Some(&settler),
        true,
        &[],
        &[TerrainType::Plains],
        &mut modifiers,
    );
    counter_modifiers(
        &unit("heavy", UnitKind::HeavyInfantry, 0),
        Some(&warrior),
        true,
        &[],
        &[],
        &mut modifiers,
    );

    assert_eq!(modifiers.len(), 6);
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.spearmanVsMounted.attack")
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.spearmanVsMounted.defense")
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.archerDefensiveTerrain.defense")
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.cavalryRoughAttack.attack")
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.cavalryOpenRaid.attack")
    );
    assert!(
        modifiers
            .iter()
            .any(|value| value.label.as_ref() == "counter.heavyInfantryBreakthrough.attack")
    );
}

#[test]
fn veterancy_and_stat_application_preserve_order_and_clamp_hit_points() {
    let mut modifiers = Vec::new();
    for (index, experience) in [0, 3, 7, 12].into_iter().enumerate() {
        veterancy_modifiers(
            &unit(&format!("unit-{index}"), UnitKind::Warrior, experience),
            &mut modifiers,
        );
    }
    assert_eq!(modifiers.len(), 6);

    push(
        &mut modifiers,
        CombatModifierKind::Technology,
        "ignored.zero",
        CombatStatTarget::Attack,
        0,
    );
    let stats = apply(
        i32::MAX,
        4,
        1,
        2,
        3,
        vec![
            modifier(CombatStatTarget::Attack, 1),
            modifier(CombatStatTarget::Defense, -2),
            modifier(CombatStatTarget::HitPoints, -9),
        ],
    );
    assert_eq!(stats.attack, i32::MAX);
    assert_eq!(stats.defense, 2);
    assert_eq!(stats.hit_points, 1);
    assert_eq!((stats.range, stats.mobility), (2, 3));

    assert_eq!(
        technology_target(TechnologyCombatStat::Attack),
        CombatStatTarget::Attack
    );
    assert_eq!(
        technology_target(TechnologyCombatStat::Defense),
        CombatStatTarget::Defense
    );
    assert_eq!(
        technology_target(TechnologyCombatStat::HitPoints),
        CombatStatTarget::HitPoints
    );
}

#[test]
fn commander_stats_apply_army_city_technology_and_composition_rules() {
    let owner = PlayerId::new("player").expect("player id");
    let commander = Unit::builder(
        UnitId::new("commander").expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        "Commander",
        HexCoord::new(0, 0),
        MovementUnits::new(100),
    )
    .with_army([
        ArmyTroop::new(TroopKind::Warrior, 2),
        ArmyTroop::new(TroopKind::Archer, 1),
        ArmyTroop::new(TroopKind::Settler, 1),
    ])
    .with_experience_points(12)
    .build()
    .expect("commander");
    let city = City::builder(
        CityId::new("city").expect("city id"),
        owner.clone(),
        "City",
        HexCoord::new(0, 0),
    )
    .build()
    .expect("city");
    let state = state_with_research(owner, commander.clone(), city.clone());
    let opponent = unit("opponent", UnitKind::Tank, 0);

    let computed = for_unit(
        &state,
        RulesetDefinition::standard(),
        &commander,
        UnitCombatSituation {
            opponent: Some(&opponent),
            defended_city: Some(&city),
            attacker: false,
            terrain_tags: &[TerrainType::Mountain],
            opponent_terrain_tags: &[TerrainType::Plains],
        },
    )
    .expect("combat stats");

    assert!(
        computed
            .modifiers
            .iter()
            .any(|value| value.kind == CombatModifierKind::Fortification)
    );
    assert!(
        computed
            .modifiers
            .iter()
            .any(|value| value.kind == CombatModifierKind::Technology)
    );
    assert!(
        computed
            .modifiers
            .iter()
            .any(|value| value.kind == CombatModifierKind::TroopComposition)
    );
    assert!(computed.hit_points > 10);
}

fn modifier(target: CombatStatTarget, delta: i32) -> CombatModifier {
    CombatModifier {
        kind: CombatModifierKind::Technology,
        label: "test".into(),
        target,
        delta,
    }
}

fn unit(id: &str, kind: UnitKind, experience: u32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        PlayerId::new("player").expect("player id"),
        kind,
        id,
        HexCoord::new(0, 0),
        MovementUnits::new(100),
    )
    .with_experience_points(experience)
    .build()
    .expect("unit")
}

fn state_with_research(owner: PlayerId, commander: Unit, city: City) -> GameState {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [Participant::try_new(
            owner.clone(),
            "Player",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(owner.clone(), PlayerTurnState::Active)]),
        [owner.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    let research = PlayerResearchState::try_new(
        [
            TechnologyId::Fortifications,
            TechnologyId::Strategy,
            TechnologyId::Tactics,
        ],
        None,
        [],
        0,
    )
    .expect("research");
    let research = ResearchState::try_new([(owner, research)]).expect("research state");
    GameState::builder(
        StateRevision::new(1),
        1,
        HexGridBounds::new(2, 2).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [commander],
    )
    .with_cities([city])
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}
