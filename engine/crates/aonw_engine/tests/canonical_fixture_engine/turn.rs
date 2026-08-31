use aonw_contracts::ReplayCommandDto;
use aonw_engine::{DomainTransition, EngineContext, GameEngine, PlayerCommand, TurnCommand};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    let player_command = match command {
        ReplayCommandDto::EndTurn { expected_revision } => PlayerCommand::EndTurn(
            TurnCommand::new(*expected_revision, context.actor_player_id()),
        ),
        ReplayCommandDto::SubmitTurn { expected_revision } => PlayerCommand::SubmitTurn(
            TurnCommand::new(*expected_revision, context.actor_player_id()),
        ),
        _ => unreachable!("turn fixture received another command family"),
    };
    GameEngine::apply_player_owned(state, context, player_command).map_err(display_error)
}
