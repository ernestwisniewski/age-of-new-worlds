use aonw_domain::GameState;

use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainTransition, GameEngine, SystemCommand,
    SystemContext,
};

use super::support::{reject, system_content_hashes};
use super::{apply_kick, apply_timeout_finalization};

impl GameEngine {
    /// Applies one host-owned lifecycle command through a boundary that has no player identity.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical content or an engine-produced state is invalid.
    pub fn apply_system_owned(
        state: GameState,
        context: SystemContext<'_>,
        command: SystemCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        let hashes = system_content_hashes(context)?;
        if state.outcome().is_terminal() {
            return Ok(reject(
                state,
                CommandRejectionCode::MatchFinished,
                hashes.0,
                hashes.1,
            ));
        }
        match command {
            SystemCommand::FinalizeTimedOutTurn(command) => {
                apply_timeout_finalization(state, context, command, hashes)
            }
            SystemCommand::KickParticipant(command) => {
                apply_kick(state, command, hashes.0, hashes.1)
            }
        }
    }
}
