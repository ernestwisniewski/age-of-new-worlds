use crate::command_dispatch::dispatch_diplomacy;
use crate::{CommandResult, DiplomacyRequest, RuntimeError};

use super::LocalRuntime;

impl LocalRuntime {
    /// Sends or responds to one current bilateral proposal.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn diplomacy(&mut self, command: &DiplomacyRequest) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session_mut()?;
            dispatch_diplomacy(session, command)
        };
        self.complete_dispatch(result)
    }
}
