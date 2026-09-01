use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{ReplayLogDto, ReplayRecordDto};
use aonw_domain::PlayerId;
use aonw_engine::GameEngine;

use super::{
    PersistenceError, ReplayRuntimeCommand, ReplayVerification, decode_record, replay_context,
    replay_result,
};
use crate::{LocalRuntime, OpenSession};

pub(crate) fn verify_replay(
    map: MapDefinition,
    ruleset: RulesetDefinition,
    input: &str,
) -> Result<ReplayVerification, PersistenceError> {
    let source_content = (map, ruleset);
    let replay = ReplayLogDto::from_json(input).map_err(PersistenceError::Codec)?;
    crate::persistence_validation::validate_replay_header(
        &replay,
        &source_content.0,
        &source_content.1,
    )?;
    let actor =
        PlayerId::new(replay.actor_player_id.clone()).map_err(PersistenceError::InvalidActor)?;
    let segment_count = replay.segments.len();
    let mut owned_context = Some((source_content.0, source_content.1, actor));
    let mut previous_checkpoint = None;
    let mut entry_count = 0;
    let mut final_stamp = None;
    let mut final_event_offset = 0;
    for (segment_index, segment) in replay.segments.into_iter().enumerate() {
        let initial_event_offset = segment.initial_event_offset;
        let initial_state_digest = segment.initial_state_digest;
        let entries = segment.entries;
        let state = decode_game_state(segment.initial_state).map_err(PersistenceError::State)?;
        if GameEngine::state_digest(&state).to_string() != initial_state_digest {
            return Err(PersistenceError::ReplayCheckpointDigestMismatch {
                segment: segment_index,
            });
        }
        if let Some((expected_digest, expected_offset)) = &previous_checkpoint
            && (&initial_state_digest != expected_digest
                || initial_event_offset != *expected_offset)
        {
            return Err(PersistenceError::ReplayCheckpointMismatch {
                segment: segment_index,
            });
        }
        let (segment_map, segment_ruleset, segment_actor) = if segment_index + 1 == segment_count {
            owned_context
                .take()
                .expect("last replay segment consumes verification context")
        } else {
            let retained = owned_context
                .as_ref()
                .expect("verification context exists before last segment");
            (retained.0.clone(), retained.1.clone(), retained.2.clone())
        };
        let mut runtime = LocalRuntime::default();
        runtime
            .open(
                OpenSession::from_state(segment_map, segment_ruleset, state, segment_actor)
                    .with_event_offset(initial_event_offset),
            )
            .map_err(PersistenceError::Open)?;
        verify_segment(&mut runtime, segment_index, &entries)?;
        entry_count += entries.len();
        let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
        let stamp = session.stamp();
        final_stamp = Some(stamp);
        final_event_offset = session.event_offset();
        previous_checkpoint = Some((stamp.state_digest.to_string(), session.event_offset()));
    }
    Ok(ReplayVerification {
        entry_count,
        final_stamp: final_stamp.expect("bounded codec rejects empty replay archives"),
        final_event_offset,
    })
}

fn verify_segment(
    runtime: &mut LocalRuntime,
    segment_index: usize,
    entries: &[aonw_contracts::ReplayEntryDto],
) -> Result<(), PersistenceError> {
    for (entry_index, entry) in entries.iter().enumerate() {
        verify_entry(runtime, segment_index, entry_index, entry)?;
    }
    Ok(())
}

pub(crate) fn verify_entry(
    runtime: &mut LocalRuntime,
    segment_index: usize,
    entry_index: usize,
    entry: &aonw_contracts::ReplayEntryDto,
) -> Result<(), PersistenceError> {
    let expected_index =
        u64::try_from(entry_index).map_err(|_| PersistenceError::ReplayIndexOverflow)?;
    if entry.index != expected_index {
        return Err(PersistenceError::ReplayIndexMismatch {
            segment: segment_index,
            expected: expected_index,
            found: entry.index,
        });
    }
    if matches!(entry.record, ReplayRecordDto::Player { .. })
        && let Some(recorded_actor) = entry.context.actor_player_id.as_deref()
    {
        let current_actor = runtime
            .session_ref()
            .map_err(PersistenceError::Runtime)?
            .actor();
        if current_actor.as_str() != recorded_actor {
            let recorded_actor =
                PlayerId::new(recorded_actor.to_owned()).map_err(PersistenceError::InvalidActor)?;
            runtime
                .handoff_hot_seat_actor(recorded_actor)
                .map_err(|_| PersistenceError::ReplayContextMismatch {
                    segment: segment_index,
                    entry: entry_index,
                })?;
        }
    }
    let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
    let context_actor = match &entry.record {
        ReplayRecordDto::Player { .. } => Some(session.actor()),
        ReplayRecordDto::System { .. } => None,
    };
    if entry.context != replay_context(session, context_actor) {
        return Err(PersistenceError::ReplayContextMismatch {
            segment: segment_index,
            entry: entry_index,
        });
    }
    let result = dispatch_replay(runtime, decode_record(&entry.record)?)?;
    let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
    if entry.result != replay_result(&result, session) {
        return Err(PersistenceError::ReplayResultMismatch {
            segment: segment_index,
            entry: entry_index,
        });
    }
    Ok(())
}

fn dispatch_replay(
    runtime: &mut LocalRuntime,
    command: ReplayRuntimeCommand,
) -> Result<crate::CommandResult, PersistenceError> {
    match command {
        ReplayRuntimeCommand::SelectTechnology(value) => runtime.select_technology(value),
        ReplayRuntimeCommand::Diplomacy(value) => runtime.diplomacy(&value),
        ReplayRuntimeCommand::Artifact(value) => runtime.artifact(&value),
        ReplayRuntimeCommand::FoundCity(value) => runtime.found_city(&value),
        ReplayRuntimeCommand::ToggleWorkedHex(value) => runtime.toggle_worked_hex(&value),
        ReplayRuntimeCommand::SelectCityExpansionHex(value) => {
            runtime.select_city_expansion_hex(&value)
        }
        ReplayRuntimeCommand::Production(value) => runtime.production(&value),
        ReplayRuntimeCommand::SelectWorkerImprovement(value) => {
            runtime.select_worker_improvement(&value)
        }
        ReplayRuntimeCommand::ConfirmWorkerImprovement(value) => {
            runtime.confirm_worker_improvement(&value)
        }
        ReplayRuntimeCommand::CancelWorkerJob(value) => runtime.cancel_worker_job(&value),
        ReplayRuntimeCommand::AssignWorkerToHex(value) => runtime.assign_worker_to_hex(&value),
        ReplayRuntimeCommand::CancelWorkerAssignment(value) => {
            runtime.cancel_worker_assignment(&value)
        }
        ReplayRuntimeCommand::BuildRoad(value) => runtime.build_road(&value),
        ReplayRuntimeCommand::AutomateWorker(value) => runtime.automate_worker(&value),
        ReplayRuntimeCommand::Attack(value) => runtime.attack_hex(&value),
        ReplayRuntimeCommand::Move(value) => runtime.dispatch(&value),
        ReplayRuntimeCommand::AutoExplore(value) => runtime.auto_explore_unit(&value),
        ReplayRuntimeCommand::AssignMerchantRoute(value) => {
            runtime.assign_merchant_trade_route(&value)
        }
        ReplayRuntimeCommand::MoveMerchantToCity(value) => runtime.move_merchant_to_city(&value),
        ReplayRuntimeCommand::DetachTroop(value) => runtime.detach_troop(&value),
        ReplayRuntimeCommand::Cancel(value) => runtime.cancel_unit_action(&value),
        ReplayRuntimeCommand::Skip(value) => runtime.skip_unit_turn(&value),
        ReplayRuntimeCommand::Fortify(value) => runtime.fortify_unit(&value),
        ReplayRuntimeCommand::EndTurn(value) => runtime.end_turn(value),
        ReplayRuntimeCommand::SubmitTurn(value) => runtime.submit_turn(value),
        ReplayRuntimeCommand::FinalizeTimedOutTurn(value) => {
            runtime.finalize_timed_out_turn(&value)
        }
        ReplayRuntimeCommand::KickParticipant(value) => runtime.kick_participant(&value),
        ReplayRuntimeCommand::ResignParticipant(value) => runtime.resign_participant(&value),
    }
    .map_err(PersistenceError::Runtime)
}
