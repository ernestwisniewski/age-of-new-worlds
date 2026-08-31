use aonw_contracts::client::MovementStepViewDto;

use super::coordinate;

pub(super) fn step(value: &aonw_domain::MovementStep) -> MovementStepViewDto {
    MovementStepViewDto {
        coordinate: coordinate(value.coordinate()),
        enter_cost_units: value.enter_cost().get(),
        cumulative_cost_units: value.cumulative_cost().get(),
    }
}
