use crate::command_dispatch::dispatch_artifact;
use crate::{ArtifactCommandRequest, CommandResult, RuntimeError};

use super::LocalRuntime;

impl LocalRuntime {
    /// Executes one current artifact command.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn artifact(
        &mut self,
        command: &ArtifactCommandRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session_mut()?;
            dispatch_artifact(session, command)
        };
        self.complete_dispatch(result)
    }
}
