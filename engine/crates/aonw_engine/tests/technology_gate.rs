//! Oracle-characterized technology catalog and read-only gate evidence for CP7/TG.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};

use aonw_content::{RulesetDefinition, TechnologyUnlock};
use aonw_domain::{
    CityBuildingType, FieldImprovementKind, PlayerResearchState, ResourceType, TechnologyId,
    UnitKind, WonderType,
};
use aonw_engine::{TechnologyAvailability, TechnologyCombatStat, TechnologyUnlockQuery};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct TechnologyManifest {
    catalog_hash: String,
    catalog_technology_count: usize,
    cases: Vec<TechnologyCase>,
    gate_cases: Vec<GateCase>,
    effect_case: EffectCase,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct TechnologyCase {
    id: String,
    technology: String,
    unlocked: Vec<String>,
    active: Option<String>,
    city_count: u32,
    fulfilled_boost: bool,
    expected_availability: String,
    expected_cost: u32,
    expected_unlocks: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct GateCase {
    id: String,
    kind: String,
    value: String,
    unlocked: Vec<String>,
    expected_unlocked: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct EffectCase {
    unlocked: Vec<String>,
    iron_production: i32,
    coal_production: i32,
    global_gold_multiplier_basis_points: u32,
    city_defense_bonus: i32,
    army_production_multiplier_basis_points: u32,
    army_strength_multiplier_basis_points: u32,
    army_attack_bonus: i32,
    army_defense_bonus: i32,
    army_hit_points_bonus: i32,
    max_controlled_hexes_bonus: i32,
    city_science_bonus: i32,
}

#[test]
fn catalog_hash_prerequisites_costs_and_unlock_breakdowns_are_exact() {
    let manifest = manifest();
    let ruleset = RulesetDefinition::standard();
    assert_eq!(
        ruleset.technologies().len(),
        manifest.catalog_technology_count
    );
    assert_eq!(
        ruleset
            .technology_catalog_hash()
            .expect("catalog hash")
            .to_string(),
        manifest.catalog_hash
    );

    for case in manifest.cases {
        let technology = technology(&case.technology);
        let research = research(&case.unlocked, case.active.as_deref());
        let query = TechnologyUnlockQuery::new(ruleset, &research);
        assert_eq!(
            availability_name(query.availability(technology).expect("availability")),
            case.expected_availability,
            "{}",
            case.id
        );
        assert_eq!(
            query
                .effective_cost(technology, case.city_count, case.fulfilled_boost)
                .expect("cost"),
            case.expected_cost,
            "{}",
            case.id
        );
        let actual: Vec<_> = query
            .unlock_breakdown(technology)
            .expect("unlocks")
            .iter()
            .copied()
            .map(unlock_name)
            .collect();
        assert_eq!(actual, case.expected_unlocks, "{}", case.id);
    }
}

#[test]
fn combat_modifiers_preserve_per_technology_labels_and_catalog_order() {
    let research = PlayerResearchState::try_new(
        [
            TechnologyId::Tactics,
            TechnologyId::Strategy,
            TechnologyId::Fortifications,
        ],
        None,
        [],
        0,
    )
    .expect("research");
    let modifiers = TechnologyUnlockQuery::new(RulesetDefinition::standard(), &research)
        .combat_modifiers(4, true, true)
        .expect("combat modifiers");
    let actual = modifiers
        .iter()
        .map(|modifier| (modifier.label.as_ref(), modifier.target, modifier.delta))
        .collect::<Vec<_>>();
    assert_eq!(
        actual,
        [
            (
                "tech.fortifications.cityDefense",
                TechnologyCombatStat::Defense,
                2,
            ),
            (
                "tech.strategy.armyStrength",
                TechnologyCombatStat::Attack,
                1,
            ),
            (
                "tech.strategy.armyDefense",
                TechnologyCombatStat::Defense,
                1,
            ),
            (
                "tech.strategy.armyHitPoints",
                TechnologyCombatStat::HitPoints,
                2,
            ),
            ("tech.tactics.armyAttack", TechnologyCombatStat::Attack, 1,),
            ("tech.tactics.armyDefense", TechnologyCombatStat::Defense, 1,),
        ]
    );
}

#[test]
fn every_production_worker_resource_unit_building_and_wonder_gate_uses_one_query() {
    let ruleset = RulesetDefinition::standard();
    for case in manifest().gate_cases {
        let research = research(&case.unlocked, None);
        let query = TechnologyUnlockQuery::new(ruleset, &research);
        let actual = match case.kind.as_str() {
            "building" => query.is_building_unlocked(building(&case.value)),
            "improvement" => query.is_improvement_unlocked(improvement(&case.value)),
            "unit" => query.is_unit_unlocked(unit(&case.value)),
            "wonder" => query.is_wonder_unlocked(wonder(&case.value)),
            "resource" => query.is_resource_revealed(resource(&case.value)),
            value => panic!("unknown gate kind {value}"),
        };
        assert_eq!(actual, case.expected_unlocked, "{}", case.id);
    }
}

#[test]
fn combat_and_economy_modifiers_are_aggregated_from_the_same_catalog() {
    let case = manifest().effect_case;
    let research = research(&case.unlocked, None);
    let summary = TechnologyUnlockQuery::new(RulesetDefinition::standard(), &research)
        .effect_summary()
        .expect("effect summary");
    assert_eq!(
        summary
            .strategic_resource_production
            .get(&ResourceType::Iron),
        Some(&case.iron_production)
    );
    assert_eq!(
        summary
            .strategic_resource_production
            .get(&ResourceType::Coal),
        Some(&case.coal_production)
    );
    assert_eq!(
        summary.global_gold_multiplier_basis_points,
        case.global_gold_multiplier_basis_points
    );
    assert_eq!(summary.city_defense_bonus, case.city_defense_bonus);
    assert_eq!(
        summary.army_production_multiplier_basis_points,
        case.army_production_multiplier_basis_points
    );
    assert_eq!(
        summary.army_strength_multiplier_basis_points,
        case.army_strength_multiplier_basis_points
    );
    assert_eq!(summary.army_attack_bonus, case.army_attack_bonus);
    assert_eq!(summary.army_defense_bonus, case.army_defense_bonus);
    assert_eq!(summary.army_hit_points_bonus, case.army_hit_points_bonus);
    assert_eq!(
        summary.max_controlled_hexes_bonus,
        case.max_controlled_hexes_bonus
    );
    assert_eq!(summary.city_science_bonus, case.city_science_bonus);
}

#[test]
fn catalog_is_exhaustive_acyclic_and_fail_closed_at_input_boundary() {
    let ruleset = RulesetDefinition::standard();
    let mut remaining: BTreeSet<_> = ruleset
        .technologies()
        .iter()
        .map(|definition| definition.id())
        .collect();
    let mut resolved = BTreeSet::new();
    while !remaining.is_empty() {
        let next = ruleset.technologies().iter().find(|definition| {
            remaining.contains(&definition.id())
                && definition
                    .prerequisites()
                    .iter()
                    .all(|required| resolved.contains(&required.domain()))
        });
        let definition = next.expect("technology prerequisites must be known and acyclic");
        assert!(remaining.remove(&definition.id()));
        assert!(resolved.insert(definition.id()));
    }
    let invalid = std::fs::read(
        repository_root().join("engine/fixtures/technology_gate/invalid/unknown-field.json"),
    )
    .expect("invalid fixture");
    assert!(serde_json::from_slice::<TechnologyManifest>(&invalid).is_err());

    let empty = PlayerResearchState::default();
    assert_eq!(
        TechnologyUnlockQuery::new(ruleset, &empty)
            .effective_cost(TechnologyId::Agriculture, 0, false)
            .expect("zero-city base cost"),
        TechnologyUnlockQuery::new(ruleset, &empty)
            .effective_cost(TechnologyId::Agriculture, 1, false)
            .expect("one-city base cost")
    );
}

fn manifest() -> TechnologyManifest {
    serde_json::from_slice(
        &std::fs::read(repository_root().join("engine/fixtures/technology_gate/manifest.json"))
            .expect("technology manifest"),
    )
    .expect("strict technology manifest")
}

fn research(unlocked: &[String], active: Option<&str>) -> PlayerResearchState {
    PlayerResearchState::try_new(
        unlocked.iter().map(|value| technology(value)),
        active.map(technology),
        [],
        0,
    )
    .expect("research state")
}

fn technology(value: &str) -> TechnologyId {
    match value {
        "agriculture" => TechnologyId::Agriculture,
        "animalHusbandry" => TechnologyId::AnimalHusbandry,
        "craftsmanship" => TechnologyId::Craftsmanship,
        "storage" => TechnologyId::Storage,
        "horsebackRiding" => TechnologyId::HorsebackRiding,
        "militaryOrganization" => TechnologyId::MilitaryOrganization,
        "ironWorking" => TechnologyId::IronWorking,
        "coalMining" => TechnologyId::CoalMining,
        "logistics" => TechnologyId::Logistics,
        "tactics" => TechnologyId::Tactics,
        "economy" => TechnologyId::Economy,
        "urbanization" => TechnologyId::Urbanization,
        "fortifications" => TechnologyId::Fortifications,
        "strategy" => TechnologyId::Strategy,
        "specialization" => TechnologyId::Specialization,
        "writing" => TechnologyId::Writing,
        "scientificMethod" => TechnologyId::ScientificMethod,
        "combustion" => TechnologyId::Combustion,
        "massProduction" => TechnologyId::MassProduction,
        "nuclearPhysics" => TechnologyId::NuclearPhysics,
        _ => panic!("unknown fixture technology {value}"),
    }
}

fn availability_name(value: TechnologyAvailability) -> &'static str {
    match value {
        TechnologyAvailability::Unlocked => "unlocked",
        TechnologyAvailability::Active => "active",
        TechnologyAvailability::Available => "available",
        TechnologyAvailability::LockedByPrerequisites => "lockedByPrerequisites",
        TechnologyAvailability::LockedByTechnology => "lockedByTechnology",
    }
}

fn unlock_name(value: TechnologyUnlock) -> String {
    match value {
        TechnologyUnlock::Building(value) => format!("building:{}", lower_camel(value)),
        TechnologyUnlock::Improvement(value) => format!("improvement:{}", lower_camel(value)),
        TechnologyUnlock::ResourceVisibility(value) => {
            format!("resourceVisibility:{}", lower_camel(value))
        }
        TechnologyUnlock::Unit(value) => format!("unit:{}", lower_camel(value)),
        TechnologyUnlock::Wonder(value) => format!("wonder:{}", lower_camel(value)),
    }
}

fn lower_camel(value: impl core::fmt::Debug) -> String {
    let value = format!("{value:?}");
    let mut characters = value.chars();
    characters.next().map_or(value.clone(), |first| {
        first.to_lowercase().chain(characters).collect()
    })
}

fn building(value: &str) -> CityBuildingType {
    match value {
        "granary" => CityBuildingType::Granary,
        "workshop" => CityBuildingType::Workshop,
        _ => panic!("unknown building {value}"),
    }
}
fn improvement(value: &str) -> FieldImprovementKind {
    match value {
        "oilWell" => FieldImprovementKind::OilWell,
        _ => panic!("unknown improvement {value}"),
    }
}
fn unit(value: &str) -> UnitKind {
    match value {
        "warrior" => UnitKind::Warrior,
        "tank" => UnitKind::Tank,
        _ => panic!("unknown unit {value}"),
    }
}
fn wonder(value: &str) -> WonderType {
    match value {
        "greatLibrary" => WonderType::GreatLibrary,
        _ => panic!("unknown wonder {value}"),
    }
}
fn resource(value: &str) -> ResourceType {
    match value {
        "horses" => ResourceType::Horses,
        "wheat" => ResourceType::Wheat,
        _ => panic!("unknown resource {value}"),
    }
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root")
        .to_path_buf()
}
