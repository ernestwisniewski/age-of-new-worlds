//! Runtime, persistence, projection, and trusted-boundary tests for T1.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientEventDto, ClientOutcomeDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{ReplayLogDto, ReplayRecordDto};
use aonw_domain::{
    Diplomacy, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationStatus, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle,
    MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerPair,
    PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{
    ClientProtocol, FinalizeTimedOutTurnRequest, LocalRuntime, OpenSession, RuntimeError,
    TurnCommandRequest,
};

#[path = "turn_kernel_runtime/economy.rs"]
mod economy;
#[path = "turn_kernel_runtime/objective.rs"]
mod objective;
#[path = "turn_kernel_runtime/outcome.rs"]
mod outcome;

#[test]
fn player_and_system_records_replay_with_exact_lifecycle_and_offsets() {
    let (map, rules, state, p1, p2) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(
            OpenSession::from_state(map.clone(), rules.clone(), state, p1.clone())
                .with_event_offset(10),
        )
        .expect("open");

    let initial = runtime.snapshot().expect("snapshot");
    assert_eq!(
        initial.turn_lifecycle().own_state(),
        Some(PlayerTurnState::Active)
    );
    assert_eq!(initial.turn_lifecycle().required_submission_count(), 2);
    assert_eq!(initial.turn_lifecycle().submitted_count(), 0);

    let submitted = runtime
        .submit_turn(TurnCommandRequest {
            expected_revision: 7,
        })
        .expect("submit");
    assert!(submitted.is_accepted());
    assert!(submitted.events.is_empty());
    assert_eq!(submitted.view_patch.turn, 7);
    assert!(submitted.view_patch.turn_lifecycle.is_some());
    assert!(submitted.view_patch.upserted_units.is_empty());

    let partial_save = runtime.export_save_json().expect("partial save");
    let partial_snapshot = runtime.snapshot().expect("partial snapshot");
    let mut partial_reopened = LocalRuntime::default();
    partial_reopened
        .open_save_json(map.clone(), rules.clone(), &partial_save)
        .expect("reopen partial turn");
    assert_eq!(
        partial_reopened.snapshot().expect("reopened partial turn"),
        partial_snapshot
    );

    let finalized = runtime
        .finalize_timed_out_turn(&FinalizeTimedOutTurnRequest {
            expected_revision: 8,
            player_ids: vec![p1.clone(), p2.clone()].into_boxed_slice(),
            skipped_player_ids: vec![p2].into_boxed_slice(),
            next_turn_started_at: None,
        })
        .expect("trusted timeout");
    assert!(finalized.is_accepted());
    assert_eq!(finalized.events.len(), 4);
    assert_eq!(finalized.view_patch.turn, 8);
    assert!(finalized.view_patch.turn_lifecycle.is_some());

    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    assert_eq!(replay.segments.len(), 1);
    let entries = &replay.segments[0].entries;
    assert_eq!(entries.len(), 2);
    assert!(matches!(entries[0].record, ReplayRecordDto::Player { .. }));
    assert_eq!(
        entries[0].context.actor_player_id.as_deref(),
        Some("player-1")
    );
    assert!(matches!(entries[1].record, ReplayRecordDto::System { .. }));
    assert_eq!(entries[1].context.actor_player_id, None);
    assert_eq!(entries[1].result.event_offset, 14);

    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify replay");
    assert_eq!(verification.entry_count, 2);
    assert_eq!(verification.final_event_offset, 14);

    let save = runtime.export_save_json().expect("save");
    let expected = runtime.snapshot().expect("expected snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);
}

#[test]
fn system_event_preflight_is_transactional() {
    let (map, rules, state, p1, p2) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(
            OpenSession::from_state(map, rules, state, p1.clone()).with_event_offset(u64::MAX - 3),
        )
        .expect("open");
    let before = runtime.snapshot().expect("before");
    let error = runtime
        .finalize_timed_out_turn(&FinalizeTimedOutTurnRequest {
            expected_revision: 7,
            player_ids: vec![p1, p2.clone()].into_boxed_slice(),
            skipped_player_ids: vec![p2].into_boxed_slice(),
            next_turn_started_at: None,
        })
        .expect_err("preflight must reject");
    assert_eq!(error, RuntimeError::EventOffsetOverflow);
    assert_eq!(runtime.snapshot().expect("after"), before);
}

#[test]
fn client_protocol_has_no_system_command_variant() {
    let payload = format!(
        r#"{{"apiVersion":{CLIENT_API_VERSION},"request":{{"type":"dispatch","command":{{"type":"kickParticipant","expectedRevision":7,"playerId":"player-2","reason":"timeout","timeoutStreak":3}}}}}}"#
    );
    assert!(ClientRequestDto::from_json(&payload).is_err());
    let response = ClientProtocol::dispatch_json(&mut LocalRuntime::default(), &payload);
    assert!(response.contains("invalid_client_request"));
}

#[test]
fn diplomacy_expiry_events_are_recipient_safe_saved_and_exactly_replayed() {
    let (map, rules, state, p1, _p2) = fixture_with_expiry();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            p1.clone(),
        ))
        .expect("open");
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
    let response =
        ClientResponseDto::from_json(&ClientProtocol::dispatch_json(&mut runtime, &request))
            .expect("response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol failure")
    };
    let ClientResponseBodyDto::Command { result } = *response else {
        panic!("command response")
    };
    assert!(result.events.iter().any(|event| matches!(
        event,
        ClientEventDto::DiplomaticProposalExpired {
            proposal_id,
            ..
        } if proposal_id == "proposal-expired"
    )));
    assert!(result.events.iter().any(|event| matches!(
        event,
        ClientEventDto::DiplomaticRelationChanged {
            old_status: aonw_contracts::DiplomaticRelationStatusDto::Truce,
            new_status: aonw_contracts::DiplomaticRelationStatusDto::Neutral,
            ..
        }
    )));
    let replay = runtime.export_replay_json().expect("replay");
    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay)
        .expect("verify replay");
    assert_eq!(verification.entry_count, 1);
    let save = runtime.export_save_json().expect("save");
    let expected = runtime.snapshot().expect("snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen save");
    assert_eq!(reopened.snapshot().expect("reopened"), expected);
}

fn fixture() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    fixture_with(false)
}

fn fixture_with_expiry() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    fixture_with(true)
}

fn fixture_with(
    with_expiry: bool,
) -> (
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
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let states = if with_expiry {
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Finished),
        ])
    } else {
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Active),
        ])
    };
    let submitted = with_expiry.then(|| p2.clone());
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        states,
        [p1.clone(), p2.clone()],
        submitted,
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let diplomacy = if with_expiry {
        let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
        let relation = DiplomaticRelation::try_new(
            pair.clone(),
            DiplomaticRelationStatus::Truce,
            0,
            Some(8),
            Some(7),
            None,
        )
        .expect("relation");
        let proposal = DiplomaticProposal::try_new(
            "proposal-expired".to_owned(),
            p1.clone(),
            p2.clone(),
            DiplomaticProposalKind::Friendship,
            7,
            8,
            0,
        )
        .expect("proposal");
        Diplomacy::try_new(&identity, [pair], [relation], [proposal], [], [], [])
            .expect("diplomacy")
    } else {
        Diplomacy::default()
    };
    let units = [unit("unit-1", &p1, 0), unit("unit-2", &p2, 1)];
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_diplomacy(diplomacy)
    .try_build()
    .expect("state");
    (map, rules, state, p1, p2)
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

fn unit(id: &str, owner: &PlayerId, col: i32) -> Unit {
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
        "runtime-turn-kernel",
        GridLayout::OddQFlatTop,
        2,
        1,
        (0..2)
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
