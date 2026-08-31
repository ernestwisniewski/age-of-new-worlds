//! Integrated acceptance tests for the current economy turn phase.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as MapResourceType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    City, CityBuildingType, CityConquestAction, CityId, CityProductionQueue, CityProductionTarget,
    CitySpecializationType, CombatState, EconomyState, FieldImprovement, FieldImprovementKind,
    GameMode, GameState, HexCoord, InfrastructureState, InitialResourceDistribution,
    IntendedAttack, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, ResourceType, StateRevision, StrategicResourceStockpile, TechnologyId,
    TransportNetwork, TurnLifecycle, Unit, UnitId, UnitKind, WonderRegistry,
};
use aonw_engine::{
    DomainEvent, EngineContext, ExecutionEvidence, GameEngine, PlayerCommand, StabilityBand,
    TurnCommand,
};

use super::{participant, player};

#[test]
fn economy_growth_uses_pre_growth_output_and_settles_claim_resources_gold_and_upkeep() {
    let EconomyGrowthFixture {
        map,
        rules,
        state,
        p1,
        p2,
        city_id,
        claimed,
    } = economy_growth_fixture();

    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p2)),
    )
    .expect("economy turn");
    assert!(transition.is_accepted());
    let city = transition.state().city(&city_id).expect("updated city");
    assert_eq!(city.population(), 2);
    assert_eq!(city.stored_food(), 0);
    assert!(city.controlled_hexes().contains(&claimed));
    assert_eq!(
        city.production_queue()
            .expect("partial production")
            .invested_production(),
        4,
        "production must use the pre-growth one-worker snapshot"
    );
    assert_eq!(
        transition.state().economy().player_gold().get(&p1),
        Some(&12),
        "10 opening gold + 5 income - (1 + 2) paid-worker upkeep"
    );
    assert_eq!(
        transition
            .state()
            .economy()
            .strategic_resources()
            .get(&p1)
            .and_then(|stockpile| stockpile.amounts().get(&ResourceType::Oil)),
        Some(&1)
    );
    let claim_index = transition
        .events()
        .iter()
        .position(|event| matches!(event, DomainEvent::CityClaimedHex(value) if value.city_id() == &city_id && value.coordinate() == claimed))
        .expect("claim event");
    let first_turn_end = transition
        .events()
        .iter()
        .position(|event| matches!(event, DomainEvent::TurnEnded(_)))
        .expect("turn end");
    assert!(claim_index < first_turn_end);
}

struct EconomyGrowthFixture {
    map: MapDefinition,
    rules: &'static RulesetDefinition,
    state: GameState,
    p1: PlayerId,
    p2: PlayerId,
    city_id: CityId,
    claimed: HexCoord,
}

fn economy_growth_fixture() -> EconomyGrowthFixture {
    let map = economy_map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let city_id = CityId::new("city-1").expect("city id");
    let claimed = HexCoord::new(0, 1);
    let city = City::builder(city_id.clone(), p1.clone(), "Capital", HexCoord::new(0, 0))
        .with_progression(1, 21, 6, 2)
        .with_controlled_hexes([HexCoord::new(1, 0)])
        .with_production(
            Some(
                CityProductionQueue::try_new(
                    CityProductionTarget::Building(CityBuildingType::Granary),
                    0,
                    StrategicResourceStockpile::default(),
                )
                .expect("queue"),
            ),
            0,
        )
        .with_planning(Some(CitySpecializationType::Commerce), Some(claimed))
        .build()
        .expect("city");
    let identity = two_player_identity(GameMode::Multiplayer, &p1, &p2);
    let lifecycle = final_submission_lifecycle(&identity, &p1, &p2);
    let units = (0..6).map(|index| {
        unit(
            &format!("worker-{index}"),
            &p1,
            UnitKind::Worker,
            HexCoord::new(index % 5, index / 5),
        )
    });
    let infrastructure = InfrastructureState::try_new(
        [FieldImprovement::new(
            HexCoord::new(1, 0),
            FieldImprovementKind::OilWell,
            Some(city_id.clone()),
        )],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let research = ResearchState::try_new([(
        p1.clone(),
        PlayerResearchState::try_new([TechnologyId::Combustion], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1.clone(), 10)]),
        BTreeMap::new(),
        BTreeMap::from([(p1.clone(), 0), (p2.clone(), 0)]),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities([city])
    .with_infrastructure(infrastructure)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_economy(economy)
    .try_build()
    .expect("state");
    EconomyGrowthFixture {
        map,
        rules,
        state,
        p1,
        p2,
        city_id,
        claimed,
    }
}

#[test]
fn stability_decay_crosses_band_and_unattacked_city_recovers_one_hit_point() {
    let map = line_map("stability", 3);
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let identity = one_player_identity(&p1);
    let lifecycle = active_lifecycle(&identity, [&p1]);
    let city_id = CityId::new("city-1").expect("city id");
    let city = City::builder(city_id.clone(), p1.clone(), "Capital", HexCoord::new(0, 0))
        .with_controlled_hexes([HexCoord::new(1, 0)])
        .with_hit_points(Some(10))
        .build()
        .expect("city");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::new(),
        BTreeMap::from([(p1.clone(), 8)]),
        BTreeMap::from([(p1.clone(), 4)]),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities([city])
    .with_economy(economy)
    .try_build()
    .expect("state");

    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("economy turn");
    assert_eq!(
        transition.state().economy().player_war_weariness().get(&p1),
        Some(&7)
    );
    assert_eq!(
        transition.state().economy().player_stability_net().get(&p1),
        Some(&0)
    );
    assert_eq!(
        transition
            .state()
            .city(&city_id)
            .expect("city")
            .hit_points(),
        Some(11)
    );
    assert!(transition.events().iter().any(|event| matches!(
        event,
        DomainEvent::StabilityBandChanged(value)
            if value.player_id() == &p1
                && value.previous_band() == StabilityBand::Content
                && value.new_band() == StabilityBand::Stable
                && value.net() == 0
    )));
    assert!(matches!(
        transition.events().last(),
        Some(DomainEvent::TurnEnded(_))
    ));
}

#[test]
fn city_attacked_during_simultaneous_combat_does_not_recover_in_same_turn() {
    let map = line_map("attacked-city", 3);
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = two_player_identity(GameMode::Multiplayer, &p1, &p2);
    let lifecycle = final_submission_lifecycle(&identity, &p1, &p2);
    let attacker_id = UnitId::new("attacker").expect("unit id");
    let city_id = CityId::new("city-2").expect("city id");
    let attacker = unit("attacker", &p1, UnitKind::Warrior, HexCoord::new(0, 0));
    let city = City::builder(city_id.clone(), p2.clone(), "Defender", HexCoord::new(1, 0))
        .with_hit_points(Some(10))
        .build()
        .expect("city");
    let combat = CombatState::try_new([IntendedAttack::new(
        attacker_id,
        HexCoord::new(1, 0),
        StateRevision::new(7),
        p1.clone(),
        CityConquestAction::Capture,
    )])
    .expect("combat");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [attacker],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities([city])
    .with_combat(combat)
    .try_build()
    .expect("state");

    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p2)),
    )
    .expect("combat economy turn");
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("turn evidence")
    };
    let combat_hp = i64::from(evidence.combat_executions()[0].outcome.defender_hit_points);
    assert!(combat_hp > 0, "fixture must leave the city standing");
    assert_eq!(
        transition
            .state()
            .city(&city_id)
            .expect("surviving city")
            .hit_points(),
        Some(combat_hp),
        "same-turn recovery must not undo combat damage"
    );
    assert!(
        transition
            .state()
            .economy()
            .player_war_weariness()
            .get(&p1)
            .is_none(),
        "the first attack in a war is free"
    );
}

fn two_player_identity(mode: GameMode, p1: &PlayerId, p2: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        mode,
    )
    .expect("identity")
}

fn one_player_identity(player: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [Participant::try_new(
            player.clone(),
            "One",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")],
        GameMode::HotSeat,
    )
    .expect("identity")
}

fn final_submission_lifecycle(
    identity: &MatchIdentity,
    submitted: &PlayerId,
    active: &PlayerId,
) -> TurnLifecycle {
    TurnLifecycle::try_new(
        identity,
        BTreeMap::from([
            (submitted.clone(), PlayerTurnState::Finished),
            (active.clone(), PlayerTurnState::Active),
        ]),
        [submitted.clone(), active.clone()],
        [submitted.clone()],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle")
}

fn active_lifecycle<'a>(
    identity: &MatchIdentity,
    players: impl IntoIterator<Item = &'a PlayerId>,
) -> TurnLifecycle {
    let players = players.into_iter().cloned().collect::<Vec<_>>();
    TurnLifecycle::try_new(
        identity,
        players
            .iter()
            .cloned()
            .map(|player| (player, PlayerTurnState::Active))
            .collect(),
        players,
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(100),
    )
    .build()
    .expect("unit")
}

fn economy_map() -> MapDefinition {
    let tiles = (0..2)
        .flat_map(|row| {
            (0..5).map(move |col| {
                let coordinate = HexCoord::new(col, row);
                let terrains = if coordinate == HexCoord::new(0, 1) {
                    vec![TerrainType::Plains, TerrainType::Hills]
                } else {
                    vec![TerrainType::Plains]
                };
                let resources = if coordinate == HexCoord::new(1, 0) {
                    vec![MapResourceType::Oil]
                } else {
                    Vec::new()
                };
                TileDefinition::try_new_for_simulation(coordinate, terrains, resources, 0)
                    .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "economy-turn",
        GridLayout::OddQFlatTop,
        5,
        2,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn line_map(id: &str, width: u16) -> MapDefinition {
    let tiles = (0..width)
        .map(|col| {
            TileDefinition::try_new_for_simulation(
                HexCoord::new(i32::from(col), 0),
                vec![TerrainType::Grassland],
                Vec::new(),
                0,
            )
            .expect("tile")
        })
        .collect();
    MapDefinition::try_new(id, GridLayout::OddQFlatTop, width, 1, tiles, Vec::new()).expect("map")
}
