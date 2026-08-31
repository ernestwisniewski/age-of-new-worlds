//! Current-only actor handoff for local hot-seat and multi-AI orchestration.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameLengthConfig, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState, RuleNumber,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules,
};
use aonw_local_runtime::{
    ActorHandoffError, LocalRuntime, MoveUnitRequest, OpenSession, ReachableRequest, RuntimeQuery,
};

#[test]
fn handoff_is_hot_seat_only_and_validates_the_actor() {
    let actor = player("player-1");
    assert_eq!(
        LocalRuntime::default().handoff_hot_seat_actor(actor.clone()),
        Err(ActorHandoffError::SessionNotOpen)
    );

    let mut multiplayer = opened(GameMode::Multiplayer);
    assert_eq!(
        multiplayer.handoff_hot_seat_actor(actor),
        Err(ActorHandoffError::NotHotSeat)
    );

    let mut hot_seat = opened(GameMode::HotSeat);
    let missing = player("missing");
    let error = hot_seat
        .handoff_hot_seat_actor(missing.clone())
        .expect_err("unknown player");
    assert_eq!(error, ActorHandoffError::UnknownPlayer(missing));
    assert!(error.to_string().starts_with("unknown hot-seat actor:"));
    assert_eq!(
        ActorHandoffError::SessionNotOpen.to_string(),
        "session is not open"
    );
    assert_eq!(
        ActorHandoffError::NotHotSeat.to_string(),
        "actor handoff requires a hot-seat match"
    );
}

#[test]
fn handoff_preserves_state_and_replay_across_two_authenticated_actors() {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let first = player("player-1");
    let second = player("player-2");
    let mut runtime = opened_with(map.clone(), rules.clone(), GameMode::HotSeat);
    let initial = *runtime.snapshot().expect("snapshot").stamp();
    let first_move = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id("unit-1"),
            target: HexCoord::new(1, 0),
        })
        .expect("first move");
    assert!(first_move.is_accepted());
    let first_query = RuntimeQuery::Reachable(ReachableRequest {
        expected_revision: 1,
        unit_id: unit_id("unit-1"),
    });
    runtime
        .query(&first_query)
        .expect("cached first-actor query");
    assert_eq!(runtime.query_cache_stats().misses, 1);
    let before_handoff = *runtime.snapshot().expect("first state").stamp();
    let handed = runtime
        .handoff_hot_seat_actor(second.clone())
        .expect("second actor");
    assert_eq!(handed, before_handoff);
    assert_eq!(
        runtime
            .snapshot()
            .expect("second view")
            .recipient_player_id(),
        &second
    );
    assert!(runtime.query(&first_query).is_err());
    assert_eq!(runtime.query_cache_stats().misses, 2);

    let second_move = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 1,
            unit_id: unit_id("unit-2"),
            target: HexCoord::new(2, 0),
        })
        .expect("second move");
    assert!(second_move.is_accepted());
    runtime
        .handoff_hot_seat_actor(first.clone())
        .expect("first actor again");
    assert_eq!(
        runtime
            .snapshot()
            .expect("first view")
            .recipient_player_id(),
        &first
    );
    assert_ne!(*runtime.snapshot().expect("final").stamp(), initial);

    let replay = runtime.export_replay_json().expect("multi-actor replay");
    let verified = LocalRuntime::verify_replay_json(map, rules, &replay).expect("exact replay");
    assert_eq!(verified.entry_count, 2);
    assert_eq!(verified.final_stamp, second_move.stamp);
}

fn opened(mode: GameMode) -> LocalRuntime {
    opened_with(map(), RulesetDefinition::standard().clone(), mode)
}

fn opened_with(map: MapDefinition, rules: RulesetDefinition, mode: GameMode) -> LocalRuntime {
    let first = player("player-1");
    let second = player("player-2");
    let identity = MatchIdentity::try_new(
        match_rules(),
        [participant(&first), participant(&second)],
        mode,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
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
    .expect("lifecycle");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("unit-1", &first, HexCoord::new(0, 0)),
            unit("unit-2", &second, HexCoord::new(3, 0)),
        ],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, first))
        .expect("open");
    runtime
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "hot-seat-handoff",
        GridLayout::OddQFlatTop,
        4,
        1,
        (0..4)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn match_rules() -> MatchRules {
    MatchRules::new(
        GameLengthConfig::default(),
        VictoryRules::try_new(
            false,
            false,
            RuleNumber::new("60").expect("percent"),
            1,
            true,
            Some(8),
            None,
            false,
            1,
            1,
        )
        .expect("victory"),
        BTreeMap::new(),
    )
}

fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Ai,
        None,
    )
    .expect("participant")
}

fn unit(id: &str, owner: &PlayerId, position: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Commander,
        id,
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit")
}
