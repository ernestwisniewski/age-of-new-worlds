//! Transaction and privacy contract for generic remote player commands.

use aonw_contract_mapping::encode_game_state;
use aonw_contracts::client::ClientCommandDto;
use aonw_contracts::server::{PlayerCommandServerRequestDto, SERVER_HOST_API_VERSION};
use aonw_domain::{PlayerTurnState, StateRevision, UnitId, UnitPosture};
use aonw_engine::{PlayerCommand, TurnCommand, UnitActionCommand};
use aonw_server_runtime::{
    PlayerCommandRequest, ServerBoundaryError, apply_player_command, apply_player_command_dto,
};

#[test]
fn non_turn_command_uses_the_transactional_recipient_safe_path() {
    let fixture = fixture([]);
    let actor = player("player-1");
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let outcome = apply_player_command(PlayerCommandRequest {
        state: fixture.state,
        world: fixture.world,
        authenticated_actor: actor.clone(),
        command: PlayerCommand::FortifyUnit(UnitActionCommand::new(7, &unit_id)),
        initial_event_offset: 23,
    })
    .expect("fortify unit");

    assert_eq!(outcome.rejection, None);
    assert_eq!(outcome.state.revision(), StateRevision::new(8));
    assert_eq!(outcome.initial_event_offset, 23);
    assert_eq!(outcome.final_event_offset, 23);
    assert!(outcome.events.is_empty());
    assert_eq!(outcome.recipients.len(), 2);
    for recipient in &outcome.recipients {
        assert_eq!(recipient.patch.from_revision, 7);
        assert_eq!(recipient.patch.to_revision, 8);
        assert!(recipient.events.is_empty());
        assert!(recipient.snapshot.units().iter().all(|unit| {
            unit.owner_player_id() == &recipient.recipient_player_id
                || unit.owned_details().is_none()
        }));
    }
    let actor_view = outcome
        .recipients
        .iter()
        .find(|recipient| recipient.recipient_player_id == actor)
        .expect("actor view");
    assert_eq!(
        actor_view
            .snapshot
            .units()
            .iter()
            .find(|unit| unit.id() == &unit_id)
            .expect("fortified unit")
            .posture(),
        UnitPosture::Fortified
    );
}

#[test]
fn embedded_turn_actor_is_rebound_to_the_authenticated_player() {
    let fixture = fixture([]);
    let authenticated_actor = player("player-1");
    let forged_actor = player("player-2");
    let outcome = apply_player_command(PlayerCommandRequest {
        state: fixture.state,
        world: fixture.world,
        authenticated_actor: authenticated_actor.clone(),
        command: PlayerCommand::SubmitTurn(TurnCommand::new(7, &forged_actor)),
        initial_event_offset: 31,
    })
    .expect("submit authenticated turn");

    assert_eq!(outcome.rejection, None);
    let turn = outcome.state.match_lifecycle().turn();
    assert!(turn.submitted_player_ids().contains(&authenticated_actor));
    assert!(!turn.submitted_player_ids().contains(&forged_actor));
    assert_eq!(
        turn.turn_states_by_player_id().get(&authenticated_actor),
        Some(&PlayerTurnState::Finished)
    );
    assert_eq!(
        turn.turn_states_by_player_id().get(&forged_actor),
        Some(&PlayerTurnState::Active)
    );
}

#[test]
fn strict_player_command_dto_uses_the_same_typed_command_shape() {
    let fixture = fixture([]);
    let map_hash = fixture.world.map_hash().to_string();
    let ruleset_hash = fixture.world.ruleset_hash().to_string();
    let request = PlayerCommandServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        authenticated_actor_player_id: "player-1".to_owned(),
        command: ClientCommandDto::FortifyUnit {
            expected_revision: 7,
            unit_id: "unit-1".to_owned(),
        },
        initial_event_offset: 41,
        map_hash,
        ruleset_hash,
        state: encode_game_state(&fixture.state),
    };
    let result = apply_player_command_dto(fixture.world, request).expect("strict command");

    assert_eq!(result.rejection, None);
    assert_eq!(result.stamp.revision, 8);
    assert_eq!(result.initial_event_offset, 41);
    assert_eq!(result.final_event_offset, 41);
    assert_eq!(result.recipients.len(), 2);
    assert!(result.recipients.iter().all(|recipient| {
        recipient.patch.from_revision == 7
            && recipient.patch.to_revision == 8
            && recipient.snapshot.units.iter().all(|unit| {
                unit.owner_player_id == recipient.recipient_player_id
                    || unit.owned_details.is_none()
            })
    }));
}

#[test]
fn strict_player_command_dto_rejects_invalid_nested_identity() {
    let fixture = fixture([]);
    let request = PlayerCommandServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        authenticated_actor_player_id: "player-1".to_owned(),
        command: ClientCommandDto::MoveUnit {
            expected_revision: 7,
            unit_id: "   ".to_owned(),
            target: aonw_contracts::CoordinateDto { col: 0, row: 0 },
        },
        initial_event_offset: 0,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        state: encode_game_state(&fixture.state),
    };

    assert!(matches!(
        apply_player_command_dto(fixture.world, request),
        Err(ServerBoundaryError::InvalidPlayerCommand(_))
    ));
}

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;

use support::{fixture, player};
