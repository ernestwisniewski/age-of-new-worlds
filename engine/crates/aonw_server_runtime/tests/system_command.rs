//! Trusted lifecycle command contract for the stateless multiplayer host.

use aonw_contract_mapping::encode_game_state;
use aonw_contracts::ReplaySystemCommandDto;
use aonw_contracts::server::{SERVER_HOST_API_VERSION, SystemCommandServerRequestDto};
use aonw_domain::{PlayerTurnState, StateRevision};
use aonw_engine::{KickParticipantCommand, SystemCommand};
use aonw_server_runtime::{
    ServerBoundaryError, SystemCommandRequest, apply_system_command, apply_system_command_dto,
};

#[test]
fn trusted_kick_uses_the_transactional_recipient_safe_path() {
    let fixture = fixture([]);
    let kicked = player("player-2");
    let outcome = apply_system_command(SystemCommandRequest {
        state: fixture.state,
        world: fixture.world,
        command: SystemCommand::KickParticipant(KickParticipantCommand::new(
            7, &kicked, "timeout", 3,
        )),
        initial_event_offset: 23,
    })
    .expect("kick participant");

    assert_eq!(outcome.rejection, None);
    assert_eq!(outcome.state.revision(), StateRevision::new(8));
    assert_eq!(outcome.initial_event_offset, 23);
    assert_eq!(outcome.final_event_offset, 24);
    assert_eq!(outcome.events.len(), 1);
    assert!(
        outcome
            .state
            .match_lifecycle()
            .turn()
            .kicked_player_ids()
            .contains(&kicked)
    );
    assert_eq!(
        outcome
            .state
            .match_lifecycle()
            .turn()
            .turn_states_by_player_id()
            .get(&kicked),
        Some(&PlayerTurnState::Finished)
    );
    assert_eq!(outcome.recipients.len(), 2);
    assert!(outcome.recipients.iter().all(|recipient| {
        recipient.patch.from_revision == 7
            && recipient.patch.to_revision == 8
            && recipient.events.len() == 1
            && recipient.snapshot.units().iter().all(|unit| {
                unit.owner_player_id() == &recipient.recipient_player_id
                    || unit.owned_details().is_none()
            })
    }));
}

#[test]
fn strict_timeout_dto_advances_the_same_canonical_turn() {
    let fixture = fixture([]);
    let request = SystemCommandServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        command: ReplaySystemCommandDto::FinalizeTimedOutTurn {
            expected_revision: 7,
            player_ids: vec!["player-1".to_owned(), "player-2".to_owned()],
            skipped_player_ids: vec!["player-1".to_owned(), "player-2".to_owned()],
            next_turn_started_at: None,
        },
        initial_event_offset: 41,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        state: encode_game_state(&fixture.state),
    };
    let result = apply_system_command_dto(fixture.world, request).expect("timeout finalization");

    assert_eq!(result.rejection, None);
    assert_eq!(result.stamp.revision, 8);
    assert_eq!(result.initial_event_offset, 41);
    assert_eq!(
        result.final_event_offset,
        41 + u64::try_from(result.events.len()).expect("event count")
    );
    assert_eq!(result.recipients.len(), 2);
    assert!(result.recipients.iter().all(|recipient| {
        recipient.patch.from_revision == 7
            && recipient.patch.to_revision == 8
            && recipient.snapshot.turn == 8
    }));
}

#[test]
fn strict_system_dto_rejects_invalid_host_values_before_execution() {
    let fixture = fixture([]);
    let request = SystemCommandServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        command: ReplaySystemCommandDto::KickParticipant {
            expected_revision: 7,
            player_id: "   ".to_owned(),
            reason: "timeout".to_owned(),
            timeout_streak: 3,
        },
        initial_event_offset: 0,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        state: encode_game_state(&fixture.state),
    };

    assert!(matches!(
        apply_system_command_dto(fixture.world, request),
        Err(ServerBoundaryError::InvalidSystemCommand(_))
    ));
}

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;

use support::{fixture, player};
