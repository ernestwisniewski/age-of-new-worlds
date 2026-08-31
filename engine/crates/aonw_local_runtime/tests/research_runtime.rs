//! Current-only research protocol, runtime, and replay coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::TechnologyIdDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientEventDto,
    ClientFeatureDto, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto, ClientResponseDto, TechnologyAvailabilityDto,
};
use aonw_domain::{
    City, CityId, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState, StateRevision,
    TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

#[test]
fn research_protocol_is_complete_and_replayable() {
    let (map, ruleset, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            ruleset.clone(),
            state,
            actor,
        ))
        .expect("open");

    let capabilities = dispatch(&mut runtime, ClientRequestBodyDto::Capabilities);
    let ClientResponseBodyDto::Capabilities { features } = capabilities else {
        panic!("capabilities response")
    };
    assert!(features.contains(&ClientFeatureDto::Research));

    let queried = dispatch(
        &mut runtime,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ResearchOptions {
                expected_revision: 0,
            },
        },
    );
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::ResearchOptions {
                player_id,
                active_technology_id,
                options,
                ..
            },
    } = queried
    else {
        panic!("research options response")
    };
    assert_eq!(player_id, "player-1");
    assert_eq!(active_technology_id, None);
    assert_eq!(options.len(), 54);
    assert!(options.iter().any(|option| {
        option.technology_id == TechnologyIdDto::Agriculture
            && option.availability == TechnologyAvailabilityDto::Available
    }));

    let selected = dispatch(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SelectTechnology {
                expected_revision: 0,
                technology_id: TechnologyIdDto::Agriculture,
            },
        },
    );
    let ClientResponseBodyDto::Command { result } = selected else {
        panic!("research command response")
    };
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(result.stamp.revision, 1);

    let advanced = dispatch(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::EndTurn {
                expected_revision: 1,
            },
        },
    );
    let ClientResponseBodyDto::Command { result } = advanced else {
        panic!("research turn response")
    };
    assert!(matches!(
        result.events.as_slice(),
        [
            ClientEventDto::ResearchPointsGained { points: 2, .. },
            ClientEventDto::TurnEnded { .. }
        ]
    ));

    let expected = runtime.snapshot().expect("research snapshot");
    let save = runtime.export_save_json().expect("research save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), ruleset.clone(), &save)
        .expect("reopen research save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);

    let replay = runtime.export_replay_json().expect("research replay");
    assert!(replay.contains("researchPointsGained"));
    let verification =
        LocalRuntime::verify_replay_json(map, ruleset, &replay).expect("verify research replay");
    assert_eq!(verification.entry_count, 2);
    assert_eq!(verification.final_stamp.revision, StateRevision::new(2));
}

fn dispatch(runtime: &mut LocalRuntime, request: ClientRequestBodyDto) -> ClientResponseBodyDto {
    let document = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("client request");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &document))
        .expect("client response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client protocol failure: {:?}", response.outcome)
    };
    *response
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player id");
    let participant = Participant::try_new(
        actor.clone(),
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity = MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::HotSeat)
        .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), PlayerTurnState::Active)]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let state = GameState::builder(
        StateRevision::INITIAL,
        1,
        map.bounds(),
        ruleset.occupancy_policy(),
        [],
    )
    .with_cities([City::builder(
        CityId::new("capital").expect("city"),
        actor.clone(),
        "Capital",
        HexCoord::new(1, 1),
    )
    .build()
    .expect("city")])
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("research state");
    (map, ruleset, state, actor)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "research-runtime",
        GridLayout::OddQFlatTop,
        3,
        3,
        (0..3)
            .flat_map(|row| {
                (0..3).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
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
