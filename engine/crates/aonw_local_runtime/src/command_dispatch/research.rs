use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::TechnologyId;
use aonw_engine::{CancelResearchSelectionCommand, PlayerCommand, SelectTechnologyCommand};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current revision-bound research selection.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct SelectTechnologyRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Current engine-owned technology choice.
    pub technology: TechnologyId,
}

pub(crate) fn dispatch_select_technology(
    session: &mut Session,
    command: SelectTechnologyRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(
            command.expected_revision,
            command.technology,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SelectTechnology {
                expected_revision: command.expected_revision,
                technology_id: aonw_contract_mapping::encode_technology(command.technology),
            },
        },
    )
}

/// Revision-bound dismissal of a pending research choice.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct CancelResearchSelectionRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

pub(crate) fn dispatch_cancel_research_selection(
    session: &mut Session,
    command: CancelResearchSelectionRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::CancelResearchSelection(CancelResearchSelectionCommand::new(
            command.expected_revision,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::CancelResearchSelection {
                expected_revision: command.expected_revision,
            },
        },
    )
}
