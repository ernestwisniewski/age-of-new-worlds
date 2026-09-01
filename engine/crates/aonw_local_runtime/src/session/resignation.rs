use crate::turn_dispatch::{ResignParticipantRequest, dispatch_resignation};
use crate::{CommandResult, LocalRuntime, RuntimeError};

impl LocalRuntime {
    /// Records a voluntary participant resignation through the trusted lifecycle boundary.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn resign_participant(
        &mut self,
        command: &ResignParticipantRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session_mut()?;
            dispatch_resignation(session, command)
        };
        self.complete_dispatch(result)
    }
}
