use crate::encode_improvement;
use aonw_contracts::client::{
    WorkerAutomationActionDto, WorkerAutomationMetricsDto, WorkerAutomationOptionDto,
};
use aonw_engine::{WorkerAutomationAction, WorkerAutomationOption};

use super::coordinate;

/// Maps a worker automation option to its strict current client DTO.
#[must_use]
pub fn encode_worker_automation_option(value: WorkerAutomationOption) -> WorkerAutomationOptionDto {
    let metrics = value.metrics();
    WorkerAutomationOptionDto {
        target: coordinate(value.target()),
        action: match value.action() {
            WorkerAutomationAction::Improve(improvement) => WorkerAutomationActionDto::Improve {
                improvement: encode_improvement(improvement),
            },
            WorkerAutomationAction::Assign => WorkerAutomationActionDto::Assign,
        },
        movement_cost_units: value.movement_cost_units(),
        metrics: WorkerAutomationMetricsDto {
            tiles_examined: metrics.tiles_examined(),
            legality_evaluations: metrics.legality_evaluations(),
            routes_planned: metrics.routes_planned(),
        },
    }
}
