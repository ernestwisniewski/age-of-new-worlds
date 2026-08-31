mod automation;
mod model;
mod planner_support;
mod rules;
mod score;
mod turn;

pub use model::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, ConfirmWorkerImprovementCommand,
    SelectWorkerImprovementCommand, WorkerAutomationAction, WorkerAutomationExecution,
    WorkerAutomationMetrics, WorkerAutomationOption, WorkerImprovementOption, WorkerOptions,
    WorkerOptionsQuery,
};

pub(crate) use automation::apply_automation;
pub(crate) use rules::{
    WorkerMutation, WorkerRuleError, WorkerUpdate, apply_assign, apply_build_road,
    apply_cancel_assignment, apply_cancel_job, apply_confirm, apply_select, query_options,
};
pub(crate) use turn::{WorkerTurnUpdate, advance_workers};
