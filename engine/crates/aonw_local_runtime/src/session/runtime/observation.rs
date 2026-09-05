use std::sync::Arc;

use aonw_domain::PlayerId;
use aonw_projection::{ProjectedView, RecipientDisclosure, diff_view, unchanged_view};

use super::super::Session;
use super::{MovementSearchWorkspace, QueryCache};
use crate::{CommandResult, LocalRuntime, RuntimeError};

/// A bounded sequence projected for one fixed recipient across actor handoffs.
#[derive(Clone, Debug)]
pub(super) struct CommandObservation {
    recipient: Arc<PlayerId>,
    projection: ProjectedView,
    revision: u64,
    maximum: usize,
    commands: Vec<CommandResult>,
}

impl CommandObservation {
    fn new(session: &Session, maximum: usize) -> Self {
        Self {
            recipient: session.shared_actor(),
            projection: session.projection().clone(),
            revision: session.stamp().revision.get(),
            maximum,
            commands: Vec::new(),
        }
    }

    pub(super) fn record(
        &mut self,
        session: &Session,
        result: &CommandResult,
    ) -> Result<(), RuntimeError> {
        if self.commands.len() == self.maximum {
            return Err(RuntimeError::ObservationBudgetExceeded);
        }
        let next = if result.stamp.revision.get() == self.revision {
            self.projection.clone()
        } else {
            ProjectedView::try_for_recipient(
                session.state(),
                Arc::clone(&self.recipient),
                session.map(),
                session.ruleset(),
            )
            .map_err(RuntimeError::Query)?
        };
        let disclosure = RecipientDisclosure::observed_transition(
            self.recipient.as_ref().clone(),
            &self.projection,
            &next,
            result.evidence.as_ref(),
        );
        let patch = if result.stamp.revision.get() == self.revision {
            unchanged_view(self.revision, &self.projection)
        } else {
            diff_view(
                self.revision,
                result.stamp.revision.get(),
                &self.projection,
                &next,
            )
        };
        self.projection = next;
        self.revision = result.stamp.revision.get();
        self.commands.push(CommandResult {
            stamp: result.stamp,
            rejection: result.rejection,
            events: result.events.clone(),
            evidence: result.evidence.clone(),
            view_patch: patch,
            recipient_disclosure: disclosure,
        });
        Ok(())
    }
}

impl LocalRuntime {
    /// Creates an isolated simulation runtime without copying immutable world,
    /// projection, visibility, or replay storage.
    #[must_use]
    pub fn simulation_clone(&self) -> Self {
        let mut session = self.session.clone();
        if let Some(session) = session.as_mut() {
            session.disable_replay();
        }
        Self {
            session,
            replay_playback: None,
            poisoned: self.poisoned,
            workspace: MovementSearchWorkspace::default(),
            query_cache: QueryCache::default(),
            observation: None,
        }
    }

    pub(super) fn start_observing_recipient(
        &mut self,
        maximum: usize,
    ) -> Result<PlayerId, RuntimeError> {
        debug_assert!(self.observation.is_none());
        let session = self.session_ref()?;
        let recipient = session.actor().clone();
        self.observation = Some(CommandObservation::new(session, maximum));
        Ok(recipient)
    }

    pub(super) fn finish_observing_recipient(&mut self) -> Box<[CommandResult]> {
        self.observation.take().map_or_else(
            || Box::new([]) as Box<[_]>,
            |value| value.commands.into_boxed_slice(),
        )
    }
}
