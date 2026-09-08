//! Manual-turn-work wire, cache, and hot-seat isolation contracts.
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
};
use aonw_domain::{
    City, CityId, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};
use serde_json::json;
use std::collections::BTreeMap;

#[test]
fn pending_work_is_read_only_cached_and_scoped_to_the_hot_seat_actor() {
    let mut runtime = opened();
    let snapshot = runtime.snapshot().expect("snapshot");
    let replay = runtime.export_replay_json().expect("replay");
    let first = query(&mut runtime, 0);
    let value = serde_json::to_value(&first).expect("json");
    let fixture = aonw_contracts::client::ClientResponseDto::from_json(include_str!(
        "../../../fixtures/client_protocol/pending_turn_actions_response.json"
    ))
    .expect("wire fixture");
    assert_eq!(first, fixture.outcome);
    assert_eq!(
        value["response"]["result"]["actions"],
        json!([
            {"type":"unit", "unitId":"unit-0", "coordinate":{"col":0,"row":0}},
            {"type":"cityProduction", "cityId":"capital", "coordinate":{"col":0,"row":1}},
            {"type":"research"},
        ])
    );
    assert_eq!(value["response"]["result"]["canActivate"], true);
    assert_eq!(query(&mut runtime, 0), first);
    assert_eq!(runtime.query_cache_stats().hits, 1);
    assert_eq!(runtime.query_cache_stats().misses, 1);
    assert_eq!(runtime.snapshot().expect("snapshot"), snapshot);
    assert_eq!(runtime.export_replay_json().expect("replay"), replay);
    runtime
        .handoff_hot_seat_actor(player("player-2"))
        .expect("handoff");
    let other = query(&mut runtime, 0);
    let value = serde_json::to_value(&other).expect("json");
    assert_eq!(
        value["response"]["result"]["actions"],
        json!([
            {"type":"unit", "unitId":"unit-3", "coordinate":{"col":3,"row":0}},
            {"type":"research"},
        ])
    );
    assert_eq!(runtime.query_cache_stats().misses, 2);
    assert_eq!(query(&mut runtime, 0), other);
    assert_eq!(runtime.query_cache_stats().hits, 2);
}

#[test]
fn accepted_command_refreshes_work_and_stale_revision_cannot_hit_cache() {
    let mut runtime = opened();
    query(&mut runtime, 0);
    let response = ClientProtocol::dispatch(
        &mut runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Dispatch {
                command: ClientCommandDto::SkipUnitTurn {
                    expected_revision: 0,
                    unit_id: "unit-0".to_owned(),
                },
            },
        },
    );
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("command success")
    };
    let ClientResponseBodyDto::Command { result } = *response else {
        panic!("command result")
    };
    assert_eq!(
        result.outcome,
        aonw_contracts::client::ClientCommandOutcomeDto::Accepted
    );
    let ClientOutcomeDto::Failure { error } = query(&mut runtime, 0) else {
        panic!("stale query")
    };
    assert_eq!(error.code, "stale_revision");
    let ClientOutcomeDto::Success { response } = query(&mut runtime, 1) else {
        panic!("fresh query")
    };
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::PendingTurnActions {
                stamp,
                can_activate,
                actions,
            },
    } = *response
    else {
        panic!("turn actions")
    };
    assert_eq!(stamp.revision, 1);
    assert!(can_activate);
    assert_eq!(actions.len(), 2);
    assert!(matches!(
        actions[0],
        aonw_contracts::client::PendingTurnActionDto::CityProduction { .. }
    ));
    assert_eq!(runtime.query_cache_stats().hits, 0);
    assert_eq!(runtime.query_cache_stats().misses, 3);
}

fn query(runtime: &mut LocalRuntime, revision: u64) -> ClientOutcomeDto {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Query {
            query: ClientQueryDto::PendingTurnActions {
                expected_revision: revision,
            },
        },
    }
    .to_json()
    .expect("request");
    aonw_contracts::client::ClientResponseDto::from_json(&ClientProtocol::dispatch_json(
        runtime, &request,
    ))
    .expect("response")
    .outcome
}

fn opened() -> LocalRuntime {
    let first = player("player-1");
    let second = player("player-2");
    let rules = RulesetDefinition::standard().clone();
    let map = MapDefinition::try_new(
        "pending-turn-runtime",
        GridLayout::OddQFlatTop,
        4,
        2,
        (0..2)
            .flat_map(|row| {
                (0..4).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
                        vec![],
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        vec![],
    )
    .expect("map");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [&first, &second].map(|id| {
            Participant::try_new(
                id.clone(),
                id.as_str(),
                0xff00_0000,
                PlayerCountry::Poland,
                PlayerKind::Human,
                None,
            )
            .expect("participant")
        }),
        GameMode::HotSeat,
    )
    .expect("identity");
    let turn = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (first.clone(), PlayerTurnState::Active),
            (second.clone(), PlayerTurnState::Active),
        ]),
        [first.clone(), second.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn");
    let units = [(&first, 0), (&second, 3)].map(|(owner, col)| {
        Unit::builder(
            UnitId::new(format!("unit-{col}")).expect("unit id"),
            owner.clone(),
            UnitKind::Warrior,
            "Warrior",
            HexCoord::new(col, 0),
            MovementUnits::new(4),
        )
        .build()
        .expect("unit")
    });
    let city = City::builder(
        CityId::new("capital").expect("city id"),
        first.clone(),
        "Capital",
        HexCoord::new(0, 1),
    )
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        units,
    )
    .with_cities([city])
    .with_match_lifecycle(MatchLifecycle::new(identity, turn))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, first))
        .expect("open");
    runtime
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}
