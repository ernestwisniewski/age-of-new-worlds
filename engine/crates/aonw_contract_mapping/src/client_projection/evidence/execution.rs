use aonw_contracts::client::ClientEvidenceDto;
use aonw_engine::{ExecutionEvidence, LogisticsExecution, UnitMovementExecution};
use aonw_projection::RecipientDisclosure;

use super::super::worker::encode_worker_automation_option;
use super::logistics::{logistics_evidence, movement_execution};
use super::{combat_execution, coordinate, movement};

pub(super) fn encode_evidence(
    value: &ExecutionEvidence,
    disclosure: Option<&RecipientDisclosure>,
) -> Option<ClientEvidenceDto> {
    let allows_combat = |value: &_| disclosure.is_none_or(|policy| policy.allows_combat(value));
    let allows_unit = |value: &_| disclosure.is_none_or(|policy| policy.allows_unit(value));
    let owns_unit = |value: &_| disclosure.is_none_or(|policy| policy.owns_unit(value));
    let allows_city = |value: &_| disclosure.is_none_or(|policy| policy.allows_city(value));
    let allows_movement = |value: &_| disclosure.is_none_or(|policy| policy.allows_movement(value));
    match value {
        ExecutionEvidence::Combat(value) => {
            allows_combat(value).then(|| ClientEvidenceDto::Combat {
                execution: combat_execution(value),
            })
        }
        ExecutionEvidence::UnitMovement(value) => {
            allows_movement(value).then(|| public_movement(value))
        }
        ExecutionEvidence::Logistics(value) => encode_logistics(value, disclosure),
        ExecutionEvidence::TurnKernel(value) => Some(ClientEvidenceDto::TurnKernel {
            processors: value
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            founded_city_ids: value
                .founded_city_ids()
                .iter()
                .filter(|city| allows_city(city))
                .map(|city| city.as_str().to_owned())
                .collect(),
            combat_executions: value
                .combat_executions()
                .iter()
                .filter(|combat| allows_combat(combat))
                .map(combat_execution)
                .collect(),
            reset_unit_ids: value
                .reset_unit_ids()
                .iter()
                .filter(|unit| allows_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            movement_executions: value
                .movement_executions()
                .iter()
                .filter(|movement| allows_movement(movement))
                .map(movement_execution)
                .collect(),
            invalidated_order_unit_ids: value
                .invalidated_order_unit_ids()
                .iter()
                .filter(|unit| owns_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            finished_auto_explore_unit_ids: value
                .finished_auto_explore_unit_ids()
                .iter()
                .filter(|unit| owns_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        }),
        ExecutionEvidence::WorkerAutomation(value) => {
            if owns_unit(value.unit_id()) {
                Some(ClientEvidenceDto::WorkerAutomation {
                    unit_id: value.unit_id().as_str().to_owned(),
                    option: encode_worker_automation_option(value.option()),
                    movement: value.movement().map(movement_execution),
                })
            } else {
                value
                    .movement()
                    .filter(|value| allows_movement(value))
                    .map(public_movement)
            }
        }
    }
}

fn encode_logistics(
    value: &LogisticsExecution,
    disclosure: Option<&RecipientDisclosure>,
) -> Option<ClientEvidenceDto> {
    if disclosure.is_none_or(|policy| policy.allows_logistics(value)) {
        return Some(ClientEvidenceDto::Logistics {
            execution: logistics_evidence(value),
        });
    }
    match value {
        LogisticsExecution::AutoExplore { movement, .. } => movement
            .as_ref()
            .filter(|value| disclosure.is_none_or(|policy| policy.allows_movement(value)))
            .map(public_movement),
        _ => None,
    }
}

fn public_movement(value: &UnitMovementExecution) -> ClientEvidenceDto {
    ClientEvidenceDto::UnitMovement {
        unit_id: value.unit_id().as_str().to_owned(),
        from: coordinate(value.from()),
        steps: value.steps().iter().map(movement::step).collect(),
    }
}
