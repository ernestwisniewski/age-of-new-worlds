use super::{dispatch_client, opened_runtime};
use aonw_contracts::FieldImprovementKindDto;
use aonw_contracts::client::{
    ClientCommandDto, ClientCommandResultDto, ClientEventDto, ClientRequestBodyDto,
    ClientResponseBodyDto, WorkerJobCompletionDto, YieldValueDto,
};

#[test]
fn completed_farm_preserves_its_yield_after_the_worker_is_consumed() {
    let mut runtime = opened_runtime();
    accepted(
        &mut runtime,
        ClientCommandDto::ConfirmWorkerImprovement {
            expected_revision: 9,
            unit_id: "worker-1".to_owned(),
            improvement: Some(FieldImprovementKindDto::Farm),
        },
    );
    for revision in 10..12 {
        let progress = accepted(
            &mut runtime,
            ClientCommandDto::EndTurn {
                expected_revision: revision,
            },
        );
        assert!(
            !progress
                .events
                .iter()
                .any(|event| matches!(event, ClientEventDto::WorkerCompletedJob { .. }))
        );
    }
    let completed = accepted(
        &mut runtime,
        ClientCommandDto::EndTurn {
            expected_revision: 12,
        },
    );
    let event = completed
        .events
        .iter()
        .find(|event| matches!(event, ClientEventDto::WorkerCompletedJob { .. }))
        .expect("completed worker event");
    let ClientEventDto::WorkerCompletedJob {
        unit_id,
        target,
        completion,
        yield_delta,
    } = event
    else {
        unreachable!()
    };
    assert_eq!(unit_id, "worker-1");
    assert_eq!((target.col, target.row), (1, 1));
    assert_eq!(
        *completion,
        WorkerJobCompletionDto::FieldImprovement {
            improvement: FieldImprovementKindDto::Farm
        }
    );
    assert_eq!(
        *yield_delta,
        YieldValueDto {
            food: 1,
            production: 0,
            gold: 0,
            defense: 0
        }
    );
    assert!(
        completed
            .view_patch
            .removed_unit_ids
            .iter()
            .any(|id| id == "worker-1")
    );
    let document = serde_json::to_value(event).expect("worker event JSON");
    assert_eq!(
        document["yieldDelta"],
        serde_json::json!({"food": 1, "production": 0, "gold": 0, "defense": 0})
    );
}

fn accepted(
    runtime: &mut aonw_local_runtime::LocalRuntime,
    command: ClientCommandDto,
) -> ClientCommandResultDto {
    let ClientResponseBodyDto::Command { result } =
        dispatch_client(runtime, ClientRequestBodyDto::Dispatch { command })
    else {
        panic!("command response")
    };
    assert_eq!(
        result.outcome,
        aonw_contracts::client::ClientCommandOutcomeDto::Accepted
    );
    *result
}
