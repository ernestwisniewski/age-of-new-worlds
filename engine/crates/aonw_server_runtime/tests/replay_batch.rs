//! Replay journal verification and recipient isolation at the server boundary.
use aonw_contract_mapping::encode_game_state;
use aonw_contracts::ReplaySystemCommandDto;
use aonw_contracts::client::ClientCommandDto;
use aonw_contracts::server::{
    MAX_SERVER_REPLAY_BATCH_STEPS, PlayerCommandServerRequestDto, SERVER_HOST_API_VERSION,
    ServerReplayBatchRequestDto, ServerReplayRecordDto, ServerReplayStepDto,
    SystemCommandServerRequestDto,
};
use aonw_engine::{ENGINE_BEHAVIOR_FINGERPRINT, GameEngine};
use aonw_server_runtime::{
    ServerBoundaryError, apply_player_command_dto, apply_system_command_dto,
    replay_server_batch_dto,
};

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;
use support::{Fixture, fixture};

fn request(fixture: &Fixture) -> ServerReplayBatchRequestDto {
    ServerReplayBatchRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        behavior_fingerprint: ENGINE_BEHAVIOR_FINGERPRINT.to_owned(),
        initial_state: encode_game_state(&fixture.state),
        initial_state_digest: GameEngine::state_digest(&fixture.state).to_string(),
        initial_event_offset: 23,
        recipient_player_id: "player-1".to_owned(),
        steps: vec![],
    }
}

fn journal(fixture: &Fixture) -> ServerReplayBatchRequestDto {
    let mut request = request(fixture);
    let command = ClientCommandDto::FortifyUnit {
        expected_revision: 7,
        unit_id: "unit-1".to_owned(),
    };
    let applied = apply_player_command_dto(
        fixture.world.clone(),
        PlayerCommandServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            authenticated_actor_player_id: "player-1".to_owned(),
            command: command.clone(),
            initial_event_offset: 23,
            map_hash: request.map_hash.clone(),
            ruleset_hash: request.ruleset_hash.clone(),
            state: request.initial_state.clone(),
        },
    )
    .expect("record accepted command");
    assert_eq!(applied.rejection, None);
    assert_eq!(applied.stamp.revision, 8);
    request.steps.push(ServerReplayStepDto {
        record: ServerReplayRecordDto::Player {
            actor_player_id: "player-1".to_owned(),
            command,
        },
        revision: 8,
        state_digest: applied.stamp.state_digest,
        initial_event_offset: 23,
        final_event_offset: 23,
    });
    request
}

#[test]
fn empty_batch_projects_checkpoint_without_command() {
    let fixture = fixture([]);
    let request = request(&fixture);
    let result = replay_server_batch_dto(&fixture.world, request.clone()).expect("checkpoint");
    assert_eq!(result.state, request.initial_state);
    assert_eq!(result.stamp.revision, 7);
    assert_eq!(result.final_event_offset, 23);
    assert!(result.command.is_none());
}

#[test]
fn replay_matches_live_execution_and_filters_other_players_private_data() {
    let fixture = fixture([]);
    let request = journal(&fixture);
    for player in ["player-1", "player-2"] {
        let mut input = request.clone();
        input.recipient_player_id = player.to_owned();
        let result = replay_server_batch_dto(&fixture.world, input).expect("replay");
        assert_eq!(result.stamp.revision, 8);
        assert_eq!(result.stamp.state_digest, request.steps[0].state_digest);
        let command = result.command.expect("last command");
        assert_eq!(command.view_patch.from_revision, 7);
        assert_eq!(command.view_patch.to_revision, 8);
        assert!(
            result
                .snapshot
                .units
                .iter()
                .all(|unit| unit.owner_player_id == player || unit.owned_details.is_none())
        );
        assert!(command.events.is_empty());
    }
}

#[test]
fn replay_system_command_continues_from_verified_checkpoint() {
    let fixture = fixture([]);
    let first = replay_server_batch_dto(&fixture.world, journal(&fixture)).expect("first batch");
    let command = ReplaySystemCommandDto::ResignParticipant {
        expected_revision: 8,
        player_id: "player-2".to_owned(),
    };
    let applied = apply_system_command_dto(
        fixture.world.clone(),
        SystemCommandServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            command: command.clone(),
            initial_event_offset: first.final_event_offset,
            map_hash: first.stamp.map_hash.clone(),
            ruleset_hash: first.stamp.ruleset_hash.clone(),
            state: first.state.clone(),
        },
    )
    .expect("record system command");
    assert_eq!(applied.rejection, None);
    let mut input = request(&fixture);
    input.initial_state = first.state;
    input.initial_state_digest = first.stamp.state_digest;
    input.initial_event_offset = first.final_event_offset;
    input.steps.push(ServerReplayStepDto {
        record: ServerReplayRecordDto::System { command },
        revision: 9,
        state_digest: applied.stamp.state_digest.clone(),
        initial_event_offset: applied.initial_event_offset,
        final_event_offset: applied.final_event_offset,
    });
    let result = replay_server_batch_dto(&fixture.world, input).expect("system replay");
    assert_eq!(result.state, applied.state);
    assert_eq!(result.stamp, applied.stamp);
    assert_eq!(result.final_event_offset, applied.final_event_offset);
}

#[test]
fn timeout_replay_retains_explicit_context_and_batch_boundaries() {
    let fixture = fixture([]);
    let mut input = journal(&fixture);
    let first = replay_server_batch_dto(&fixture.world, input.clone()).expect("first step");
    let command = ReplaySystemCommandDto::FinalizeTimedOutTurn {
        expected_revision: 8,
        player_ids: vec!["player-1".to_owned(), "player-2".to_owned()],
        skipped_player_ids: vec!["player-1".to_owned(), "player-2".to_owned()],
        next_turn_started_at: Some("2026-09-12T10:00:00Z".to_owned()),
    };
    let applied = apply_system_command_dto(
        fixture.world.clone(),
        SystemCommandServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            command: command.clone(),
            initial_event_offset: first.final_event_offset,
            map_hash: input.map_hash.clone(),
            ruleset_hash: input.ruleset_hash.clone(),
            state: first.state.clone(),
        },
    )
    .expect("timeout");
    assert_eq!(applied.rejection, None);
    assert_eq!(applied.state.turn, 8);
    input.steps.push(ServerReplayStepDto {
        record: ServerReplayRecordDto::System { command },
        revision: 9,
        state_digest: applied.stamp.state_digest.clone(),
        initial_event_offset: applied.initial_event_offset,
        final_event_offset: applied.final_event_offset,
    });
    let whole = replay_server_batch_dto(&fixture.world, input.clone()).expect("whole batch");
    input.initial_state = first.state;
    input.initial_state_digest = first.stamp.state_digest;
    input.initial_event_offset = first.final_event_offset;
    input.steps.remove(0);
    let split = replay_server_batch_dto(&fixture.world, input.clone()).expect("split batch");
    assert_eq!(whole, split);
    assert_eq!(whole.state, applied.state);
    if let ServerReplayRecordDto::System {
        command:
            ReplaySystemCommandDto::FinalizeTimedOutTurn {
                next_turn_started_at,
                ..
            },
    } = &mut input.steps[0].record
    {
        *next_turn_started_at = Some("2026-09-12T10:01:00Z".to_owned());
    }
    assert!(matches!(
        replay_server_batch_dto(&fixture.world, input),
        Err(ServerBoundaryError::ReplayMismatch)
    ));
}

#[test]
fn replay_rejects_checkpoint_identity_recipient_and_journal_drift() {
    let fixture = fixture([]);
    let valid = journal(&fixture);
    let mutations: [fn(&mut ServerReplayBatchRequestDto); 9] = [
        |r| r.behavior_fingerprint.push('x'),
        |r| r.initial_state_digest.push('x'),
        |r| r.recipient_player_id = "outsider".to_owned(),
        |r| r.steps[0].revision += 1,
        |r| r.steps[0].state_digest.push('x'),
        |r| r.steps[0].initial_event_offset += 1,
        |r| r.steps[0].final_event_offset += 1,
        |r| {
            if let ServerReplayRecordDto::Player {
                command:
                    ClientCommandDto::FortifyUnit {
                        expected_revision, ..
                    },
                ..
            } = &mut r.steps[0].record
            {
                *expected_revision = 0;
            }
        },
        |r| r.steps = vec![r.steps[0].clone(); MAX_SERVER_REPLAY_BATCH_STEPS + 1],
    ];
    for mutate in mutations {
        let mut input = valid.clone();
        mutate(&mut input);
        assert!(matches!(
            replay_server_batch_dto(&fixture.world, input),
            Err(ServerBoundaryError::ReplayMismatch)
        ));
    }
    let mut input = valid;
    input.map_hash.push('x');
    assert!(matches!(
        replay_server_batch_dto(&fixture.world, input),
        Err(ServerBoundaryError::ContentIdentityMismatch)
    ));
}

#[test]
fn replay_json_is_strict_and_round_trips() {
    let fixture = fixture([]);
    let request = journal(&fixture);
    let json = serde_json::to_string(&request).expect("encode");
    assert_eq!(
        ServerReplayBatchRequestDto::from_json(&json).expect("decode"),
        request
    );
    let mut value: serde_json::Value = serde_json::from_str(&json).expect("value");
    value["steps"][0]["record"]["system"] = true.into();
    assert!(ServerReplayBatchRequestDto::from_json(&value.to_string()).is_err());
}
