use aonw_contracts::FieldImprovementKindDto;
use aonw_contracts::client::{
    ClientCommandDto, ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto,
    ClientResponseBodyDto, WorkerAutomationActionDto, WorkerAutomationMetricsDto,
    WorkerAutomationOptionDto, WorkerImprovementOptionDto,
};

use super::{coordinate, stamp};

pub(super) fn requests() -> [ClientRequestBodyDto; 8] {
    [
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::WorkerOptions {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SelectWorkerImprovement {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
                improvement: FieldImprovementKindDto::Farm,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::ConfirmWorkerImprovement {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
                improvement: Some(FieldImprovementKindDto::Farm),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelWorkerJob {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::AssignWorkerToHex {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelWorkerAssignment {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::BuildRoad {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::AutomateWorker {
                expected_revision: 8,
                unit_id: "worker-1".to_owned(),
            },
        },
    ]
}

pub(super) fn response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::WorkerOptions {
            stamp: stamp(),
            unit_id: "worker-1".to_owned(),
            coordinate: coordinate(1, 1),
            improvements: vec![WorkerImprovementOptionDto {
                improvement: FieldImprovementKindDto::Farm,
                build_turns: 3,
            }],
            can_assign: false,
            can_build_road: true,
            automation: Some(WorkerAutomationOptionDto {
                target: coordinate(1, 1),
                action: WorkerAutomationActionDto::Improve {
                    improvement: FieldImprovementKindDto::Farm,
                },
                movement_cost_units: 0,
                metrics: WorkerAutomationMetricsDto {
                    tiles_examined: 3,
                    legality_evaluations: 57,
                    routes_planned: 2,
                },
            }),
        },
    }
}
