use aonw_contract_mapping::decode_technology;
use aonw_contracts::ReplayCommandDto;
use aonw_engine::{
    DomainTransition, EngineContext, GameEngine, PlayerCommand, SelectTechnologyCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    let ReplayCommandDto::SelectTechnology {
        expected_revision,
        technology_id,
    } = command
    else {
        unreachable!("research fixture received another command family")
    };
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(
            *expected_revision,
            decode_technology(*technology_id),
        )),
    )
    .map_err(display_error)
}
