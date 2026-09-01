use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, MapObjective, MapObjectiveType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandResultDto, ClientEventDto, ClientOutcomeDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{ReplayEventDto, ReplayLogDto};
use aonw_domain::{
    City, CityId, EconomyState, FogOfWar, GameMode, GameState, HexCoord,
    InitialResourceDistribution, MapObjectiveHoldState, MatchIdentity, MatchLifecycle, MatchRules,
    ObjectiveState, PlayerFog, PlayerId, PlayerTurnState, StateRevision, TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

use super::{participant, player, unit};

#[test]
fn objective_events_are_recipient_safe_saved_and_exactly_replayed() {
    let (map, rules, visible_state, p1, p2) = fixture(&player("player-2"));
    let mut visible = LocalRuntime::default();
    visible
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            visible_state,
            p2,
        ))
        .expect("open visible");
    let result = dispatch_submit(&mut visible);
    let events = &result.events;
    assert!(events.iter().any(|event| matches!(
        event,
        ClientEventDto::MapObjectiveSecured {
            player_id,
            objective_id,
            ..
        } if player_id == "player-2" && objective_id == "central-ruins"
    )));
    let visible_snapshot = visible.snapshot().expect("visible snapshot");
    let visible_victory = visible_snapshot.victory();
    assert_eq!(
        visible_victory.map_objectives()[0]
            .controller_player_id()
            .map(PlayerId::as_str),
        Some("player-2")
    );
    assert!(result.view_patch.victory.is_some());
    assert!(events.iter().any(|event| matches!(
        event,
        ClientEventDto::DominationThresholdReached { player_id, .. }
            if player_id == "player-2"
    )));
    assert_replay_and_save(&visible, &map, &rules);

    let (_, _, foreign_state, _, _) = fixture(&p1);
    let mut foreign = LocalRuntime::default();
    foreign
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            foreign_state,
            p1,
        ))
        .expect("open foreign");
    let result = dispatch_submit(&mut foreign);
    let events = &result.events;
    assert!(
        !events
            .iter()
            .any(|event| matches!(event, ClientEventDto::MapObjectiveSecured { .. }))
    );
    assert!(events.iter().any(|event| matches!(
        event,
        ClientEventDto::DominationThresholdReached { player_id, .. }
            if player_id == "player-2"
    )));
    let foreign_snapshot = foreign.snapshot().expect("foreign snapshot");
    let foreign_victory = foreign_snapshot.victory();
    assert_eq!(
        foreign_victory.map_objectives()[0].controller_player_id(),
        None
    );
    assert_eq!(foreign_victory.map_objectives()[0].hold_turns(), 0);
    assert!(result.view_patch.victory.is_some());
    let replay = foreign.export_replay_json().expect("foreign replay");
    assert!(replay.contains("mapObjectiveSecured"));
    LocalRuntime::verify_replay_json(map, rules, &replay).expect("foreign replay verify");
}

fn assert_replay_and_save(runtime: &LocalRuntime, map: &MapDefinition, rules: &RulesetDefinition) {
    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    assert!(
        replay.segments[0].entries[0]
            .result
            .events
            .iter()
            .any(|event| matches!(
                event,
                ReplayEventDto::MapObjectiveSecured { objective_id, .. }
                    if objective_id == "central-ruins"
            ))
    );
    assert!(
        replay.segments[0].entries[0]
            .result
            .events
            .iter()
            .any(|event| matches!(
                event,
                ReplayEventDto::DominationThresholdReached { player_id, .. }
                    if player_id == "player-2"
            ))
    );
    LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify replay");
    let save = runtime.export_save_json().expect("save");
    let expected = runtime.snapshot().expect("snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &save)
        .expect("reopen objective save");
    assert_eq!(reopened.snapshot().expect("reopened"), expected);
}

fn dispatch_submit(runtime: &mut LocalRuntime) -> Box<ClientCommandResultDto> {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SubmitTurn {
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
    result
}

fn fixture(
    final_actor: &PlayerId,
) -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    let map = objective_map();
    let rules = RulesetDefinition::standard().clone();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let submitted = if final_actor == &p1 { &p2 } else { &p1 };
    let lifecycle = lifecycle(&identity, &p1, &p2, submitted);
    let city = City::new(
        CityId::new("city-2").expect("city id"),
        p2.clone(),
        HexCoord::new(0, 0),
        [HexCoord::new(1, 0), HexCoord::new(2, 0)],
    );
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p2.clone(), 4)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::new(),
        [
            MapObjectiveHoldState::try_new("central-ruins".to_owned(), p2.clone(), 1)
                .expect("hold"),
        ],
    )
    .expect("objectives");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [unit("unit-1", &p1, 4), unit("unit-2", &p2, 0)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities([city])
    .with_economy(economy)
    .with_objectives(objectives)
    .with_fog_of_war(
        FogOfWar::try_new([
            PlayerFog::new(p1.clone(), [], [HexCoord::new(4, 0)]),
            PlayerFog::new(p2.clone(), [], [HexCoord::new(0, 0)]),
        ])
        .expect("fog"),
    )
    .try_build()
    .expect("state");
    (map, rules, state, p1, p2)
}

fn lifecycle(
    identity: &MatchIdentity,
    p1: &PlayerId,
    p2: &PlayerId,
    submitted: &PlayerId,
) -> TurnLifecycle {
    let state = |player: &PlayerId| {
        if player == submitted {
            PlayerTurnState::Finished
        } else {
            PlayerTurnState::Active
        }
    };
    TurnLifecycle::try_new(
        identity,
        BTreeMap::from([(p1.clone(), state(p1)), (p2.clone(), state(p2))]),
        [p1.clone(), p2.clone()],
        [submitted.clone()],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle")
}

fn objective_map() -> MapDefinition {
    let objective = MapObjective::try_new(
        "central-ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(0, 0),
        2,
        5,
        3,
    )
    .expect("objective");
    MapDefinition::try_new(
        "runtime-objectives",
        GridLayout::OddQFlatTop,
        5,
        1,
        (0..5)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        vec![objective],
    )
    .expect("map")
}
