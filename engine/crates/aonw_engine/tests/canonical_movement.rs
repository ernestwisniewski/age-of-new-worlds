//! Canonical movement integration tests.

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    ArmyTroop, City, CityId, FogOfWar, GameState, HexCoord, MovementUnits, PlayerFog, PlayerId,
    StateRevision, TransportCondition, TransportNetwork, TransportSegment, TroopKind, Unit, UnitId,
    UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{
    CompiledMovementMap, EngineContext, ExecutionEvidence, GameEngine, GameQuery, MoveUnitCommand,
    PlayerCommand, QueryResult, TerrainMovementQuery,
};

fn map() -> MapDefinition {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "canonical-movement",
        GridLayout::OddQFlatTop,
        5,
        5,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn unit(id: &str, owner: &str, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        PlayerId::new(owner).expect("owner id"),
        UnitKind::Commander,
        "unit.commander",
        position,
        MovementUnits::new(10),
    )
    .with_army([ArmyTroop::new(TroopKind::Archer, 2)])
    .with_hit_points(Some(7))
    .with_experience_points(12)
    .build()
    .expect("unit")
}

fn world(
    units: Vec<Unit>,
    cities: Vec<City>,
    fog: FogOfWar,
    transport: TransportNetwork,
) -> GameState {
    GameState::builder(
        StateRevision::new(4),
        2,
        map().bounds(),
        UnitOccupancyPolicy::FriendlyStacking,
        units,
    )
    .with_cities(cities)
    .with_fog_of_war(fog)
    .with_transport_network(transport)
    .try_build()
    .expect("state")
}

#[test]
fn canonical_move_preserves_unit_fields_and_updates_fog_and_contact() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let state = world(
        vec![
            unit("unit-1", "player-1", HexCoord::new(1, 1)),
            unit("unit-2", "player-2", HexCoord::new(3, 1)),
        ],
        Vec::new(),
        FogOfWar::try_new([PlayerFog::new(actor.clone(), [], [HexCoord::new(1, 1)])]).expect("fog"),
        TransportNetwork::default(),
    );
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::MoveUnit(MoveUnitCommand::new(4, &unit_id, HexCoord::new(2, 1))),
    )
    .expect("transition");

    assert!(transition.is_accepted());
    assert_eq!(transition.revision(), StateRevision::new(5));
    assert_eq!(transition.events().len(), 1);
    assert!(matches!(
        transition.evidence(),
        Some(ExecutionEvidence::UnitMovement(_))
    ));
    let moved = transition.state().unit(&unit_id).expect("moved unit");
    assert_eq!(moved.position(), HexCoord::new(2, 1));
    assert_eq!(moved.hit_points(), Some(7));
    assert_eq!(moved.experience_points(), 12);
    assert_eq!(moved.army(), [ArmyTroop::new(TroopKind::Archer, 2)]);
    assert!(
        transition
            .state()
            .fog_of_war()
            .player(&actor)
            .expect("fog")
            .visible_hexes()
            .contains(&HexCoord::new(3, 1))
    );
    assert!(
        transition
            .state()
            .diplomacy()
            .has_contact(&actor, &PlayerId::new("player-2").expect("player"))
    );
}

#[test]
fn canonical_rejection_preserves_revision_and_digest() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let state = world(
        vec![unit("unit-1", "player-1", HexCoord::new(1, 1))],
        Vec::new(),
        FogOfWar::default(),
        TransportNetwork::default(),
    );
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let transition = GameEngine::apply_player_owned(
        state.clone(),
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::MoveUnit(MoveUnitCommand::new(3, &unit_id, HexCoord::new(2, 1))),
    )
    .expect("rejection transition");

    assert!(!transition.is_accepted());
    assert_eq!(
        transition.rejection().expect("rejection").code().as_str(),
        "stale_revision"
    );
    assert_eq!(transition.state(), &state);
    assert_eq!(transition.digest(), GameEngine::state_digest(&state));
}

#[test]
fn prepared_apply_matches_raw_apply_and_exposes_owned_parts() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let state = world(
        vec![unit("unit-1", "player-1", HexCoord::new(0, 0))],
        Vec::new(),
        FogOfWar::default(),
        TransportNetwork::default(),
    );
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let command =
        || PlayerCommand::MoveUnit(MoveUnitCommand::new(4, &unit_id, HexCoord::new(1, 0)));
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let raw = GameEngine::apply_player_owned(state.clone(), context, command()).expect("raw apply");
    let compiled =
        CompiledMovementMap::compile_owned(map.clone(), RulesetDefinition::standard().clone())
            .expect("compiled map");
    let owned = GameEngine::apply_player_owned(
        state,
        context.with_compiled_movement_map(&compiled),
        command(),
    )
    .expect("owned apply")
    .into_parts();

    assert_eq!(owned.state, *raw.state());
    assert_eq!(owned.digest, Some(raw.digest()));
    assert_eq!(&*owned.events, raw.events());
    assert_eq!(owned.evidence.as_ref(), raw.evidence());
    assert_eq!(owned.map_hash, compiled.map_hash());
    assert_eq!(owned.ruleset_hash, compiled.ruleset_hash());
}

#[test]
fn canonical_query_uses_known_operational_roads() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let roads = TransportNetwork::try_new([
        TransportSegment::road(
            HexCoord::new(1, 1),
            TransportCondition::Operational,
            actor.clone(),
            None,
        ),
        TransportSegment::road(
            HexCoord::new(2, 1),
            TransportCondition::Operational,
            actor.clone(),
            None,
        ),
    ])
    .expect("roads");
    let state = world(
        vec![unit("unit-1", "player-1", HexCoord::new(1, 1))],
        Vec::new(),
        FogOfWar::default(),
        roads,
    );
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let result = GameEngine::query(
        &state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        GameQuery::PlanRoute(TerrainMovementQuery::new(4, &unit_id, HexCoord::new(2, 1))),
    )
    .expect("query");
    let QueryResult::Route(route) = result else {
        panic!("route result")
    };
    assert_eq!(route.total_cost(), MovementUnits::new(1));
}

#[test]
fn hidden_foreign_city_is_an_accepted_no_op_but_discovered_city_is_rejected() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let city = City::new(
        CityId::new("city-2").expect("city id"),
        PlayerId::new("player-2").expect("owner"),
        HexCoord::new(2, 1),
        [],
    );
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let hidden = world(
        vec![unit("unit-1", "player-1", HexCoord::new(1, 1))],
        vec![city.clone()],
        FogOfWar::try_new([PlayerFog::new(actor.clone(), [], [HexCoord::new(1, 1)])]).expect("fog"),
        TransportNetwork::default(),
    );
    let hidden_result = GameEngine::apply_player_owned(
        hidden,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::MoveUnit(MoveUnitCommand::new(4, &unit_id, HexCoord::new(2, 1))),
    )
    .expect("transition");
    assert!(hidden_result.is_accepted());
    assert!(hidden_result.events().is_empty());
    assert_eq!(
        hidden_result
            .state()
            .unit(&unit_id)
            .expect("unit")
            .position(),
        HexCoord::new(1, 1)
    );

    let discovered = world(
        vec![unit("unit-1", "player-1", HexCoord::new(1, 1))],
        vec![city],
        FogOfWar::try_new([PlayerFog::new(
            actor.clone(),
            [HexCoord::new(2, 1)],
            [HexCoord::new(1, 1)],
        )])
        .expect("fog"),
        TransportNetwork::default(),
    );
    let discovered_result = GameEngine::apply_player_owned(
        discovered,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::MoveUnit(MoveUnitCommand::new(4, &unit_id, HexCoord::new(2, 1))),
    )
    .expect("transition");
    assert_eq!(
        discovered_result
            .rejection()
            .expect("rejection")
            .code()
            .as_str(),
        "move_target_is_foreign_city_center"
    );
}
