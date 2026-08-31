use aonw_domain::{GameMode, PlayerId};

use crate::ActorHandoffError;

use super::LocalRuntime;

impl LocalRuntime {
    /// Changes the authenticated actor of an explicitly local hot-seat match.
    ///
    /// State, digest, revision, event offset, and replay history are preserved;
    /// recipient visibility, projection, and query cache are rebuilt.
    ///
    /// # Errors
    ///
    /// Returns an error for a closed session, non-hot-seat match, or unknown actor.
    pub fn handoff_hot_seat_actor(
        &mut self,
        actor: PlayerId,
    ) -> Result<super::SessionStamp, ActorHandoffError> {
        if self.poisoned {
            return Err(ActorHandoffError::SessionPoisoned);
        }
        let session = self
            .session
            .as_mut()
            .ok_or(ActorHandoffError::SessionNotOpen)?;
        let identity = session.state().match_lifecycle().identity();
        if identity.game_mode() != GameMode::HotSeat {
            return Err(ActorHandoffError::NotHotSeat);
        }
        if !identity.contains(&actor) {
            return Err(ActorHandoffError::UnknownPlayer(actor));
        }
        session
            .handoff_actor(actor)
            .map_err(ActorHandoffError::Projection)?;
        self.query_cache.clear();
        Ok(session.stamp())
    }
}
