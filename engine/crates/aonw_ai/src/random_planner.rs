use core::num::NonZeroUsize;

use aonw_domain::StateRevision;
use aonw_engine::StateDigest;
use aonw_local_runtime::{CommandResult, LocalRuntime, RuntimeError, SessionStamp};

use crate::{
    AiRng, AiRngTrace, PlanFingerprint, PlannedCommand, SearchFingerprint,
    actions::legal_move_candidates, fingerprint::SearchFingerprintInput, rng::draw_index,
};

/// One seeded random command selected from authoritative legal actions.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RandomPlan {
    stamp: SessionStamp,
    command: aonw_local_runtime::MoveUnitRequest,
    fingerprint: PlanFingerprint,
    search_fingerprint: SearchFingerprint,
    rng_trace: AiRngTrace,
}

impl RandomPlan {
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
    pub fn command(&self) -> PlannedCommand {
        PlannedCommand::MoveUnit(self.command.clone())
    }

    /// Returns the stable state/command identity shared by all planners.
    #[must_use]
    pub const fn fingerprint(&self) -> PlanFingerprint {
        self.fingerprint
    }

    /// Returns the identity of seed, ordered draws, work, state, and result.
    #[must_use]
    pub const fn search_fingerprint(&self) -> SearchFingerprint {
        self.search_fingerprint
    }

    /// Returns complete ordered RNG evidence for this decision.
    #[must_use]
    pub const fn rng_trace(&self) -> &AiRngTrace {
        &self.rng_trace
    }

    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        runtime.dispatch(&self.command)
    }
}

/// Result of seeded random planning for the current state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RandomPlanningOutcome {
    /// One executable command was selected.
    Planned(Box<RandomPlan>),
    /// Recipient-safe state and authoritative queries exposed no legal move.
    NoLegalCommand {
        /// Canonical revision for which no legal command was found.
        revision: StateRevision,
    },
}

/// Seeded planner sampling uniformly from canonical public legal actions.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RandomPlanner {
    base_seed: u32,
}

impl RandomPlanner {
    /// Creates a planner with an explicit reproducible base seed.
    #[must_use]
    pub const fn new(base_seed: u32) -> Self {
        Self { base_seed }
    }

    /// Selects one standard command without mutating canonical game state.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when the session is closed or a query
    /// cannot be evaluated.
    pub fn plan(self, runtime: &mut LocalRuntime) -> Result<RandomPlanningOutcome, RuntimeError> {
        let snapshot = runtime.snapshot()?;
        let stamp = *snapshot.stamp();
        let revision = stamp.revision;
        let recipient = snapshot.recipient_player_id();
        let candidates = legal_move_candidates(runtime, &snapshot)?;
        let Some(maximum) = NonZeroUsize::new(candidates.len()) else {
            return Ok(RandomPlanningOutcome::NoLegalCommand { revision });
        };

        let initial_rng = AiRng::from_turn(snapshot.turn(), recipient, self.base_seed);
        let mut rng = initial_rng;
        let mut draws = Vec::with_capacity(1);
        let selected = draw_index(&mut rng, maximum, &mut draws);
        let command = candidates[selected].request().clone();
        let rng_trace = AiRngTrace::new(initial_rng.state(), rng.state(), draws);
        let fingerprint = PlanFingerprint::for_move(stamp, recipient, &command);
        let search_fingerprint = SearchFingerprint::for_search(SearchFingerprintInput {
            stamp,
            recipient,
            strategy: "random",
            base_seed: self.base_seed,
            budget: None,
            trace: &rng_trace,
            counters: &[1],
            plan: fingerprint,
        });
        Ok(RandomPlanningOutcome::Planned(Box::new(RandomPlan {
            stamp,
            command,
            fingerprint,
            search_fingerprint,
            rng_trace,
        })))
    }
}
