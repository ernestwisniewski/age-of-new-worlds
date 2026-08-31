use aonw_domain::{PlayerId, StateRevision};
use aonw_engine::StateDigest;
use aonw_local_runtime::{CommandResult, LocalRuntime, RuntimeError, SessionStamp};

use crate::{PlanFingerprint, PlannedCommand, actions::best_move_command};

/// One deterministic command and the canonical identity it was planned from.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct BaselinePlan {
    stamp: SessionStamp,
    command: PlannedCommand,
    fingerprint: PlanFingerprint,
}

impl BaselinePlan {
    fn new(stamp: SessionStamp, recipient: &PlayerId, command: PlannedCommand) -> Self {
        let fingerprint = PlanFingerprint::for_command(stamp, recipient, &command);
        Self {
            stamp,
            command,
            fingerprint,
        }
    }

    /// Returns the canonical state digest read by the planner.
    #[must_use]
    pub const fn state_digest(&self) -> StateDigest {
        self.stamp.state_digest
    }

    /// Returns the full authoritative state/content identity read by the planner.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }

    /// Returns the standard runtime command selected by the planner.
    #[must_use]
    pub const fn command(&self) -> &PlannedCommand {
        &self.command
    }

    /// Returns the stable identity of the state/command pair.
    #[must_use]
    pub const fn fingerprint(&self) -> PlanFingerprint {
        self.fingerprint
    }

    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        self.command.execute(runtime)
    }
}

/// Result of asking the baseline planner for one command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum BaselinePlanningOutcome {
    /// One executable command was selected.
    Planned(BaselinePlan),
    /// This planner instance already produced its decision for the revision.
    AlreadyPlanned {
        /// Canonical revision already inspected by this planner instance.
        revision: StateRevision,
    },
    /// Recipient-safe state and authoritative queries exposed no legal move.
    NoLegalCommand {
        /// Canonical revision for which no legal command was found.
        revision: StateRevision,
    },
}

/// Deterministic one-command-per-revision baseline planner.
#[derive(Clone, Debug, Default)]
pub struct BaselinePlanner {
    last_planned_identity: Option<PlanningIdentity>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct PlanningIdentity {
    stamp: SessionStamp,
    recipient_player_id: PlayerId,
}

impl BaselinePlanner {
    /// Plans at most one normal runtime command for the current revision.
    ///
    /// Known foreign units and cities act as movement targets. Without a known
    /// target the planner uses canonical unit and coordinate ordering. All
    /// legal movement choices come from the authoritative `Reachable` query.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when the session is closed or a query
    /// cannot be evaluated.
    pub fn plan(
        &mut self,
        runtime: &mut LocalRuntime,
    ) -> Result<BaselinePlanningOutcome, RuntimeError> {
        let snapshot = runtime.snapshot()?;
        let revision = snapshot.stamp().revision;
        let identity = PlanningIdentity {
            stamp: *snapshot.stamp(),
            recipient_player_id: snapshot.recipient_player_id().clone(),
        };
        if self.last_planned_identity.as_ref() == Some(&identity) {
            return Ok(BaselinePlanningOutcome::AlreadyPlanned { revision });
        }

        let command = best_move_command(runtime, &snapshot)?;
        let outcome = command.map_or(
            BaselinePlanningOutcome::NoLegalCommand { revision },
            |command| {
                BaselinePlanningOutcome::Planned(BaselinePlan::new(
                    identity.stamp,
                    &identity.recipient_player_id,
                    command,
                ))
            },
        );
        self.last_planned_identity = Some(identity);
        Ok(outcome)
    }
}
