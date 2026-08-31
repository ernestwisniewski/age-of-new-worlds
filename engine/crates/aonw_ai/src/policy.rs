use core::num::NonZeroU32;
use std::collections::BTreeMap;

use aonw_domain::{
    AiDifficulty as DomainAiDifficulty, AiPersona as DomainAiPersona, AiPlayer,
    AiStrategyId as DomainAiStrategyId, StateRevision,
};
use aonw_engine::{CommandRejectionCode, StateDigest};
use aonw_local_runtime::{
    AiTurnDriver, AiTurnExecution, CommandResult, LocalRuntime, RuntimeError, SessionStamp,
};

use crate::{
    AiProfile, MctsSearchStats, PlanFingerprint, PlannedCommand, PlannedCommandFamily,
    PlanningBudget, SearchFingerprint, StrategicAssessment, policy_actions,
    profile::AiTacticalStrategy,
};

/// One deterministic policy command and the authoritative identity it read.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicPlan {
    stamp: SessionStamp,
    profile: AiProfile,
    assessment: StrategicAssessment,
    tactical_search: Option<TacticalSearchEvidence>,
    command: PlannedCommand,
    fingerprint: PlanFingerprint,
}

impl StrategicPlan {
    fn new(
        stamp: SessionStamp,
        recipient: &aonw_domain::PlayerId,
        profile: AiProfile,
        assessment: StrategicAssessment,
        tactical_search: Option<TacticalSearchEvidence>,
        command: PlannedCommand,
    ) -> Self {
        let fingerprint = PlanFingerprint::for_command(stamp, recipient, &command);
        Self {
            stamp,
            profile,
            assessment,
            tactical_search,
            command,
            fingerprint,
        }
    }

    /// Returns the canonical state digest read by the planner.
    #[must_use]
    pub const fn state_digest(&self) -> StateDigest {
        self.stamp.state_digest
    }

    /// Returns full state and content identity read by the planner.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }

    /// Returns the explicit policy profile used for this decision.
    #[must_use]
    pub const fn profile(&self) -> AiProfile {
        self.profile
    }

    /// Returns the revision-bound hierarchical assessment used by the policy.
    #[must_use]
    pub const fn assessment(&self) -> &StrategicAssessment {
        &self.assessment
    }

    /// Returns bounded search evidence when this command used tactical MCTS.
    #[must_use]
    pub const fn tactical_search(&self) -> Option<&TacticalSearchEvidence> {
        self.tactical_search.as_ref()
    }

    /// Returns the selected standard runtime command.
    #[must_use]
    pub const fn command(&self) -> &PlannedCommand {
        &self.command
    }

    /// Returns the stable state/command fingerprint.
    #[must_use]
    pub const fn fingerprint(&self) -> PlanFingerprint {
        self.fingerprint
    }

    /// Executes through the same public runtime method as a client command.
    ///
    /// # Errors
    ///
    /// Returns the normal runtime error from the authoritative boundary.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        self.command.execute(runtime)
    }
}

/// Result of planning the next decision for the current actor.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum StrategicPlanningOutcome {
    /// One deterministic public command was selected.
    Planned(Box<StrategicPlan>),
    /// The actor already submitted or finished its current turn.
    AwaitingTurn {
        /// Current canonical revision.
        revision: StateRevision,
    },
    /// The match already has a terminal outcome.
    MatchFinished {
        /// Current canonical revision.
        revision: StateRevision,
    },
}

/// Deterministic production policy over recipient-safe views and public queries.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct StrategicPlanner;

impl StrategicPlanner {
    /// Plans the next obligatory, strategic, tactical, or lifecycle command.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when the session or an authoritative query
    /// cannot be evaluated.
    pub fn plan(
        self,
        runtime: &mut LocalRuntime,
    ) -> Result<StrategicPlanningOutcome, RuntimeError> {
        self.plan_with_profile(runtime, AiProfile::default())
    }

    /// Plans one decision with explicit difficulty and persona inputs.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when the session or an authoritative query
    /// cannot be evaluated.
    pub fn plan_with_profile(
        self,
        runtime: &mut LocalRuntime,
        profile: AiProfile,
    ) -> Result<StrategicPlanningOutcome, RuntimeError> {
        let snapshot = runtime.snapshot()?;
        let revision = snapshot.stamp().revision;
        if snapshot.outcome().is_terminal() {
            return Ok(StrategicPlanningOutcome::MatchFinished { revision });
        }
        if snapshot.turn_lifecycle().own_submitted()
            || matches!(
                snapshot.turn_lifecycle().own_state(),
                Some(aonw_domain::PlayerTurnState::Finished)
            )
        {
            return Ok(StrategicPlanningOutcome::AwaitingTurn { revision });
        }
        let stamp = *snapshot.stamp();
        let recipient = snapshot.recipient_player_id().clone();
        let assessment = StrategicAssessment::from_snapshot(&snapshot, profile);
        let decision =
            policy_actions::next_policy_command(runtime, &snapshot, &assessment, profile)?;
        Ok(StrategicPlanningOutcome::Planned(Box::new(
            StrategicPlan::new(
                stamp,
                &recipient,
                profile,
                assessment,
                decision.tactical_search,
                decision.command,
            ),
        )))
    }

    /// Executes a bounded complete actor turn through repeated public dispatches.
    ///
    /// # Errors
    ///
    /// Returns on runtime failure, any supposedly legal policy rejection, or
    /// exhaustion of the explicit deterministic command budget.
    pub fn play_turn(
        self,
        runtime: &mut LocalRuntime,
        command_budget: NonZeroU32,
    ) -> Result<StrategicTurnReport, StrategicPlannerError> {
        self.play_turn_with_profile(runtime, command_budget, AiProfile::default())
    }

    /// Executes one bounded actor turn with an explicit production AI profile.
    ///
    /// # Errors
    ///
    /// Returns on runtime failure, policy rejection, or command-budget exhaustion.
    pub fn play_turn_with_profile(
        self,
        runtime: &mut LocalRuntime,
        command_budget: NonZeroU32,
        profile: AiProfile,
    ) -> Result<StrategicTurnReport, StrategicPlannerError> {
        let initial_stamp = *runtime.snapshot()?.stamp();
        let mut family_usage = BTreeMap::new();
        for executed_commands in 0..command_budget.get() {
            match self.plan_with_profile(runtime, profile)? {
                StrategicPlanningOutcome::Planned(plan) => {
                    let family = plan.command().family();
                    let result = plan.execute(runtime)?;
                    ensure_accepted(family, result.rejection)?;
                    *family_usage.entry(family).or_insert(0) += 1;
                    if family == PlannedCommandFamily::Turn {
                        return Ok(StrategicTurnReport {
                            initial_stamp,
                            final_stamp: result.stamp,
                            executed_commands: executed_commands + 1,
                            family_usage,
                            completed_turn: true,
                        });
                    }
                }
                StrategicPlanningOutcome::AwaitingTurn { .. }
                | StrategicPlanningOutcome::MatchFinished { .. } => {
                    let final_stamp = *runtime.snapshot()?.stamp();
                    return Ok(StrategicTurnReport {
                        initial_stamp,
                        final_stamp,
                        executed_commands,
                        family_usage,
                        completed_turn: false,
                    });
                }
            }
        }
        Err(StrategicPlannerError::CommandBudgetExhausted {
            maximum: command_budget,
        })
    }
}

impl AiTurnDriver for StrategicPlanner {
    fn play_turn(
        &mut self,
        runtime: &mut LocalRuntime,
        configuration: AiPlayer,
        command_budget: NonZeroU32,
    ) -> Result<AiTurnExecution, Box<str>> {
        let profile = AiProfile::new(
            match configuration.difficulty() {
                DomainAiDifficulty::Easy => crate::AiDifficulty::Easy,
                DomainAiDifficulty::Normal => crate::AiDifficulty::Normal,
                DomainAiDifficulty::Hard => crate::AiDifficulty::Hard,
                DomainAiDifficulty::VeryHard => crate::AiDifficulty::VeryHard,
            },
            match configuration.persona() {
                DomainAiPersona::Balanced => crate::AiPersona::Balanced,
                DomainAiPersona::Aggressive => crate::AiPersona::Aggressive,
                DomainAiPersona::Expansive => crate::AiPersona::Expansive,
                DomainAiPersona::Economic => crate::AiPersona::Economic,
                DomainAiPersona::Scientific => crate::AiPersona::Scientific,
            },
        )
        .with_runtime_configuration(
            match configuration.strategy_id() {
                DomainAiStrategyId::Random => AiTacticalStrategy::Random,
                DomainAiStrategyId::Mcts => AiTacticalStrategy::Mcts,
                DomainAiStrategyId::Basic
                | DomainAiStrategyId::Scripted
                | DomainAiStrategyId::Utility => AiTacticalStrategy::Direct,
            },
            configuration.seed(),
        );
        match self.play_turn_with_profile(runtime, command_budget, profile) {
            Ok(report) => Ok(AiTurnExecution {
                stamp: *report.final_stamp(),
                executed_commands: report.executed_commands(),
                completed_turn: report.completed_turn(),
            }),
            Err(StrategicPlannerError::CommandBudgetExhausted { .. }) => {
                let stamp = *runtime
                    .snapshot()
                    .map_err(|error| error.to_string().into_boxed_str())?
                    .stamp();
                Ok(AiTurnExecution {
                    stamp,
                    executed_commands: command_budget.get(),
                    completed_turn: false,
                })
            }
            Err(error) => {
                runtime.poison();
                Err(error.to_string().into_boxed_str())
            }
        }
    }
}

fn ensure_accepted(
    family: PlannedCommandFamily,
    rejection: Option<CommandRejectionCode>,
) -> Result<(), StrategicPlannerError> {
    rejection.map_or(Ok(()), |rejection| {
        Err(StrategicPlannerError::CommandRejected { family, rejection })
    })
}

/// Audit evidence for selective tactical search inside the strategic policy.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct TacticalSearchEvidence {
    fingerprint: SearchFingerprint,
    budget: PlanningBudget,
    stats: MctsSearchStats,
}

impl TacticalSearchEvidence {
    pub(crate) const fn new(
        fingerprint: SearchFingerprint,
        budget: PlanningBudget,
        stats: MctsSearchStats,
    ) -> Self {
        Self {
            fingerprint,
            budget,
            stats,
        }
    }
    /// Returns the stable identity of state, seed, work, trace, and result.
    #[must_use]
    pub const fn fingerprint(self) -> SearchFingerprint {
        self.fingerprint
    }
    /// Returns the exact deterministic search limits.
    #[must_use]
    pub const fn budget(self) -> PlanningBudget {
        self.budget
    }
    /// Returns exact bounded work counters.
    #[must_use]
    pub const fn stats(self) -> MctsSearchStats {
        self.stats
    }
}

/// Deterministic evidence from one policy-driven actor turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicTurnReport {
    initial_stamp: SessionStamp,
    final_stamp: SessionStamp,
    executed_commands: u32,
    family_usage: BTreeMap<PlannedCommandFamily, u32>,
    completed_turn: bool,
}

impl StrategicTurnReport {
    /// Returns state/content identity before the first command.
    #[must_use]
    pub const fn initial_stamp(&self) -> &SessionStamp {
        &self.initial_stamp
    }
    /// Returns state/content identity after the last command.
    #[must_use]
    pub const fn final_stamp(&self) -> &SessionStamp {
        &self.final_stamp
    }
    /// Returns the exact accepted public command count.
    #[must_use]
    pub const fn executed_commands(&self) -> u32 {
        self.executed_commands
    }
    /// Returns accepted command counts by stable capability family.
    #[must_use]
    pub const fn family_usage(&self) -> &BTreeMap<PlannedCommandFamily, u32> {
        &self.family_usage
    }
    /// Returns whether this invocation dispatched the lifecycle command.
    #[must_use]
    pub const fn completed_turn(&self) -> bool {
        self.completed_turn
    }
}

/// Failure of bounded autonomous turn execution.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum StrategicPlannerError {
    /// Public session/query/engine boundary failure.
    Runtime(RuntimeError),
    /// A command generated from authoritative options was rejected.
    CommandRejected {
        /// Coarse command family.
        family: PlannedCommandFamily,
        /// Stable authoritative rejection.
        rejection: CommandRejectionCode,
    },
    /// The explicit deterministic command budget was exhausted.
    CommandBudgetExhausted {
        /// Maximum commands permitted for the invocation.
        maximum: NonZeroU32,
    },
}

impl From<RuntimeError> for StrategicPlannerError {
    fn from(value: RuntimeError) -> Self {
        Self::Runtime(value)
    }
}

impl core::fmt::Display for StrategicPlannerError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Runtime(error) => error.fmt(formatter),
            Self::CommandRejected { family, rejection } => {
                write!(
                    formatter,
                    "planned {family:?} command was rejected: {rejection}"
                )
            }
            Self::CommandBudgetExhausted { maximum } => {
                write!(formatter, "strategic command budget exhausted at {maximum}")
            }
        }
    }
}

impl std::error::Error for StrategicPlannerError {}

#[cfg(test)]
mod tests {
    use aonw_engine::CommandRejectionCode;

    use super::{PlannedCommandFamily, StrategicPlannerError, ensure_accepted};

    #[test]
    fn accepted_and_rejected_policy_dispatches_are_typed() {
        assert_eq!(ensure_accepted(PlannedCommandFamily::Turn, None), Ok(()));
        assert!(matches!(
            ensure_accepted(
                PlannedCommandFamily::Combat,
                Some(CommandRejectionCode::UnitBusy)
            ),
            Err(StrategicPlannerError::CommandRejected {
                family: PlannedCommandFamily::Combat,
                rejection: CommandRejectionCode::UnitBusy,
            })
        ));
    }
}
