//! Hex query cache, actor disclosure, and protocol acceptance.
use aonw_content::{
    GridLayout, MapDefinition, ResourceType, RulesetDefinition, TerrainProfile, TerrainType,
    TileDefinition,
};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto, MapResourceDto,
};
use aonw_domain::{
    GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, StateRevision, TechnologyId, TurnLifecycle, WonderRegistry,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};
use std::collections::BTreeMap;

#[test]
fn hex_query_cache_preserves_coordinates_revision_and_recipient_disclosure() {
    let mut runtime = opened();
    let before = runtime.snapshot().expect("snapshot");
    let replay = runtime.export_replay_json().expect("replay");
    let first = query(&mut runtime, 0, 0);
    let fixture = aonw_contracts::client::ClientResponseDto::from_json(include_str!(
        "../../../fixtures/client_protocol/hex_inspection_response.json"
    ))
    .expect("wire fixture");
    assert_eq!(first, fixture.outcome);
    assert_eq!(
        profile(&first).resources,
        [MapResourceDto::Deer, MapResourceDto::Coal]
    );
    assert_eq!(query(&mut runtime, 0, 0), first);
    let second = query(&mut runtime, 0, 1);
    assert!(profile(&second).resources.is_empty());
    assert_eq!(
        profile(&second).coordinate,
        CoordinateDto { col: 1, row: 0 }
    );
    assert_eq!(runtime.query_cache_stats().hits, 1);
    assert_eq!(runtime.query_cache_stats().misses, 2);
    let stale = query(&mut runtime, 9, 0);
    let ClientOutcomeDto::Failure { error } = stale else {
        panic!("stale must fail")
    };
    assert_eq!(error.code, "stale_revision");
    assert_eq!(runtime.snapshot().expect("snapshot"), before);
    assert_eq!(runtime.export_replay_json().expect("replay"), replay);

    runtime
        .handoff_hot_seat_actor(player("player-2"))
        .expect("handoff");
    let private = query(&mut runtime, 0, 0);
    assert_eq!(profile(&private).resources, [MapResourceDto::Deer]);
    assert_ne!(profile(&private).score, profile(&first).score);
    assert_eq!(runtime.query_cache_stats().hits, 1);
    assert_eq!(runtime.query_cache_stats().misses, 4);
    assert_eq!(query(&mut runtime, 0, 0), private);
    assert_eq!(runtime.query_cache_stats().hits, 2);
}

fn profile(value: &ClientOutcomeDto) -> &aonw_contracts::client::HexInspectionDto {
    let ClientOutcomeDto::Success { response } = value else {
        panic!("successful query")
    };
    let ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::HexInspection { inspection, .. },
    } = response.as_ref()
    else {
        panic!("hex profile")
    };
    inspection
}

fn query(runtime: &mut LocalRuntime, revision: u64, col: i32) -> ClientOutcomeDto {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Query {
            query: ClientQueryDto::HexInspection {
                expected_revision: revision,
                coordinate: CoordinateDto { col, row: 0 },
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
        "hex-inspection-runtime",
        GridLayout::OddQFlatTop,
        2,
        1,
        vec![
            TileDefinition::try_new(
                HexCoord::new(0, 0),
                TerrainProfile::try_new(vec![TerrainType::Forest]).expect("terrain"),
                vec![ResourceType::Deer, ResourceType::Coal],
                0,
            )
            .expect("tile"),
            TileDefinition::try_new_for_simulation(
                HexCoord::new(1, 0),
                vec![TerrainType::Plains],
                vec![],
                0,
            )
            .expect("tile"),
        ],
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
    let research = ResearchState::try_new([(
        first.clone(),
        PlayerResearchState::try_new([TechnologyId::CoalMining], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, turn))
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
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
