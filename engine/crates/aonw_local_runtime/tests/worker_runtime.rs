//! Runtime, save, replay, cache, and recipient tests for current workers.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{FieldImprovementKindDto, ReplayEventDto, ReplayLogDto, SaveGameDto};
use aonw_domain::{
    City, CityId, FogOfWar, GameMode, GameState, HexCoord, InteractionState, KnowledgeState,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry,
    PlayerFog, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState,
    StateRevision, TechnologyId, TurnLifecycle, Unit, UnitId, UnitKind, WonderRegistry,
};
use aonw_engine::{DomainEvent, WorkerJobCompletion};
use aonw_local_runtime::{
    ClientProtocol, LocalRuntime, OpenSession, RuntimeQuery, RuntimeQueryResult,
    TurnCommandRequest, WorkerOptionsRequest, WorkerUnitRequest,
};

#[test]
fn road_job_save_reopen_replay_projection_and_query_cache_are_exact() {
    let (map, rules, state, actor, foreign) = fixture();
    let worker_id = unit_id("worker-1");
    let road_coordinate = HexCoord::new(1, 1);
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open worker session");

    assert_query_cache_job_and_mid_save(&mut runtime, &map, &rules, &worker_id);

    let progressed = runtime
        .end_turn(TurnCommandRequest {
            expected_revision: 10,
        })
        .expect("progress road");
    assert!(progressed.is_accepted());
    assert!(progressed.view_patch.upserted_roads.is_empty());
    let completed = runtime
        .end_turn(TurnCommandRequest {
            expected_revision: 11,
        })
        .expect("complete road");
    assert!(completed.is_accepted());
    assert!(completed.events.iter().any(|event| matches!(
        event,
        DomainEvent::WorkerCompletedJob(value)
            if value.completion() == WorkerJobCompletion::Road
                && value.target() == road_coordinate
    )));
    assert_eq!(completed.view_patch.upserted_roads.len(), 1);
    assert_eq!(
        completed.view_patch.upserted_roads[0].coordinate(),
        road_coordinate
    );
    assert_final_roundtrip_replay_and_disclosure(&runtime, &map, &rules, &foreign, road_coordinate);
}

#[test]
fn strict_json_protocol_exercises_the_complete_worker_surface() {
    let mut query_runtime = opened_runtime();
    let query = dispatch_client(
        &mut query_runtime,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::WorkerOptions {
                expected_revision: 9,
                unit_id: "worker-1".to_owned(),
            },
        },
    );
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::WorkerOptions {
                improvements,
                can_build_road,
                automation,
                ..
            },
    } = query
    else {
        panic!("worker options response")
    };
    assert!(!improvements.is_empty());
    assert!(can_build_road);
    assert!(automation.is_some());

    for command in worker_commands() {
        let response = dispatch_client(
            &mut opened_runtime(),
            ClientRequestBodyDto::Dispatch { command },
        );
        assert!(matches!(response, ClientResponseBodyDto::Command { .. }));
    }
}

fn worker_commands() -> [ClientCommandDto; 7] {
    [
        ClientCommandDto::SelectWorkerImprovement {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
            improvement: FieldImprovementKindDto::Farm,
        },
        ClientCommandDto::ConfirmWorkerImprovement {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
            improvement: Some(FieldImprovementKindDto::Farm),
        },
        ClientCommandDto::CancelWorkerJob {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
        },
        ClientCommandDto::AssignWorkerToHex {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
        },
        ClientCommandDto::CancelWorkerAssignment {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
        },
        ClientCommandDto::BuildRoad {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
        },
        ClientCommandDto::AutomateWorker {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
        },
    ]
}

fn dispatch_client(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let document = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("client request JSON");
    let response = ClientProtocol::dispatch_json(runtime, &document);
    let response = ClientResponseDto::from_json(&response).expect("client response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client protocol response failed: {:?}", response.outcome)
    };
    *response
}

fn opened_runtime() -> LocalRuntime {
    let (map, rules, state, actor, _) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open worker session");
    runtime
}

fn assert_query_cache_job_and_mid_save(
    runtime: &mut LocalRuntime,
    map: &MapDefinition,
    rules: &RulesetDefinition,
    worker_id: &UnitId,
) {
    let query = RuntimeQuery::WorkerOptions(WorkerOptionsRequest {
        expected_revision: 9,
        unit_id: worker_id.clone(),
    });
    let first = runtime.query(&query).expect("worker options");
    let second = runtime.query(&query).expect("cached worker options");
    assert_eq!(first, second);
    assert_eq!(runtime.query_cache_stats().misses, 1);
    assert_eq!(runtime.query_cache_stats().hits, 1);
    let RuntimeQueryResult::WorkerOptions { options, .. } = first else {
        panic!("worker options")
    };
    assert!(options.can_build_road());
    let started = runtime
        .build_road(&WorkerUnitRequest {
            expected_revision: 9,
            unit_id: worker_id.clone(),
        })
        .expect("start road");
    assert!(started.is_accepted());
    let busy_query = RuntimeQuery::WorkerOptions(WorkerOptionsRequest {
        expected_revision: 10,
        unit_id: worker_id.clone(),
    });
    let RuntimeQueryResult::WorkerOptions { options, .. } =
        runtime.query(&busy_query).expect("post-command options")
    else {
        panic!("worker options")
    };
    assert!(!options.can_build_road());
    assert_eq!(runtime.query_cache_stats().misses, 2);
    let mid_snapshot = runtime.snapshot().expect("mid-job snapshot");
    assert!(
        mid_snapshot
            .units()
            .iter()
            .find(|unit| unit.id() == worker_id)
            .expect("owned worker")
            .owned_details()
            .and_then(|details| details.activity().worker_job())
            .is_some()
    );
    let mid_save = runtime.export_save_json().expect("mid-job save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &mid_save)
        .expect("reopen mid-job save");
    assert_eq!(
        reopened.snapshot().expect("reopened snapshot"),
        mid_snapshot
    );
}

fn assert_final_roundtrip_replay_and_disclosure(
    runtime: &LocalRuntime,
    map: &MapDefinition,
    rules: &RulesetDefinition,
    foreign: &PlayerId,
    road_coordinate: HexCoord,
) {
    let final_snapshot = runtime.snapshot().expect("final snapshot");
    assert_eq!(final_snapshot.roads().len(), 1);
    assert_eq!(final_snapshot.roads()[0].coordinate(), road_coordinate);
    let final_save = runtime.export_save_json().expect("final save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &final_save)
        .expect("reopen final save");
    assert_eq!(
        reopened.snapshot().expect("final reopened snapshot"),
        final_snapshot
    );
    let replay_json = runtime.export_replay_json().expect("replay");
    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify replay");
    assert_eq!(verification.entry_count, 3);
    assert_eq!(&verification.final_stamp, final_snapshot.stamp());
    let mut tampered = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    let completion_event = tampered.segments[0].entries[2]
        .result
        .events
        .iter_mut()
        .find(|event| matches!(event, ReplayEventDto::WorkerCompletedJob { .. }))
        .expect("worker completion event");
    let ReplayEventDto::WorkerCompletedJob { target, .. } = completion_event else {
        unreachable!("matched worker event")
    };
    target.col += 1;
    let tampered_json = tampered.to_json().expect("tampered replay");
    assert!(LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &tampered_json).is_err());
    let mut foreign_save = SaveGameDto::from_json(&final_save).expect("save DTO");
    foreign
        .as_str()
        .clone_into(&mut foreign_save.actor_player_id);
    let foreign_save = foreign_save.to_json().expect("foreign save");
    let mut foreign_runtime = LocalRuntime::default();
    foreign_runtime
        .open_save_json(map.clone(), rules.clone(), &foreign_save)
        .expect("open foreign recipient");
    assert!(
        foreign_runtime
            .snapshot()
            .expect("foreign snapshot")
            .roads()
            .is_empty()
    );
}

fn fixture() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = player("player-1");
    let foreign = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&foreign)],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (foreign.clone(), PlayerTurnState::Finished),
        ]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [foreign.clone()],
        None,
    )
    .expect("lifecycle");
    let research = ResearchState::try_new([
        (
            actor.clone(),
            PlayerResearchState::try_new([TechnologyId::Agriculture], None, [], 0)
                .expect("actor research"),
        ),
        (foreign.clone(), PlayerResearchState::default()),
    ])
    .expect("research");
    let worker = Unit::builder(
        unit_id("worker-1"),
        actor.clone(),
        UnitKind::Worker,
        "worker",
        HexCoord::new(1, 1),
        MovementUnits::new(10),
    )
    .with_worker_build_charges(1)
    .build()
    .expect("worker");
    let observer = Unit::builder(
        unit_id("observer-1"),
        foreign.clone(),
        UnitKind::Scout,
        "observer",
        HexCoord::new(5, 3),
        MovementUnits::new(10),
    )
    .build()
    .expect("observer");
    let city = City::builder(
        CityId::new("city-1").expect("city id"),
        actor.clone(),
        "city",
        HexCoord::new(0, 1),
    )
    .with_progression(2, 0, 6, 3)
    .with_controlled_hexes([HexCoord::new(1, 1)])
    .build()
    .expect("city");
    let visible = (0..4)
        .flat_map(|row| (0..6).map(move |col| HexCoord::new(col, row)))
        .collect::<Vec<_>>();
    let fog = FogOfWar::try_new([
        PlayerFog::new(actor.clone(), [], visible),
        PlayerFog::new(foreign.clone(), [], [HexCoord::new(5, 3)]),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [worker, observer],
    )
    .with_cities([city])
    .with_interaction(InteractionState::default())
    .with_fog_of_war(fog)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor, foreign)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "worker-runtime",
        GridLayout::OddQFlatTop,
        6,
        4,
        (0..4)
            .flat_map(|row| {
                (0..6).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}
