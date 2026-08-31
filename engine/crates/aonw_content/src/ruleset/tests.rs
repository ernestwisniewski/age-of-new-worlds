use std::collections::BTreeSet;

use aonw_domain::{
    CityBuildingType, CitySpecializationType, MovementUnits, PaceProfile, TechnologyId, UnitKind,
    UnitMovementDomain, WonderType,
};

use crate::{
    EconomyYield, ProductionRequirement, ResourceType, StrategicResourceCost, TechnologyCostBalance,
};

use super::{RulesetDefinition, STANDARD_UNITS};

#[test]
fn standard_ruleset_owns_movement_balance_and_capabilities() {
    let ruleset = RulesetDefinition::standard();
    let merchant = ruleset
        .unit(UnitKind::Merchant)
        .expect("merchant definition");
    let plane = ruleset
        .unit(UnitKind::ReconPlane)
        .expect("plane definition");
    assert!(merchant.capabilities().uses_trade_routes());
    assert_eq!(
        plane.capabilities().movement_domain.domain(),
        UnitMovementDomain::Air
    );
    assert_eq!(plane.maximum_movement(false), MovementUnits::new(14));
    assert_eq!(plane.maximum_movement(true), MovementUnits::new(4));
}

#[test]
fn standard_ruleset_owns_exact_outcome_balance() {
    let ruleset = RulesetDefinition::standard();
    let balance = ruleset.outcome();
    assert_eq!(balance.city_score(), 40);
    assert_eq!(balance.population_score(), 12);
    assert_eq!(balance.territory_hex_score(), 3);
    assert_eq!(balance.building_score(), 8);
    assert_eq!(balance.technology_score(), 18);
    assert_eq!(balance.improvement_score(), 5);
    assert_eq!(balance.experience_point_divisor(), 5);
    assert_eq!(balance.gold_divisor(), 50);
    assert_eq!(balance.maximum_gold_score(), 200);

    let score_values = [
        (UnitKind::Commander, 30),
        (UnitKind::Warrior, 15),
        (UnitKind::Archer, 17),
        (UnitKind::Settler, 18),
        (UnitKind::Worker, 12),
        (UnitKind::Merchant, 14),
        (UnitKind::Scout, 10),
        (UnitKind::Spearman, 18),
        (UnitKind::Cavalry, 24),
        (UnitKind::Catapult, 25),
        (UnitKind::HeavyInfantry, 30),
        (UnitKind::FieldCannon, 35),
        (UnitKind::Rifleman, 38),
        (UnitKind::Tank, 50),
        (UnitKind::ScoutShip, 20),
        (UnitKind::Warship, 40),
        (UnitKind::ReconPlane, 36),
    ];
    for (kind, score) in score_values {
        assert_eq!(
            ruleset.unit(kind).expect("unit definition").score_value(),
            score
        );
    }
}

#[test]
fn standard_ruleset_hash_is_stable() {
    let first = RulesetDefinition::standard().content_hash().expect("hash");
    let second = RulesetDefinition::standard().content_hash().expect("hash");
    assert_eq!(first, second);
    assert_eq!(
        first.to_string(),
        "c8bec5b750ded25f60e989dd0e87c6a1a1a7ab87914d574aea830856441ad7ed"
    );
}

#[test]
fn standard_production_catalog_is_complete_and_total() {
    let production = RulesetDefinition::standard().production();
    assert_eq!(production.buildings().len(), 59);
    assert_eq!(production.units().len(), 17);
    assert_eq!(production.wonders().len(), 11);

    let mut identities = BTreeSet::new();
    for definition in production.buildings() {
        assert!(identities.insert(format!("building:{:?}", definition.building())));
        assert_eq!(
            production.building(definition.building()),
            Some(*definition)
        );
        assert!(definition.base_cost() > 0);
    }
    for definition in production.units() {
        assert!(identities.insert(format!("unit:{:?}", definition.unit())));
        assert_eq!(production.unit(definition.unit()), Some(*definition));
        assert!(definition.base_cost() > 0);
        assert!(definition.supply_cost() >= 0);
    }
    for definition in production.wonders() {
        assert!(identities.insert(format!("wonder:{:?}", definition.wonder())));
        assert_eq!(production.wonder(definition.wonder()), Some(*definition));
        assert!(definition.base_cost() > 0);
    }
    assert_eq!(identities.len(), 87);
}

#[test]
fn standard_production_balance_preserves_exact_fixed_point_rules() {
    let production = RulesetDefinition::standard().production();
    assert_eq!(
        [
            PaceProfile::Unlimited,
            PaceProfile::Standard60,
            PaceProfile::Normal90,
            PaceProfile::Long120,
        ]
        .map(|pace| production.building_cost(100, pace)),
        [Some(145), Some(85), Some(92), Some(100)]
    );
    assert_eq!(
        [
            PaceProfile::Unlimited,
            PaceProfile::Standard60,
            PaceProfile::Normal90,
            PaceProfile::Long120,
        ]
        .map(|pace| production.unit_cost(100, pace)),
        [Some(130), Some(80), Some(90), Some(100)]
    );
    assert_eq!(
        production.building_cost(6, PaceProfile::Standard60),
        Some(6)
    );
    assert_eq!(production.rush_gold_per_production(), 2);
    assert_eq!(production.project_divisor(false), 2);
    assert_eq!(production.project_divisor(true), 12);
    assert_eq!(production.supply_density(), (22, 100));
    assert_eq!(production.map_supply_bounds(), (12, 28));
    assert_eq!(production.building_cost(0, PaceProfile::Long120), Some(0));
    assert_eq!(
        [
            CitySpecializationType::Growth,
            CitySpecializationType::Industry,
            CitySpecializationType::Commerce,
            CitySpecializationType::Science,
            CitySpecializationType::Military,
        ]
        .map(|value| production.specialization_building(value)),
        [
            CityBuildingType::Granary,
            CityBuildingType::Workshop,
            CityBuildingType::MerchantHall,
            CityBuildingType::Archive,
            CityBuildingType::Barracks,
        ]
    );
}

#[test]
fn standard_research_pace_scaling_is_exact_and_uses_ceiling_arithmetic() {
    let balance = TechnologyCostBalance::STANDARD;
    let science = RulesetDefinition::standard().science_balance();
    assert_eq!(science.base_science_per_city(), 2);
    assert_eq!(science.max_science_per_city(), 0);
    assert_eq!(
        science.second_science_building_multiplier_basis_points(),
        7_000
    );
    assert_eq!(
        science.later_science_building_multiplier_basis_points(),
        3_500
    );
    let paces = [
        PaceProfile::Unlimited,
        PaceProfile::Standard60,
        PaceProfile::Normal90,
        PaceProfile::Long120,
    ];
    assert_eq!(
        paces.map(|pace| balance.paced_cost(100, pace)),
        [Some(100), Some(80), Some(95), Some(110)]
    );
    assert_eq!(
        paces.map(|pace| balance.paced_cost(1, pace)),
        [Some(1), Some(1), Some(1), Some(2)]
    );
    assert_eq!(balance.paced_cost(0, PaceProfile::Long120), Some(0));
}

#[test]
fn standard_diplomacy_balance_matches_the_ruleset_values() {
    let balance = RulesetDefinition::standard().diplomacy();
    assert_eq!(balance.proposal_duration_turns(), 5);
    assert_eq!(balance.message_duration_turns(), 5);
    assert_eq!(balance.message_cooldown_turns(), 5);
    assert_eq!(balance.promise_duration_turns(), 3);
    assert_eq!(balance.truce_duration_turns(), 10);
    assert_eq!(balance.friendship_accept_score_delta(), 18);
    assert_eq!(balance.truce_accept_score_delta(), 10);
    assert_eq!(balance.proposal_reject_score_delta(), -6);
    assert_eq!(balance.war_declaration_score_delta(), -25);
    assert_eq!(balance.war_declaration_observer_score_delta(), -8);
    assert_eq!(balance.gold_gift_minimum_amount(), 5);
    assert_eq!(balance.gold_gift_cooldown_turns(), 5);
    assert_eq!(balance.gold_gift_score_delta(4), 0);
    assert_eq!(balance.gold_gift_score_delta(10), 2);
    assert_eq!(balance.gold_gift_score_delta(100), 12);
    assert_eq!(balance.promise_broken_score_delta(), -15);
    assert_eq!(balance.friendly_resource_trade_gold_bonus(), 1);
    assert_eq!(
        balance.message_response_score_delta(aonw_domain::DiplomaticMessageResponse::Conciliatory),
        12
    );
    assert_eq!(
        balance.message_response_score_delta(aonw_domain::DiplomaticMessageResponse::Aggressive),
        -18
    );
    assert_eq!(
        balance
            .common_enemy_cooperation_bonus(aonw_domain::DiplomaticMessageResponse::Conciliatory),
        8
    );
}

#[test]
fn standard_production_catalog_owns_requirements_reservations_and_effects() {
    let production = RulesetDefinition::standard().production();
    let water_mill = production
        .building(CityBuildingType::WaterMill)
        .expect("water mill");
    assert_eq!(
        water_mill.river_yield_per_hex(),
        EconomyYield::new(1, 0, 0, 0)
    );
    assert_eq!(water_mill.max_river_applications(), 3);
    assert!(water_mill.requirements().is_empty());
    assert_eq!(water_mill.yield_delta(), EconomyYield::new(0, 0, 0, 0));
    assert_eq!(water_mill.science_per_turn(), 0);
    assert_eq!(water_mill.max_controlled_hexes_delta(), 0);
    assert_eq!(
        production
            .building(CityBuildingType::Storehouse)
            .expect("storehouse")
            .food_deposit_basis_points(),
        12_000
    );

    let cavalry = production.unit(UnitKind::Cavalry).expect("cavalry");
    assert_eq!(cavalry.presence_resources(), &[ResourceType::Horses]);
    let tank = production.unit(UnitKind::Tank).expect("tank");
    assert_eq!(
        tank.strategic_cost_options(),
        &[StrategicResourceCost::new(2, 0)]
    );
    let plane = production.unit(UnitKind::ReconPlane).expect("recon plane");
    assert_eq!(
        plane.strategic_cost_options(),
        &[
            StrategicResourceCost::new(0, 1),
            StrategicResourceCost::new(1, 0),
        ]
    );
    assert_eq!(plane.strategic_cost_options()[0].oil(), 0);
    assert_eq!(plane.strategic_cost_options()[0].aluminium(), 1);
    assert!(!plane.strategic_cost_options()[0].is_empty());
    assert!(StrategicResourceCost::default().is_empty());

    let mother_factory = production
        .wonder(WonderType::MotherFactory)
        .expect("mother factory");
    assert_eq!(
        mother_factory.requirements(),
        &[ProductionRequirement::ResourceAny(&[
            ResourceType::Coal,
            ResourceType::Iron,
        ])]
    );
    assert_eq!(mother_factory.empire_production_basis_points(), 1_000);
    assert_eq!(mother_factory.production_burst(), 80);
    assert_eq!(mother_factory.host_yield(), EconomyYield::new(0, 0, 0, 0));
    assert_eq!(
        mother_factory.empire_yield_per_city(),
        EconomyYield::new(0, 0, 0, 0)
    );
    assert_eq!(mother_factory.empire_science_per_city(), 0);
    assert_eq!(mother_factory.empire_gold_basis_points(), 0);
    assert_eq!(mother_factory.stability_delta(), 0);
    assert!(!mother_factory.grants_free_active_technology());
    assert_eq!(mother_factory.grant_gold(), 0);
    let library = production
        .wonder(WonderType::GreatLibrary)
        .expect("great library");
    assert_eq!(library.empire_science_per_city(), 1);
    assert!(library.grants_free_active_technology());
}

#[test]
fn standard_technology_catalog_is_complete_and_stable() {
    let ruleset = RulesetDefinition::standard();
    assert_eq!(ruleset.technologies().len(), 54);
    for key in crate::TechnologyKey::ALL {
        assert!(!key.as_str().is_empty());
        assert!(
            ruleset
                .technology(key.domain())
                .is_some_and(|value| value.id() == key.domain())
        );
    }
    let mut unique_unlocks = BTreeSet::new();
    let mut counts = [0_u32; 5];
    for unlock in ruleset
        .technologies()
        .iter()
        .flat_map(|definition| definition.unlocks())
    {
        let (category, value, index) = match unlock {
            crate::TechnologyUnlock::Building(value) => {
                let _ = value.domain();
                ("building", format!("{value:?}"), 0)
            }
            crate::TechnologyUnlock::Improvement(value) => {
                let _ = value.domain();
                ("improvement", format!("{value:?}"), 1)
            }
            crate::TechnologyUnlock::ResourceVisibility(value) => {
                let _ = value.domain();
                ("resource", format!("{value:?}"), 2)
            }
            crate::TechnologyUnlock::Unit(value) => {
                let _ = value.domain();
                ("unit", format!("{value:?}"), 3)
            }
            crate::TechnologyUnlock::Wonder(value) => {
                let _ = value.domain();
                ("wonder", format!("{value:?}"), 4)
            }
        };
        assert!(unique_unlocks.insert((category, value)));
        counts[index] += 1;
    }
    assert_eq!(counts, [58, 19, 5, 13, 11]);
    assert_eq!(
        ruleset
            .technology_cost_balance()
            .default_boost_discount_basis_points(),
        2_500
    );
    for boost in ruleset
        .technologies()
        .iter()
        .flat_map(|definition| definition.boosts())
    {
        let _ = boost.condition();
        assert!(boost.discount_basis_points() > 0);
    }
    assert_eq!(
        ruleset
            .technology_catalog_hash()
            .expect("catalog hash")
            .to_string(),
        "a58f5b7def080e42b3d44c2ebb44955e56ea6d4f61b5d25facd3146ee5bed7b3"
    );
    assert_eq!(
        ruleset
            .technology(TechnologyId::NuclearPhysics)
            .expect("nuclear physics")
            .base_cost(),
        48
    );
}

#[test]
fn standard_combat_content_exposes_every_rule_value() {
    let ruleset = RulesetDefinition::standard();
    for definition in STANDARD_UNITS {
        assert_eq!(ruleset.unit(definition.kind()), Some(definition));
        let capabilities = definition.capabilities();
        let _ = (
            capabilities.producible_by_cities(),
            capabilities.gains_experience(),
            capabilities.military(),
            capabilities.recon(),
            capabilities.uses_trade_routes(),
        );
        let combat = definition.combat();
        let _ = (
            combat.attack(),
            combat.defense(),
            combat.hit_points(),
            combat.range(),
            combat.mobility(),
        );
    }
    let combat = ruleset.combat();
    assert_eq!(combat.variance(), 2);
    assert_eq!(combat.ranged_retaliation_percent(), 50);
    assert_eq!(combat.retreat_threshold_percent(), 25);
    assert_eq!(combat.defended_city_unit_defense_bonus(), 1);
    assert_eq!(combat.mixed_commander_army_attack_bonus(), 1);
    assert!(combat.city().hit_points() > 0);
    for definition in ruleset.technologies() {
        assert!(!definition.label().is_empty());
        let _ = (
            definition.era(),
            definition.prerequisites(),
            definition.blocked_by(),
            definition.effects(),
        );
    }
}

#[test]
fn technology_value_constructors_preserve_runtime_inputs() {
    use crate::{
        TechnologyBoost, TechnologyBoostCondition, TechnologyDefinition, TechnologyEra,
        TechnologyImprovement, TechnologyKey,
    };

    let boost = TechnologyBoost::new(
        TechnologyBoostCondition::ImprovementCount {
            improvement: TechnologyImprovement::Farm,
            count: std::hint::black_box(2),
        },
        std::hint::black_box(1_750),
    );
    assert_eq!(boost.discount_basis_points(), 1_750);
    let definition = TechnologyDefinition::new(
        TechnologyKey::Agriculture,
        TechnologyEra::Foundation,
        std::hint::black_box(7),
        &[],
        &[],
        &[],
        &[],
    );
    assert_eq!(definition.base_cost(), 7);
    assert!(definition.blocked_by().is_empty());
}
