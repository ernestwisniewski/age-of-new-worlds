//! Transaction and privacy contract for generic remote player commands.

use aonw_domain::{PlayerTurnState, StateRevision, UnitId, UnitPosture};
use aonw_engine::{PlayerCommand, TurnCommand, UnitActionCommand};
use aonw_server_runtime::{PlayerCommandRequest, apply_player_command};

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

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;

use support::{fixture, player};
