use aonw_domain::StateRevision;
use aonw_engine::StateDigest;
use aonw_local_runtime::{CommandResult, LocalRuntime, RuntimeError, SessionStamp};

use crate::{
    AiRng, AiRngTrace, PlanFingerprint, PlannedCommand, PlanningBudget, SearchFingerprint,
    actions::bounded_tactical_move_candidates,
    fingerprint::SearchFingerprintInput,
    mcts_search::{MctsSearchStats, owned_movement, search},
};

/// One command selected by bounded deterministic MCTS.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MctsPlan {
    stamp: SessionStamp,
    command: aonw_local_runtime::MoveUnitRequest,
    fingerprint: PlanFingerprint,
    search_fingerprint: SearchFingerprint,
    rng_trace: AiRngTrace,
    budget: PlanningBudget,
    stats: MctsSearchStats,
}

impl MctsPlan {
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

    /// Returns the identity of budget, seed, draws, work, state, and result.
    #[must_use]
    pub const fn search_fingerprint(&self) -> SearchFingerprint {
        self.search_fingerprint
    }

    /// Returns complete ordered RNG evidence for this search.
    #[must_use]
    pub const fn rng_trace(&self) -> &AiRngTrace {
        &self.rng_trace
    }

    /// Returns the exact deterministic limits used by the search.
    #[must_use]
    pub const fn budget(&self) -> PlanningBudget {
        self.budget
    }

    /// Returns bounded work counters from the search.
    #[must_use]
    pub const fn stats(&self) -> MctsSearchStats {
        self.stats
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

/// Result of deterministic MCTS planning for the current state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MctsPlanningOutcome {
    /// One executable command was selected.
    Planned(Box<MctsPlan>),
    /// Recipient-safe state and authoritative queries exposed no legal move.
    NoLegalCommand {
        /// Canonical revision for which no legal command was found.
        revision: StateRevision,
    },
}

/// Monte Carlo tree search over cloned public local-runtime transitions.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MctsPlanner {
    base_seed: u32,
    budget: PlanningBudget,
}

impl MctsPlanner {
    /// Creates a search with explicit deterministic seed and work limits.
    #[must_use]
    pub const fn new(base_seed: u32, budget: PlanningBudget) -> Self {
        Self { base_seed, budget }
    }

    /// Searches cloned runtime states without mutating the authoritative state.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when snapshots, queries, or simulated
    /// command transitions cannot be evaluated.
    pub fn plan(self, runtime: &mut LocalRuntime) -> Result<MctsPlanningOutcome, RuntimeError> {
        let root_snapshot = runtime.snapshot()?;
        let stamp = *root_snapshot.stamp();
        let revision = stamp.revision;
        let recipient = root_snapshot.recipient_player_id().clone();
        let root_candidates = bounded_tactical_move_candidates(
            runtime,
            &root_snapshot,
            usize::try_from(self.budget.max_nodes() - 1).unwrap_or(usize::MAX),
        )?;
        let Some(immediate_best) = root_candidates.first() else {
            return Ok(MctsPlanningOutcome::NoLegalCommand { revision });
        };
        let quality_floor = root_snapshot
            .units()
            .iter()
            .position(|unit| unit.id() == &immediate_best.request().unit_id)
            .map(|unit_index| QualityFloor {
                unit_index,
                target: immediate_best.request().target,
                distance_to_known_opponent: immediate_best.distance_to_known_opponent(),
            });
        let root_actions = root_candidates
            .into_iter()
            .map(crate::actions::MoveCandidate::into_request)
            .collect::<Vec<_>>();

        let initial_rng = AiRng::from_turn(root_snapshot.turn(), &recipient, self.base_seed);
        let mut rng = initial_rng;
        let mut draws = Vec::new();
        let initial_movement = owned_movement(&root_snapshot, &recipient);
        let mut result = search(
            runtime,
            &recipient,
            initial_movement,
            self.budget,
            root_actions,
            &mut rng,
            &mut draws,
        )?;
        if let Some(floor) = quality_floor
            && known_opponent_distance(&root_snapshot, &recipient, result.command.target)
                .unwrap_or(u64::MAX)
                > floor.distance_to_known_opponent.unwrap_or(u64::MAX)
            && let Some(unit) = root_snapshot.units().get(floor.unit_index)
        {
            result.command = aonw_local_runtime::MoveUnitRequest {
                expected_revision: revision.get(),
                unit_id: unit.id().clone(),
                target: floor.target,
            };
            result.stats.record_quality_guard();
        }

        let rng_trace = AiRngTrace::new(initial_rng.state(), rng.state(), draws);
        let fingerprint = PlanFingerprint::for_move(stamp, &recipient, &result.command);
        let counters = result.stats.fingerprint_counters();
        let search_fingerprint = SearchFingerprint::for_search(SearchFingerprintInput {
            stamp,
            recipient: &recipient,
            strategy: "mcts",
            base_seed: self.base_seed,
            budget: Some(self.budget),
            trace: &rng_trace,
            counters: &counters,
            plan: fingerprint,
        });
        Ok(MctsPlanningOutcome::Planned(Box::new(MctsPlan {
            stamp,
            command: result.command,
            fingerprint,
            search_fingerprint,
            rng_trace,
            budget: self.budget,
            stats: result.stats,
        })))
    }
}

#[derive(Clone, Copy)]
struct QualityFloor {
    unit_index: usize,
    target: aonw_domain::HexCoord,
    distance_to_known_opponent: Option<u64>,
}

fn known_opponent_distance(
    snapshot: &aonw_local_runtime::PlayerViewSnapshot,
    recipient: &aonw_domain::PlayerId,
    target: aonw_domain::HexCoord,
) -> Option<u64> {
    snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != recipient)
        .map(|unit| target.distance_to(aonw_domain::HexCoord::new(unit.col(), unit.row())))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != recipient)
                .map(|city| target.distance_to(city.center())),
        )
        .min()
}
