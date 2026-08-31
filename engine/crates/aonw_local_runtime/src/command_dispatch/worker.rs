use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{FieldImprovementKind, UnitId};
use aonw_engine::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, ConfirmWorkerImprovementCommand,
    PlayerCommand, SelectWorkerImprovementCommand,
};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current revision-bound improvement selection or confirmation.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct WorkerImprovementRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Worker receiving the command.
    pub unit_id: UnitId,
    /// Explicit improvement; confirmation may use matching pending state.
    pub improvement: Option<FieldImprovementKind>,
}

/// Current revision-bound worker command without an additional payload.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct WorkerUnitRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Worker receiving the command.
    pub unit_id: UnitId,
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum RuntimeWorkerCommandKind {
    CancelJob,
    Assign,
    CancelAssignment,
    BuildRoad,
    Automate,
}

pub(crate) fn dispatch_select_worker_improvement(
    session: &mut Session,
    command: &WorkerImprovementRequest,
) -> Result<CommandResult, RuntimeError> {
    let improvement = command
        .improvement
        .expect("select worker improvement requires decoded improvement");
    dispatch_player(
        session,
        PlayerCommand::SelectWorkerImprovement(SelectWorkerImprovementCommand::new(
            command.expected_revision,
            &command.unit_id,
            improvement,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SelectWorkerImprovement {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
                improvement: aonw_contract_mapping::encode_improvement(improvement),
            },
        },
    )
}

pub(crate) fn dispatch_confirm_worker_improvement(
    session: &mut Session,
    command: &WorkerImprovementRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.improvement,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::ConfirmWorkerImprovement {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
                improvement: command
                    .improvement
                    .map(aonw_contract_mapping::encode_improvement),
            },
        },
    )
}

pub(crate) fn dispatch_worker_unit(
    session: &mut Session,
    command: &WorkerUnitRequest,
    kind: RuntimeWorkerCommandKind,
) -> Result<CommandResult, RuntimeError> {
    let expected_revision = command.expected_revision;
    let unit_id = command.unit_id.as_str().to_owned();
    let (player, replay) = match kind {
        RuntimeWorkerCommandKind::CancelJob => (
            PlayerCommand::CancelWorkerJob(CancelWorkerJobCommand::new(
                expected_revision,
                &command.unit_id,
            )),
            ReplayCommandDto::CancelWorkerJob {
                expected_revision,
                unit_id,
            },
        ),
        RuntimeWorkerCommandKind::Assign => (
            PlayerCommand::AssignWorkerToHex(AssignWorkerToHexCommand::new(
                expected_revision,
                &command.unit_id,
            )),
            ReplayCommandDto::AssignWorkerToHex {
                expected_revision,
                unit_id,
            },
        ),
        RuntimeWorkerCommandKind::CancelAssignment => (
            PlayerCommand::CancelWorkerAssignment(CancelWorkerAssignmentCommand::new(
                expected_revision,
                &command.unit_id,
            )),
            ReplayCommandDto::CancelWorkerAssignment {
                expected_revision,
                unit_id,
            },
        ),
        RuntimeWorkerCommandKind::BuildRoad => (
            PlayerCommand::BuildRoad(BuildRoadCommand::new(expected_revision, &command.unit_id)),
            ReplayCommandDto::BuildRoad {
                expected_revision,
                unit_id,
            },
        ),
        RuntimeWorkerCommandKind::Automate => (
            PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(
                expected_revision,
                &command.unit_id,
            )),
            ReplayCommandDto::AutomateWorker {
                expected_revision,
                unit_id,
            },
        ),
    };
    dispatch_player(session, player, ReplayRecordDto::Player { command: replay })
}
