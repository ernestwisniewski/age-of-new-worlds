use aonw_contracts::client::{
    ClientCommandDto, ClientCommandOutcomeDto, ClientRequestBodyDto, ClientResponseBodyDto,
};
use aonw_domain::{PendingInteraction, ResearchStateUpdate};
use aonw_local_runtime::{LocalRuntime, OpenSession};

use super::{dispatch, fixture};

#[test]
fn pending_research_cancellation_survives_save_and_verified_replay() {
    let (map, ruleset, state, actor) = fixture();
    let state = state
        .clone()
        .into_after_research(ResearchStateUpdate {
            revision: state.revision(),
            knowledge: state.knowledge().clone(),
            interaction: state.interaction().clone().with_pending(Some(
                PendingInteraction::ResearchSelection {
                    owner_player_id: actor.clone(),
                },
            )),
        })
        .expect("pending research state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            ruleset.clone(),
            state,
            actor,
        ))
        .expect("open pending selection");
    let initial = runtime.snapshot().expect("initial snapshot");
    assert!(initial.pending_action().is_some());

    let cancelled = cancel(&mut runtime, 0);
    assert_eq!(cancelled.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(cancelled.stamp.revision, 1);
    assert!(cancelled.events.is_empty());
    assert!(cancelled.evidence.is_none());
    assert!(cancelled.view_patch.pending_action.is_none());
    assert!(cancelled.view_patch.research.is_none());
    let expected = runtime.snapshot().expect("cancelled snapshot");
    assert!(expected.pending_action().is_none());
    assert_eq!(expected.research(), initial.research());

    let repeated = cancel(&mut runtime, 1);
    assert_eq!(repeated.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(repeated.stamp, cancelled.stamp);
    assert_eq!(runtime.snapshot().expect("unchanged snapshot"), expected);

    let rejected = cancel(&mut runtime, 0);
    assert!(matches!(
        rejected.outcome,
        ClientCommandOutcomeDto::Rejected { .. }
    ));
    assert_eq!(rejected.stamp, cancelled.stamp);

    let save = runtime.export_save_json().expect("save after cancellation");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), ruleset.clone(), &save)
        .expect("reopen save");
    assert_eq!(reopened.snapshot().expect("restored snapshot"), expected);
    let replay = runtime.export_replay_json().expect("cancellation replay");
    assert!(replay.contains("cancelResearchSelection"));
    let verified =
        LocalRuntime::verify_replay_json(map, ruleset, &replay).expect("verified replay");
    assert_eq!(verified.entry_count, 3);
    assert_eq!(verified.final_stamp.revision.get(), 1);
    assert_eq!(
        verified.final_stamp.state_digest.to_string(),
        cancelled.stamp.state_digest
    );
}

fn cancel(
    runtime: &mut LocalRuntime,
    expected_revision: u64,
) -> aonw_contracts::client::ClientCommandResultDto {
    let ClientResponseBodyDto::Command { result } = dispatch(
        runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelResearchSelection { expected_revision },
        },
    ) else {
        panic!("cancellation response")
    };
    *result
}
