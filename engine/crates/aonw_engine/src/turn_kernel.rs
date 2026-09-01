mod agreement_phase;
mod city_phase;
mod diplomacy_phase;
mod events;
mod final_phases;
mod objective_phase;
mod preparation;
mod processor_order;
mod resignation;
mod support;
mod system;
mod worker_phase;

use std::collections::BTreeSet;

use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId, PlayerTurnState, TurnMode, UtcTimestamp};

use crate::movement::{TurnMovementUpdate, advance_turn_movement};
use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainEvent, DomainTransition, EngineContext,
    FinalizeTimedOutTurnCommand, KickParticipantCommand, PlayerKickedEvent, SystemContext,
    TurnCommand, TurnProcessor,
};

use self::support::{
    InteractionStateUpdate, SequentialProgress, accept_identity, apply_update,
    ordered_submission_scope, rebuild_lifecycle, reject, sequential_progress,
    simultaneous_lifecycle, transition_with_phase_evidence, unsupported_processor_for_scope,
    valid_system_scope, validate_player_command,
};
use events::{TurnPhaseEvents, sequential_phase_events, simultaneous_phase_events};
use final_phases::{FinalTurnPhases, advance_final_turn_phases};
use preparation::{
    SimultaneousPreparationPhase, TurnPreparationPhase, advance_simultaneous_preparation,
    advance_turn_preparation,
};
use processor_order::{SEQUENTIAL_TURN_PROCESSORS, SIMULTANEOUS_TURN_PROCESSORS};
use resignation::apply_resignation;

pub(crate) use support::processor_is_required;

pub(crate) fn apply_submit_turn(
    state: GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if let Some(code) = validate_player_command(&state, context, command) {
        return Ok(reject(state, code, map_hash, ruleset_hash));
    }
    let turn = state.match_lifecycle().turn();
    if turn.submitted_player_ids().contains(command.player_id()) {
        return Ok(accept_identity(
            state,
            [TurnProcessor::Submission, TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        ));
    }
    let scope = ordered_submission_scope(&state);
    let mut submitted = turn.submitted_player_ids().clone();
    submitted.insert(command.player_id().clone());
    let mut states = turn.turn_states_by_player_id().clone();
    states.insert(command.player_id().clone(), PlayerTurnState::Finished);
    if !scope.iter().all(|player| submitted.contains(player)) {
        let lifecycle = rebuild_lifecycle(
            &state,
            states,
            turn.required_submission_player_ids().clone(),
            submitted,
            turn.timeout_streaks_by_player_id().clone(),
            turn.afk_player_ids().clone(),
            turn.kicked_player_ids().clone(),
            turn.resigned_player_ids().clone(),
            turn.turn_started_at().cloned(),
        )?;
        return apply_update(
            state,
            lifecycle,
            None,
            Vec::new(),
            None,
            None,
            None,
            None,
            None,
            InteractionStateUpdate::Preserve,
            Box::new([]),
            [TurnProcessor::Submission, TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        );
    }
    finalize_simultaneous(
        state,
        context.map(),
        context.ruleset(),
        &scope,
        &[],
        None,
        false,
        map_hash,
        ruleset_hash,
    )
}

pub(crate) fn apply_end_turn(
    state: GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if let Some(code) = validate_player_command(&state, context, command) {
        return Ok(reject(state, code, map_hash, ruleset_hash));
    }
    let identity = state.match_lifecycle().identity();
    if identity.turn_mode() == TurnMode::Simultaneous {
        return apply_submit_turn(state, context, command, map_hash, ruleset_hash);
    }
    let progress = match sequential_progress(&state, command.player_id()) {
        Ok(progress) => progress,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    if unsupported_processor_for_scope(&state, context.map(), &progress.reset_scope).is_some() {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnProcessorUnsupported,
            map_hash,
            ruleset_hash,
        ));
    }
    let preparation = advance_turn_preparation(
        state,
        context.map(),
        context.ruleset(),
        &progress.reset_scope,
        &BTreeSet::new(),
    )?;
    finish_sequential_turn(
        preparation,
        context,
        command,
        progress,
        (map_hash, ruleset_hash),
    )
}

fn finish_sequential_turn(
    preparation: TurnPreparationPhase,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
    progress: SequentialProgress,
    hashes: (ContentHash, ContentHash),
) -> Result<DomainTransition, CanonicalEngineError> {
    let state = preparation.state;
    let movement = match advance_turn_movement(
        &state,
        context.map(),
        context.ruleset(),
        &progress.reset_scope,
    ) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(state, code, hashes.0, hashes.1)),
    };
    let lifecycle = state.match_lifecycle().turn();
    let required = lifecycle.required_submission_player_ids().clone();
    let submitted = if progress.round_complete {
        BTreeSet::new()
    } else {
        lifecycle.submitted_player_ids().clone()
    };
    let next_lifecycle = rebuild_lifecycle(
        &state,
        progress.states,
        required,
        submitted,
        lifecycle.timeout_streaks_by_player_id().clone(),
        lifecycle.afk_player_ids().clone(),
        lifecycle.kicked_player_ids().clone(),
        lifecycle.resigned_player_ids().clone(),
        lifecycle.turn_started_at().cloned(),
    )?;
    let TurnMovementUpdate {
        units,
        fog_of_war,
        diplomacy,
        interaction,
        events: movement_events,
        executions,
        reset_unit_ids,
        invalidated_order_unit_ids,
        finished_auto_explore_unit_ids,
    } = movement;
    let mut weariness_counts = crate::economy::WarWearinessEventCounts::default();
    let FinalTurnPhases {
        economy,
        diplomacy,
        objectives,
        outcome,
        diplomacy_events,
        objective_events,
        stability_events,
        outcome_events,
    } = advance_final_turn_phases(
        &state,
        context.map(),
        context.ruleset(),
        &units,
        diplomacy,
        &progress.reset_scope,
        progress.next_turn,
        &mut weariness_counts,
    )?;
    let events = sequential_phase_events(
        TurnPhaseEvents {
            settlement: preparation.events,
            movement: movement_events,
            research: preparation.research_events,
            diplomacy: diplomacy_events,
            objectives: objective_events,
            stability: stability_events,
            outcome: outcome_events,
        },
        command.player_id(),
    );
    apply_update(
        state,
        next_lifecycle,
        Some(progress.next_turn),
        units,
        Some(economy),
        Some(fog_of_war),
        Some(diplomacy),
        Some(objectives),
        Some(outcome),
        InteractionStateUpdate::Replace(interaction),
        events,
        SEQUENTIAL_TURN_PROCESSORS,
        hashes.0,
        hashes.1,
    )
    .map(|transition| {
        transition_with_phase_evidence(
            transition,
            Vec::new(),
            reset_unit_ids,
            executions,
            invalidated_order_unit_ids,
            finished_auto_explore_unit_ids,
            preparation.founded_city_ids,
        )
    })
}

fn apply_timeout_finalization(
    state: GameState,
    context: SystemContext<'_>,
    command: FinalizeTimedOutTurnCommand<'_>,
    hashes: (ContentHash, ContentHash),
) -> Result<DomainTransition, CanonicalEngineError> {
    if state.revision().get() != command.expected_revision() {
        return Ok(reject(
            state,
            CommandRejectionCode::StaleRevision,
            hashes.0,
            hashes.1,
        ));
    }
    if !valid_system_scope(&state, command.player_ids(), command.skipped_player_ids()) {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnScopeInvalid,
            hashes.0,
            hashes.1,
        ));
    }
    finalize_simultaneous(
        state,
        context.map(),
        context.ruleset(),
        command.player_ids(),
        command.skipped_player_ids(),
        command.next_turn_started_at().cloned(),
        true,
        hashes.0,
        hashes.1,
    )
}

fn apply_kick(
    state: GameState,
    command: KickParticipantCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if state.revision().get() != command.expected_revision() {
        return Ok(reject(
            state,
            CommandRejectionCode::StaleRevision,
            map_hash,
            ruleset_hash,
        ));
    }
    if !state
        .match_lifecycle()
        .identity()
        .contains(command.player_id())
    {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnPlayerNotActive,
            map_hash,
            ruleset_hash,
        ));
    }
    let turn = state.match_lifecycle().turn();
    if turn.kicked_player_ids().contains(command.player_id()) {
        return Ok(accept_identity(
            state,
            [TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        ));
    }
    let mut states = turn.turn_states_by_player_id().clone();
    states.insert(command.player_id().clone(), PlayerTurnState::Finished);
    let mut required = turn.required_submission_player_ids().clone();
    required.remove(command.player_id());
    let mut submitted = turn.submitted_player_ids().clone();
    submitted.remove(command.player_id());
    let mut afk = turn.afk_player_ids().clone();
    afk.insert(command.player_id().clone());
    let mut kicked = turn.kicked_player_ids().clone();
    kicked.insert(command.player_id().clone());
    let lifecycle = rebuild_lifecycle(
        &state,
        states,
        required,
        submitted,
        turn.timeout_streaks_by_player_id().clone(),
        afk,
        kicked,
        turn.resigned_player_ids().clone(),
        turn.turn_started_at().cloned(),
    )?;
    let event = DomainEvent::PlayerKicked(PlayerKickedEvent::new(
        state.turn(),
        command.player_id().clone(),
        command.reason(),
        command.timeout_streak(),
    ));
    apply_update(
        state,
        lifecycle,
        None,
        Vec::new(),
        None,
        None,
        None,
        None,
        None,
        InteractionStateUpdate::Preserve,
        vec![event].into_boxed_slice(),
        [TurnProcessor::Lifecycle],
        map_hash,
        ruleset_hash,
    )
}

#[allow(clippy::too_many_arguments)]
fn finalize_simultaneous(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    next_turn_started_at: Option<UtcTimestamp>,
    track_timeout_streaks: bool,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let next_turn = match simultaneous_preflight(&state, map, scope) {
        Ok(next_turn) => next_turn,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    let lifecycle = simultaneous_lifecycle(
        &state,
        scope,
        skipped,
        next_turn_started_at,
        track_timeout_streaks,
    )?;
    let current_turn = state.turn();
    let SimultaneousPreparationPhase {
        turn: preparation,
        combat_events,
        combat_executions,
        mut weariness_counts,
    } = advance_simultaneous_preparation(state, map, ruleset, scope)?;
    let movement = match advance_turn_movement(&preparation.state, map, ruleset, scope) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(preparation.state, code, map_hash, ruleset_hash)),
    };
    let TurnMovementUpdate {
        units,
        fog_of_war,
        diplomacy,
        interaction,
        events: movement_events,
        executions,
        reset_unit_ids,
        invalidated_order_unit_ids,
        finished_auto_explore_unit_ids,
    } = movement;
    let FinalTurnPhases {
        economy,
        diplomacy,
        objectives,
        outcome,
        diplomacy_events,
        objective_events,
        stability_events,
        outcome_events,
    } = advance_final_turn_phases(
        &preparation.state,
        map,
        ruleset,
        &units,
        diplomacy,
        scope,
        next_turn,
        &mut weariness_counts,
    )?;
    let events = simultaneous_phase_events(
        current_turn,
        scope,
        skipped,
        combat_events,
        TurnPhaseEvents {
            settlement: preparation.events,
            movement: movement_events,
            research: preparation.research_events,
            diplomacy: diplomacy_events,
            objectives: objective_events,
            stability: stability_events,
            outcome: outcome_events,
        },
    );
    apply_update(
        preparation.state,
        lifecycle,
        Some(next_turn),
        units,
        Some(economy),
        Some(fog_of_war),
        Some(diplomacy),
        Some(objectives),
        Some(outcome),
        InteractionStateUpdate::Replace(interaction),
        events,
        SIMULTANEOUS_TURN_PROCESSORS,
        map_hash,
        ruleset_hash,
    )
    .map(|transition| {
        transition_with_phase_evidence(
            transition,
            combat_executions.into_vec(),
            reset_unit_ids,
            executions,
            invalidated_order_unit_ids,
            finished_auto_explore_unit_ids,
            preparation.founded_city_ids,
        )
    })
}

fn simultaneous_preflight(
    state: &GameState,
    map: &MapDefinition,
    scope: &[PlayerId],
) -> Result<u32, CommandRejectionCode> {
    if unsupported_processor_for_scope(state, map, scope).is_some() {
        return Err(CommandRejectionCode::TurnProcessorUnsupported);
    }
    state
        .turn()
        .checked_add(1)
        .ok_or(CommandRejectionCode::TurnNumberOverflow)
}
