use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientEventDto, ClientOutcomeDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{ReplayEventDto, ReplayLogDto, StabilityBandDto};
use aonw_domain::{
    City, CityId, EconomyState, GameMode, GameState, HexCoord, InitialResourceDistribution,
    MatchIdentity, MatchLifecycle, MatchRules, PlayerId, PlayerTurnState, StateRevision,
    TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

use super::participant;

#[test]
fn economy_events_are_recipient_safe_saved_and_exactly_replayed() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open economy runtime");
    let events = dispatch_end_turn(&mut runtime);
    assert!(events.iter().any(|event| matches!(
        event,
        ClientEventDto::CityClaimedHex { city_id, col: 0, row: 1 }
            if city_id == "city-1"
    )));
    assert!(events.iter().any(|event| matches!(
        event,
        ClientEventDto::StabilityBandChanged {
            player_id,
            previous_band: StabilityBandDto::Content,
            new_band: StabilityBandDto::Stable,
            net: 1,
        } if player_id == "player-1"
    )));

    let replay_json = runtime.export_replay_json().expect("economy replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    assert!(
        replay.segments[0].entries[0]
            .result
            .events
            .iter()
            .any(|event| matches!(
                event,
                ReplayEventDto::CityClaimedHex { city_id, col: 0, row: 1 }
                    if city_id == "city-1"
            ))
    );
    assert!(
        replay.segments[0].entries[0]
            .result
            .events
            .iter()
            .any(|event| matches!(
                event,
                ReplayEventDto::StabilityBandChanged {
                    player_id,
                    previous_band: StabilityBandDto::Content,
                    new_band: StabilityBandDto::Stable,
                    net: 1,
                } if player_id == "player-1"
            ))
    );
    assert_eq!(
        LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
            .expect("verify economy replay")
            .entry_count,
        1
    );
    let save = runtime.export_save_json().expect("economy save");
    let expected = runtime.snapshot().expect("economy snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen economy save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);
}

fn dispatch_end_turn(runtime: &mut LocalRuntime) -> Vec<ClientEventDto> {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::EndTurn {
                expected_revision: 7,
            },
        },
    }
    .to_json()
    .expect("request");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &request))
        .expect("response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol failure")
    };
    let ClientResponseBodyDto::Command { result } = *response else {
        panic!("command response")
    };
    result.events
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(actor.clone(), "One")],
        GameMode::HotSeat,
    )
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
    let city = City::builder(
        CityId::new("city-1").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .with_progression(1, 21, 6, 2)
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .with_planning(None, Some(HexCoord::new(0, 1)))
    .build()
    .expect("city");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::new(),
        BTreeMap::from([(actor.clone(), 8)]),
        BTreeMap::from([(actor.clone(), 4)]),
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
    (map, rules, state, actor)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "runtime-economy-turn",
        GridLayout::OddQFlatTop,
        3,
        2,
        (0..2)
            .flat_map(|row| {
                (0..3).map(move |col| {
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
