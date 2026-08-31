use aonw_contract_mapping::decode_improvement;
use aonw_contracts::ReplayCommandDto;
use aonw_domain::UnitId;
use aonw_engine::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, ConfirmWorkerImprovementCommand,
    EngineContext, GameEngine, PlayerCommand, SelectWorkerImprovementCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::SelectWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => {
            let unit_id = UnitId::new(unit_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SelectWorkerImprovement(SelectWorkerImprovementCommand::new(
                    *expected_revision,
                    &unit_id,
                    decode_improvement(*improvement),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::ConfirmWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => {
            let unit_id = UnitId::new(unit_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand::new(
                    *expected_revision,
                    &unit_id,
                    improvement.map(decode_improvement),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::CancelWorkerJob {
            expected_revision,
            unit_id,
        } => apply_unit(
            state,
            context,
            *expected_revision,
            unit_id,
            |revision, unit| {
                PlayerCommand::CancelWorkerJob(CancelWorkerJobCommand::new(revision, unit))
            },
        ),
        ReplayCommandDto::AssignWorkerToHex {
            expected_revision,
            unit_id,
        } => apply_unit(
            state,
            context,
            *expected_revision,
            unit_id,
            |revision, unit| {
                PlayerCommand::AssignWorkerToHex(AssignWorkerToHexCommand::new(revision, unit))
            },
        ),
        ReplayCommandDto::CancelWorkerAssignment {
            expected_revision,
            unit_id,
        } => apply_unit(
            state,
            context,
            *expected_revision,
            unit_id,
            |revision, unit| {
                PlayerCommand::CancelWorkerAssignment(CancelWorkerAssignmentCommand::new(
                    revision, unit,
                ))
            },
        ),
        ReplayCommandDto::BuildRoad {
            expected_revision,
            unit_id,
        } => apply_unit(
            state,
            context,
            *expected_revision,
            unit_id,
            |revision, unit| PlayerCommand::BuildRoad(BuildRoadCommand::new(revision, unit)),
        ),
        ReplayCommandDto::AutomateWorker {
            expected_revision,
            unit_id,
        } => apply_unit(
            state,
            context,
            *expected_revision,
            unit_id,
            |revision, unit| {
                PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(revision, unit))
            },
        ),
        _ => unreachable!("worker dispatcher received another command family"),
    }
}

fn apply_unit(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    command: impl for<'command> FnOnce(u64, &'command UnitId) -> PlayerCommand<'command>,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    GameEngine::apply_player_owned(state, context, command(expected_revision, &unit_id))
        .map_err(display_error)
}
