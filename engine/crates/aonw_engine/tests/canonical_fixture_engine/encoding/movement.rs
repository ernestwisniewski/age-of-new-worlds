use aonw_contracts::{CoordinateDto, MovementStepDto, ReplayUnitMovementExecutionDto};
use aonw_domain::MovementStep;
use aonw_engine::UnitMovementExecution;

pub(super) fn encode_movement_execution(
    execution: &UnitMovementExecution,
) -> ReplayUnitMovementExecutionDto {
    ReplayUnitMovementExecutionDto {
        unit_id: execution.unit_id().as_str().to_owned(),
        from: CoordinateDto {
            col: execution.from().col(),
            row: execution.from().row(),
        },
        steps: execution.steps().iter().map(encode_step).collect(),
    }
}

pub(super) fn encode_step(step: &MovementStep) -> MovementStepDto {
    MovementStepDto {
        col: step.coordinate().col(),
        row: step.coordinate().row(),
        enter_cost_units: step.enter_cost().get(),
        cumulative_cost_units: step.cumulative_cost().get(),
    }
}
