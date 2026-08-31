//! Deterministic planners using only recipient-safe views and public runtime commands.
//!
//! This crate never mutates canonical state directly and does not contain a
//! simulation reducer. Every plan is revision-bound and execution delegates to
//! the same [`aonw_local_runtime::LocalRuntime`] boundary used by clients.

#![forbid(unsafe_code)]

mod actions;
mod baseline;
mod budget;
mod command;
mod fingerprint;
mod mcts;
mod mcts_search;
mod policy;
mod policy_actions;
mod policy_scoring;
mod profile;
mod random_planner;
mod rng;
mod strategy;

pub use baseline::{BaselinePlan, BaselinePlanner, BaselinePlanningOutcome};
pub use budget::{PlanningBudget, PlanningBudgetError};
pub use command::{PlannedCommand, PlannedCommandFamily};
pub use fingerprint::{PlanFingerprint, SearchFingerprint};
pub use mcts::{MctsPlan, MctsPlanner, MctsPlanningOutcome};
pub use mcts_search::MctsSearchStats;
pub use policy::{
    StrategicPlan, StrategicPlanner, StrategicPlannerError, StrategicPlanningOutcome,
    StrategicTurnReport, TacticalSearchEvidence,
};
pub use profile::{AiDifficulty, AiPersona, AiProfile, UtilityWeights};
pub use random_planner::{RandomPlan, RandomPlanner, RandomPlanningOutcome};
pub use rng::{AiRng, AiRngDraw, AiRngTrace};
pub use strategy::{
    EmpireAssessment, GoalPriority, StrategicAssessment, StrategicGoal, StrategicMode, UtilityScore,
};
