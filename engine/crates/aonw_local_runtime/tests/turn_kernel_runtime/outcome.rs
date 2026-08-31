use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientCommandRejectionCodeDto,
    ClientEventDto, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{GameOutcomeConditionDto, ReplayEventDto, ReplayLogDto};
use aonw_domain::{
    GameLengthConfig, GameMode, GameOutcomeCondition, GameState, HexCoord, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, PlayerId, PlayerTurnState, RuleNumber,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules,
};
use aonw_local_runtime::{
    ClientProtocol, FinalizeTimedOutTurnRequest, LocalRuntime, OpenSession, TurnCommandRequest,
};

use super::{participant, player};

#[test]
fn terminal_outcome_is_global_persisted_replayable_and_rejects_later_commands() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor.clone(),
        ))
        .expect("open outcome runtime");

    let result = dispatch_submit(&mut runtime, 7);
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        result.view_patch.outcome.as_ref(),
        Some(outcome)
            if outcome.condition == GameOutcomeConditionDto::Conquest
                && outcome.winner_player_id.as_deref() == Some("player-1")
                && outcome.score_by_player_id.is_empty()
    ));
    assert!(result.events.iter().any(|event| matches!(
        event,
        ClientEventDto::MatchEnded { turn: 8, outcome }
            if outcome.condition == GameOutcomeConditionDto::Conquest
                && outcome.winner_player_id.as_deref() == Some("player-1")
    )));
    let snapshot = runtime.snapshot().expect("terminal snapshot");
    assert_eq!(
        snapshot.outcome().condition(),
        GameOutcomeCondition::Conquest
    );
    assert_eq!(snapshot.outcome().winner_player_id(), Some(&actor));

    let rejected = dispatch_submit(&mut runtime, result.stamp.revision);
    assert_eq!(
        rejected.outcome,
        ClientCommandOutcomeDto::Rejected {
            code: ClientCommandRejectionCodeDto::MatchFinished,
        }
    );
    assert!(rejected.events.is_empty());
    assert_eq!(rejected.stamp.revision, result.stamp.revision);

    let replay_json = runtime.export_replay_json().expect("outcome replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    assert!(
        replay.segments[0].entries[0]
            .result
            .events
            .iter()
            .any(|event| matches!(
                event,
                ReplayEventDto::MatchEnded { turn: 8, outcome }
                    if outcome.condition == GameOutcomeConditionDto::Conquest
                        && outcome.winner_player_id.as_deref() == Some("player-1")
            ))
    );
    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify outcome replay");
    assert_eq!(verification.entry_count, 2);

    let save = runtime.export_save_json().expect("outcome save");
    let expected = runtime.snapshot().expect("expected terminal snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen outcome save");
    assert_eq!(
        reopened.snapshot().expect("reopened terminal state"),
        expected
    );
}

#[test]
fn bounded_terminal_soak_is_byte_deterministic() {
    let mut expected = None;
    for _ in 0..64 {
        let (map, rules, state, actor) = fixture();
        let mut runtime = LocalRuntime::default();
        runtime
            .open(OpenSession::from_state(map, rules, state, actor))
            .expect("open soak runtime");
        let result = runtime
            .submit_turn(TurnCommandRequest {
                expected_revision: 7,
            })
            .expect("finish soak match");
        assert!(result.is_accepted());
        let artifacts = (
            runtime.export_save_json().expect("soak save"),
            runtime.export_replay_json().expect("soak replay"),
        );
        if let Some(expected) = &expected {
            assert_eq!(&artifacts, expected);
        } else {
            expected = Some(artifacts);
        }
    }
}

#[test]
fn bounded_full_game_reopens_and_replays_every_turn_boundary() {
    let mut expected_saves = None;
    for _ in 0..8 {
        let (map, rules, state, p1, p2) = score_fixture();
        let mut runtime = LocalRuntime::default();
        runtime
            .open(OpenSession::from_state(
                map.clone(),
                rules.clone(),
                state,
                p1.clone(),
            ))
            .expect("open full-game soak runtime");
        let mut saves = Vec::new();
        loop {
            let revision = runtime
                .snapshot()
                .expect("turn-boundary snapshot")
                .stamp()
                .revision
                .get();
            runtime
                .finalize_timed_out_turn(&FinalizeTimedOutTurnRequest {
                    expected_revision: revision,
                    player_ids: vec![p1.clone(), p2.clone()].into_boxed_slice(),
                    skipped_player_ids: Box::new([]),
                    next_turn_started_at: None,
                })
                .expect("advance full-game turn");
            let replay = runtime.export_replay_json().expect("turn replay");
            LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay)
                .expect("verify turn replay");
            let save = runtime.export_save_json().expect("turn save");
            let expected = runtime.snapshot().expect("saved turn snapshot");
            let terminal = expected.outcome().is_terminal();
            let mut reopened = LocalRuntime::default();
            reopened
                .open_save_json(map.clone(), rules.clone(), &save)
                .expect("reopen at turn boundary");
            assert_eq!(reopened.snapshot().expect("reopened turn"), expected);
            saves.push(save);
            runtime = reopened;
            if terminal {
                assert_eq!(
                    runtime
                        .snapshot()
                        .expect("terminal full-game snapshot")
                        .outcome()
                        .condition(),
                    GameOutcomeCondition::Draw
                );
                break;
            }
        }
        if let Some(expected) = &expected_saves {
            assert_eq!(&saves, expected);
        } else {
            expected_saves = Some(saves);
        }
    }
}

fn dispatch_submit(
    runtime: &mut LocalRuntime,
    expected_revision: u64,
) -> Box<aonw_contracts::client::ClientCommandResultDto> {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SubmitTurn { expected_revision },
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

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
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
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Finished),
        ]),
        [p1.clone(), p2.clone()],
        [p2],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [unit("unit-1", &p1)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, p1)
}

fn score_fixture() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let match_rules = MatchRules::new(
        GameLengthConfig::default(),
        VictoryRules::try_new(
            false,
            false,
            RuleNumber::new("60").expect("percent"),
            5,
            true,
            Some(4),
            None,
            false,
            6,
            5,
        )
        .expect("score victory rules"),
        BTreeMap::new(),
    );
    let identity = MatchIdentity::try_new(
        match_rules,
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("score identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("score lifecycle");
    let state = GameState::builder(
        StateRevision::new(7),
        1,
        map.bounds(),
        rules.occupancy_policy(),
        [unit_at("unit-1", &p1, 0), unit_at("unit-2", &p2, 1)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("score state");
    (map, rules, state, p1, p2)
}

fn unit(id: &str, owner: &PlayerId) -> Unit {
    unit_at(id, owner, 0)
}

fn unit_at(id: &str, owner: &PlayerId, col: i32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(col, 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "runtime-outcome",
        GridLayout::OddQFlatTop,
        2,
        1,
        (0..2)
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
        Vec::new(),
    )
    .expect("map")
}
