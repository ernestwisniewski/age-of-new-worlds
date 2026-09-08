use crate::command_dispatch::{dispatch_cancel_research_selection, dispatch_select_technology};
use crate::{CancelResearchSelectionRequest, CommandResult, RuntimeError, SelectTechnologyRequest};

use super::LocalRuntime;

impl LocalRuntime {
    /// Dismisses the authenticated actor's pending research selection.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn cancel_research_selection(
        &mut self,
        command: CancelResearchSelectionRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session_mut()?;
            dispatch_cancel_research_selection(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Selects one currently available research target.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn select_technology(
        &mut self,
        command: SelectTechnologyRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session_mut()?;
            dispatch_select_technology(session, command)
        };
        self.complete_dispatch(result)
    }
}
