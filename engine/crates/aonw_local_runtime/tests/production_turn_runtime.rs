//! Current-only production-turn protocol, save, and replay coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::CityBuildingTypeDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientEventDto,
    ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
    ClientResponseDto,
};
use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget, GameMode, GameState,
    HexCoord, MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, StrategicResourceStockpile, TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

#[test]
fn production_turn_completion_save_reopen_and_replay_are_exact() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open turn production runtime");
    let response = dispatch_client(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::EndTurn {
                expected_revision: 9,
            },
        },
    );
    let ClientResponseBodyDto::Command { result } = response else {
        panic!("turn production response")
    };
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        result.events.as_slice(),
        [
            ClientEventDto::CityBuiltBuilding {
                building_type: CityBuildingTypeDto::Housing,
                ..
            },
            ClientEventDto::ResearchPointsGained { points: 2, .. },
            ClientEventDto::TurnEnded { .. }
        ]
    ));

    let replay = runtime
        .export_replay_json()
        .expect("turn production replay");
    assert_eq!(
        LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay)
            .expect("turn production replay verification")
            .entry_count,
        1
    );
    let save = runtime.export_save_json().expect("turn production save");
    let expected = runtime.snapshot().expect("turn production snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen turn production save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);
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
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &document))
        .expect("client response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client protocol failure: {:?}", response.outcome)
    };
    *response
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player");
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
    let definition = rules
        .production()
        .building(CityBuildingType::Housing)
        .expect("housing definition");
    let cost = rules
        .production()
        .building_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        .expect("housing cost");
    let queue = CityProductionQueue::try_new(
        CityProductionTarget::Building(CityBuildingType::Housing),
        cost,
        StrategicResourceStockpile::default(),
    )
    .expect("queue");
    let city = City::builder(
        CityId::new("capital").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_production(Some(queue), 0)
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [],
    )
    .with_cities([city])
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "production-turn-runtime",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
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
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
