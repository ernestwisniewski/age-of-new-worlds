//! Authoritative calendar turns survive local and server query transports.
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contract_mapping::encode_game_state;
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
};
use aonw_contracts::server::{
    PlayerQueryServerRequestDto, SERVER_HOST_API_VERSION, ServerPlayerQueryOutcomeDto,
};
use aonw_domain::{
    GameState, HexCoord, MovementUnits, PlayerId, StateRevision, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};
use aonw_server_runtime::{PreparedServerWorld, query_player_dto};

#[test]
fn local_and_server_keep_exhausting_steps_in_the_same_calendar_turn() {
    for available in [0, 3, 4] {
        let result = query(available, UnitKind::FieldCannon, false);
        let ClientQueryResultDto::RoutePlan {
            step_turns,
            estimated_turns,
            ..
        } = result
        else {
            panic!("route plan")
        };
        let expected = if available == 0 {
            vec![1, 2, 3, 3, 4, 4]
        } else {
            vec![1, 1, 2, 2, 3, 3]
        };
        assert_eq!(step_turns, expected, "available {available}");
        assert_eq!(Some(&estimated_turns), step_turns.last());
    }
}

#[test]
fn local_and_server_classify_only_land_road_edges() {
    for kind in [UnitKind::FieldCannon, UnitKind::ReconPlane] {
        let ClientQueryResultDto::RoutePlan {
            road_step_indices, ..
        } = query(3, kind, true)
        else {
            panic!("route")
        };
        assert_eq!(
            road_step_indices,
            if kind == UnitKind::FieldCannon {
                vec![1, 2, 3, 4, 5]
            } else {
                vec![]
            }
        );
    }
}

fn query(available: u32, kind: UnitKind, roads: bool) -> ClientQueryResultDto {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").unwrap();
    let unit = Unit::builder(
        UnitId::new("unit-1").unwrap(),
        actor.clone(),
        kind,
        "Field cannon",
        HexCoord::new(0, 0),
        MovementUnits::new(available),
    )
    .build()
    .unwrap();
    let state = GameState::builder(
        StateRevision::new(7),
        1,
        map.bounds(),
        ruleset.occupancy_policy(),
        [unit],
    )
    .with_match_lifecycle(support::fixture([]).state.match_lifecycle().clone())
    .with_transport_network(
        aonw_domain::TransportNetwork::try_new((0..6).filter(|_| roads).map(|col| {
            aonw_domain::TransportSegment::road(
                HexCoord::new(col, 0),
                aonw_domain::TransportCondition::Operational,
                actor.clone(),
                None,
            )
        }))
        .unwrap(),
    )
    .try_build()
    .unwrap();
    let canonical = encode_game_state(&state);
    let world = PreparedServerWorld::try_new(map.clone(), ruleset.clone()).unwrap();
    let query = ClientQueryDto::RoutePlan {
        expected_revision: 7,
        unit_id: "unit-1".into(),
        target: CoordinateDto { col: 5, row: 0 },
    };
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, actor))
        .unwrap();
    let local = ClientProtocol::dispatch(
        &mut runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Query {
                query: query.clone(),
            },
        },
    );
    let ClientOutcomeDto::Success { response } = local.outcome else {
        panic!("local query")
    };
    let ClientResponseBodyDto::Query { result } = *response else {
        panic!("route result")
    };
    let server = query_player_dto(
        world.clone(),
        PlayerQueryServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            authenticated_actor_player_id: "player-1".into(),
            query,
            map_hash: world.map_hash().to_string(),
            ruleset_hash: world.ruleset_hash().to_string(),
            state: canonical,
        },
    )
    .unwrap();
    assert_eq!(
        server,
        ServerPlayerQueryOutcomeDto::Success {
            result: Box::new(result.clone())
        }
    );
    result
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "route-timing",
        GridLayout::OddQFlatTop,
        6,
        1,
        (0..6)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    if col == 1 || col == 3 {
                        vec![TerrainType::Plains, TerrainType::Hills]
                    } else {
                        vec![TerrainType::Plains]
                    },
                    Vec::new(),
                    0,
                )
                .unwrap()
            })
            .collect(),
        Vec::new(),
    )
    .unwrap()
}

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;
