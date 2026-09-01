use aonw_domain::{
    GameState, HexCoord, HexGridBounds, InteractionState, MovementUnits, PendingInteraction,
    PlayerId, StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};

use super::digest_state;

mod fixture;
mod state_completeness;
mod unit_completeness;

fn unit(id: &str, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("id"),
        PlayerId::new("player-1").expect("player"),
        UnitKind::Commander,
        "unit.commander",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

#[test]
fn digest_is_independent_of_entity_input_order() {
    let bounds = HexGridBounds::new(3, 3).expect("bounds");
    let left = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [
            unit("b", HexCoord::new(1, 1)),
            unit("a", HexCoord::new(0, 0)),
        ],
    )
    .expect("state");
    let right = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [
            unit("a", HexCoord::new(0, 0)),
            unit("b", HexCoord::new(1, 1)),
        ],
    )
    .expect("state");
    assert_eq!(digest_state(&left), digest_state(&right));
    assert_eq!(
        digest_state(&left).to_string(),
        "2a48cc16b8d708476c56a7b5da5a17881095905402a2d700c607eb1b7a2a7781"
    );
}

#[test]
fn digest_includes_reversible_skip_balance() {
    let bounds = HexGridBounds::new(3, 3).expect("bounds");
    let base = unit("unit", HexCoord::new(1, 1));
    let skipped = Unit::builder(
        base.id().clone(),
        base.owner_player_id().clone(),
        base.kind(),
        base.name(),
        base.position(),
        MovementUnits::ZERO,
    )
    .build()
    .expect("skipped unit");
    let base_state = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [base],
    )
    .expect("base state");
    let skipped_state = GameState::builder(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [skipped],
    )
    .with_interaction(InteractionState::new(
        None,
        Some(PendingInteraction::UnitTurnSkip {
            owner_player_id: PlayerId::new("player-1").expect("player"),
            unit_id: UnitId::new("unit").expect("unit"),
            restore_movement: MovementUnits::new(10),
        }),
    ))
    .try_build()
    .expect("skipped state");

    assert_ne!(digest_state(&base_state), digest_state(&skipped_state));
}

#[test]
fn every_pending_interaction_shape_has_a_distinct_digest() {
    use aonw_domain::FieldImprovementKind;

    let owner = PlayerId::new("player-1").expect("player");
    let unit_id = UnitId::new("unit").expect("unit");
    let city_id = aonw_domain::CityId::new("city").expect("city");
    let pending = [
        PendingInteraction::ResearchSelection {
            owner_player_id: owner.clone(),
        },
        PendingInteraction::CityWorkedHexSelection {
            owner_player_id: owner.clone(),
            city_id: city_id.clone(),
        },
        PendingInteraction::CityExpansionSelection {
            owner_player_id: owner.clone(),
            city_id,
        },
        PendingInteraction::WorkerActionSelection {
            owner_player_id: owner.clone(),
            unit_id: unit_id.clone(),
            improvement: None,
        },
        PendingInteraction::MerchantTradeRouteSelection {
            owner_player_id: owner.clone(),
            unit_id: unit_id.clone(),
        },
        PendingInteraction::MerchantMoveToCitySelection {
            owner_player_id: owner.clone(),
            unit_id: unit_id.clone(),
        },
        PendingInteraction::UnitTurnSkip {
            owner_player_id: owner.clone(),
            unit_id: unit_id.clone(),
            restore_movement: MovementUnits::new(10),
        },
        PendingInteraction::AttackTargeting {
            owner_player_id: owner.clone(),
            unit_id: unit_id.clone(),
            defender: Some(HexCoord::new(1, 1)),
        },
        PendingInteraction::CommanderMergeSelection {
            owner_player_id: owner,
            unit_id,
        },
    ];
    let mut digests = pending
        .into_iter()
        .map(|pending| {
            let mut writer = super::writer::DigestWriter::new();
            super::hash_interaction(&mut writer, &InteractionState::new(None, Some(pending)));
            writer.finish()
        })
        .collect::<Vec<_>>();
    digests.sort_unstable();
    digests.dedup();
    assert_eq!(digests.len(), 9);

    let mut writer = super::writer::DigestWriter::new();
    super::hash_interaction(
        &mut writer,
        &InteractionState::new(
            None,
            Some(PendingInteraction::WorkerActionSelection {
                owner_player_id: PlayerId::new("player-1").expect("player"),
                unit_id: UnitId::new("unit").expect("unit"),
                improvement: Some(FieldImprovementKind::Mine),
            }),
        ),
    );
    assert!(!digests.contains(&writer.finish()));
}

#[test]
fn city_identity_tags_are_stable_and_total() {
    use aonw_domain::CityBuildingType::*;
    use aonw_domain::WonderType::*;
    let buildings = [
        Granary,
        WaterMill,
        Workshop,
        Storehouse,
        Housing,
        MerchantHall,
        Stonemason,
        Barracks,
        Marketplace,
        Port,
        Aqueduct,
        Forge,
        Stable,
        Bank,
        BuildersGuild,
        Factory,
        Lighthouse,
        TrainingGrounds,
        TownHall,
        Monument,
        Archive,
        Academy,
        University,
        Observatory,
        Laboratory,
        Reactor,
        Courthouse,
        Court,
        GovernorsOffice,
        SurveyorsOffice,
        PlanningOffice,
        Apothecary,
        PublicBaths,
        Hospital,
        Ministries,
        Walls,
        Armory,
        SiegeWorkshop,
        Citadel,
        WarCollege,
        ConscriptionOffice,
        BorderFort,
        Airfield,
        ArtisansGuild,
        MasterWorkshop,
        Steelworks,
        RailDepot,
        PowerPlant,
        AssemblyPlant,
        Refinery,
        MapRoom,
        Shipyard,
        DryDock,
        NavalAcademy,
        HarborCustoms,
        Museum,
        Parliament,
        BroadcastTower,
        WorldFairGrounds,
    ];
    for (expected, value) in buildings.into_iter().enumerate() {
        assert_eq!(super::city::building_tag(value), tag_index(expected));
    }
    for (expected, value) in [
        GreatLibrary,
        HangingGardens,
        GreatWall,
        Petra,
        CentralBank,
        ImperialUniversity,
        GrandCathedral,
        MotherFactory,
        NationalObservatory,
        SvalbardSeedVault,
        GrandExposition,
    ]
    .into_iter()
    .enumerate()
    {
        assert_eq!(super::city::wonder_tag(value), tag_index(expected));
    }
}

#[test]
fn technology_identity_tags_are_stable_and_total() {
    use aonw_domain::TechnologyId::*;
    let technologies = [
        Agriculture,
        Woodworking,
        Mining,
        AnimalHusbandry,
        Hunting,
        Fishing,
        Craftsmanship,
        Trade,
        Storage,
        WaterEngineering,
        Stoneworking,
        MilitaryOrganization,
        AdvancedTrade,
        Construction,
        Navigation,
        Irrigation,
        Banking,
        Engineering,
        Metallurgy,
        HorsebackRiding,
        IronWorking,
        CoalMining,
        Machinery,
        Administration,
        Logistics,
        Shipbuilding,
        Tactics,
        Economy,
        Urbanization,
        Fortifications,
        Strategy,
        Specialization,
        Writing,
        Mathematics,
        Medicine,
        CivilService,
        Siegecraft,
        Cartography,
        Guilds,
        Law,
        Education,
        UrbanPlanning,
        NavalDoctrine,
        Steel,
        Bureaucracy,
        Nationalism,
        ScientificMethod,
        SteamPower,
        Electricity,
        Combustion,
        Flight,
        MassProduction,
        Radio,
        NuclearPhysics,
    ];
    for (expected, value) in technologies.into_iter().enumerate() {
        assert_eq!(super::research::technology_tag(value), tag_index(expected));
    }
}

#[test]
fn resource_identity_tags_are_stable_and_total() {
    use aonw_domain::ResourceType::*;
    let resources = [
        Wheat, Fish, Deer, Sheep, Rice, Cow, Apple, Banana, Citrus, Gold, Silver, Gems, Silk,
        Spices, Cotton, Grapes, Ivory, Pearls, Coffee, Cocoa, Tobacco, Sugar, Iron, Coal, Oil,
        Aluminium, Uranium, Horses, Marble,
    ];
    for (expected, value) in resources.into_iter().enumerate() {
        assert_eq!(super::economy::resource_tag(value), tag_index(expected));
    }
}

#[test]
fn unit_and_improvement_identity_tags_are_stable_and_total() {
    use aonw_domain::FieldImprovementKind::*;
    use aonw_domain::UnitKind::*;
    let units = [
        Commander,
        Warrior,
        Archer,
        Settler,
        Worker,
        Merchant,
        Scout,
        Spearman,
        Cavalry,
        Catapult,
        HeavyInfantry,
        FieldCannon,
        Rifleman,
        Tank,
        ScoutShip,
        Warship,
        ReconPlane,
    ];
    for (expected, value) in units.into_iter().enumerate() {
        assert_eq!(super::unit_kind_tag(value), tag_index(expected));
    }
    let improvements = [
        Farm,
        RiverFarm,
        Mine,
        LumberMill,
        Pasture,
        Camp,
        Quarry,
        FishingBoats,
        Orchard,
        Plantation,
        Vineyard,
        TradingPost,
        ProspectorCamp,
        HorseRanch,
        PearlDivers,
        CoalShaft,
        OilWell,
        BauxiteMine,
        UraniumMine,
    ];
    for (expected, value) in improvements.into_iter().enumerate() {
        assert_eq!(super::improvement_tag(value), tag_index(expected));
        assert_eq!(
            super::infrastructure::improvement_tag(value),
            tag_index(expected)
        );
    }
}

fn tag_index(expected: usize) -> u8 {
    u8::try_from(expected).expect("tag index fits u8")
}
