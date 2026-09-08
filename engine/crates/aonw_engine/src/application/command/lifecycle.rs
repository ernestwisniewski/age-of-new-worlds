use aonw_domain::{GameState, PlayerId, PlayerTurnState};

use crate::CommandRejectionCode;

pub(crate) fn player_action_lifecycle_rejection(
    state: &GameState,
    actor_player_id: &PlayerId,
    boundary_can_act: bool,
) -> Option<CommandRejectionCode> {
    if !boundary_can_act {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    let lifecycle = state.match_lifecycle();
    let identity = lifecycle.identity();
    if identity.participants().is_empty() {
        // Bare engine states predate match startup and remain useful for embedders and fixtures.
        return None;
    }
    let turn = lifecycle.turn();
    if !identity.contains(actor_player_id)
        || turn.is_removed(actor_player_id)
        || turn.submitted_player_ids().contains(actor_player_id)
        || turn.turn_states_by_player_id().get(actor_player_id) != Some(&PlayerTurnState::Active)
    {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    None
}
