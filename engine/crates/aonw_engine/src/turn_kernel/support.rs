use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{ContentHash, MapDefinition};
use aonw_domain::{
    Diplomacy, EconomyState, FogOfWar, GameOutcome, GameState, InteractionState, MatchLifecycle,
    ObjectiveState, PendingInteraction, PlayerId, PlayerTurnState, TurnLifecycle, UnitPosture,
    UtcTimestamp,
};

use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainEvent, DomainTransition, EngineContext,
    ExecutionEvidence, ProcessorRequirement, SystemContext, TurnCommand, TurnKernelCapabilities,
    TurnKernelExecution, TurnProcessor, UnitMovementExecution,
};

pub(super) fn validate_player_command(
    state: &GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
) -> Option<CommandRejectionCode> {
    if state.revision().get() != command.expected_revision() {
        return Some(CommandRejectionCode::StaleRevision);
    }
    if context.actor_player_id() != command.player_id() {
        return Some(CommandRejectionCode::TurnPlayerNotControlled);
    }
    let lifecycle = state.match_lifecycle();
    if !lifecycle.identity().contains(command.player_id())
        || lifecycle
            .turn()
            .kicked_player_ids()
            .contains(command.player_id())
        || lifecycle
            .turn()
            .turn_states_by_player_id()
            .get(command.player_id())
            == Some(&PlayerTurnState::Finished)
            && !lifecycle
                .turn()
                .submitted_player_ids()
                .contains(command.player_id())
    {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    None
}

pub(super) fn ordered_submission_scope(state: &GameState) -> Vec<PlayerId> {
    let lifecycle = state.match_lifecycle().turn();
    let required = lifecycle.required_submission_player_ids();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| {
            !lifecycle.kicked_player_ids().contains(*player)
                && (required.is_empty() || required.contains(*player))
        })
        .cloned()
        .collect()
}

pub(super) fn simultaneous_lifecycle(
    state: &GameState,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    next_turn_started_at: Option<UtcTimestamp>,
    track_timeout_streaks: bool,
) -> Result<MatchLifecycle, CanonicalEngineError> {
    let current = state.match_lifecycle().turn();
    let mut states = current.turn_states_by_player_id().clone();
    for player in scope {
        states.insert(player.clone(), PlayerTurnState::Active);
    }
    for player in current.kicked_player_ids() {
        states.insert(player.clone(), PlayerTurnState::Finished);
    }
    let timeouts = if track_timeout_streaks {
        skipped
            .iter()
            .map(|player| {
                let previous = current
                    .timeout_streaks_by_player_id()
                    .get(player)
                    .copied()
                    .unwrap_or_default();
                (player.clone(), previous.saturating_add(1))
            })
            .collect()
    } else {
        current.timeout_streaks_by_player_id().clone()
    };
    rebuild_lifecycle(
        state,
        states,
        current.required_submission_player_ids().clone(),
        BTreeSet::new(),
        timeouts,
        current.afk_player_ids().clone(),
        current.kicked_player_ids().clone(),
        next_turn_started_at.or_else(|| current.turn_started_at().cloned()),
    )
}

pub(super) fn ordered_active_scope(state: &GameState) -> Vec<PlayerId> {
    let kicked = state.match_lifecycle().turn().kicked_player_ids();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| !kicked.contains(*player))
        .cloned()
        .collect()
}

pub(super) fn next_active_player(
    scope: &[PlayerId],
    after: &PlayerId,
    states: &BTreeMap<PlayerId, PlayerTurnState>,
) -> Option<PlayerId> {
    if scope.is_empty() {
        return None;
    }
    let start = scope.iter().position(|player| player == after).unwrap_or(0);
    (1..=scope.len())
        .map(|offset| &scope[(start + offset) % scope.len()])
        .find(|player| states.get(*player) != Some(&PlayerTurnState::Finished))
        .cloned()
}

pub(super) struct SequentialProgress {
    pub(super) states: BTreeMap<PlayerId, PlayerTurnState>,
    pub(super) next_turn: u32,
    pub(super) reset_scope: Vec<PlayerId>,
    pub(super) round_complete: bool,
}

pub(super) fn sequential_progress(
    state: &GameState,
    player_id: &PlayerId,
) -> Result<SequentialProgress, CommandRejectionCode> {
    let mut states = state
        .match_lifecycle()
        .turn()
        .turn_states_by_player_id()
        .clone();
    states.insert(player_id.clone(), PlayerTurnState::Finished);
    let active_scope = ordered_active_scope(state);
    let round_complete = active_scope
        .iter()
        .all(|player| states.get(player) == Some(&PlayerTurnState::Finished));
    let next_turn = if round_complete {
        state
            .turn()
            .checked_add(1)
            .ok_or(CommandRejectionCode::TurnNumberOverflow)?
    } else {
        state.turn()
    };
    if round_complete {
        for player in &active_scope {
            states.insert(player.clone(), PlayerTurnState::Active);
        }
    }
    let reset_scope = next_active_player(&active_scope, player_id, &states)
        .into_iter()
        .collect();
    Ok(SequentialProgress {
        states,
        next_turn,
        reset_scope,
        round_complete,
    })
}

pub(super) fn unsupported_processor_for_scope(
    state: &GameState,
    map: &MapDefinition,
    player_ids: &[PlayerId],
) -> Option<TurnProcessor> {
    TurnKernelCapabilities::ORDERED
        .into_iter()
        .map(|processor| (processor, processor.requirement(state, map, player_ids)))
        .find_map(|(processor, requirement)| {
            (requirement == ProcessorRequirement::RequiredButUnsupported).then_some(processor)
        })
}

pub(crate) fn processor_is_required(
    processor: TurnProcessor,
    state: &GameState,
    map: &MapDefinition,
    player_ids: &[PlayerId],
) -> bool {
    let owns_scope = |player: &PlayerId| player_ids.contains(player);
    match processor {
        TurnProcessor::Submission | TurnProcessor::Lifecycle | TurnProcessor::MovementReset => {
            !player_ids.is_empty()
        }
        TurnProcessor::Combat => state
            .combat()
            .intended_attacks()
            .iter()
            .any(|attack| owns_scope(attack.declaring_player_id())),
        TurnProcessor::CityFounding => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.activity().city_founding_job().is_some()
        }),
        TurnProcessor::WorkerJobs => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.activity().worker_job().is_some()
        }),
        TurnProcessor::Production => state
            .cities()
            .iter()
            .any(|city| owns_scope(city.owner_player_id()) && city.production_queue().is_some()),
        TurnProcessor::Artifacts => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.activity().excavating_artifact_id().is_some()
        }),
        TurnProcessor::QueuedMovement => state
            .units()
            .iter()
            .any(|unit| owns_scope(unit.owner_player_id()) && unit.queued_path().is_some()),
        TurnProcessor::TradeRoutes => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.merchant_trade_route().is_some()
        }),
        TurnProcessor::WorkerAutomation => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.posture() == UnitPosture::AutoWorking
        }),
        TurnProcessor::AutoExplore => state.units().iter().any(|unit| {
            owns_scope(unit.owner_player_id()) && unit.posture() == UnitPosture::AutoExploring
        }),
        TurnProcessor::ReversibleSkipCleanup => matches!(
            state.interaction().pending(),
            Some(PendingInteraction::UnitTurnSkip {
                owner_player_id,
                ..
            }) if owns_scope(owner_player_id)
        ),
        TurnProcessor::Economy | TurnProcessor::Outcome => !player_ids.is_empty(),
        TurnProcessor::Research => {
            state.research().players().iter().any(|(player, research)| {
                owns_scope(player)
                    && (research.active_technology_id().is_some()
                        || !research.progress_by_technology_id().is_empty()
                        || research.science_overflow() > 0)
            }) || state
                .cities()
                .iter()
                .any(|city| owns_scope(city.owner_player_id()))
        }
        TurnProcessor::Agreements => {
            state
                .diplomacy()
                .resource_trade_agreements()
                .iter()
                .any(|agreement| {
                    owns_scope(agreement.exporter_player_id())
                        || owns_scope(agreement.importer_player_id())
                })
        }
        TurnProcessor::Diplomacy => diplomacy_is_required(state, &owns_scope),
        TurnProcessor::Objectives => {
            super::objective_phase::processor_is_required(state, map, player_ids)
        }
    }
}

fn diplomacy_is_required(state: &GameState, owns_scope: &impl Fn(&PlayerId) -> bool) -> bool {
    let next_turn = state.turn().saturating_add(1);
    let diplomacy = state.diplomacy();
    diplomacy.relations().iter().any(|relation| {
        (owns_scope(relation.pair().first()) || owns_scope(relation.pair().second()))
            && relation
                .status_expires_on_turn()
                .is_some_and(|turn| turn <= next_turn)
    }) || diplomacy.pending_proposals().iter().any(|proposal| {
        (owns_scope(proposal.from_player_id()) || owns_scope(proposal.to_player_id()))
            && proposal.expires_on_turn() <= next_turn
    }) || diplomacy.messages().iter().any(|message| {
        (owns_scope(message.from_player_id()) || owns_scope(message.to_player_id()))
            && (message.response().is_none() && message.expires_on_turn() <= next_turn
                || message
                    .promise_due_turn()
                    .is_some_and(|turn| turn <= next_turn)
                    && !message.promise_broken())
    })
}

pub(super) fn valid_system_scope(
    state: &GameState,
    scope: &[PlayerId],
    skipped: &[PlayerId],
) -> bool {
    let unique_scope = scope.iter().collect::<BTreeSet<_>>();
    let unique_skipped = skipped.iter().collect::<BTreeSet<_>>();
    !scope.is_empty()
        && unique_scope.len() == scope.len()
        && unique_skipped.len() == skipped.len()
        && scope.iter().all(|player| {
            state.match_lifecycle().identity().contains(player)
                && !state
                    .match_lifecycle()
                    .turn()
                    .kicked_player_ids()
                    .contains(player)
        })
        && skipped.iter().all(|player| unique_scope.contains(player))
}

#[allow(clippy::too_many_arguments)]
pub(super) fn rebuild_lifecycle(
    state: &GameState,
    states: BTreeMap<PlayerId, PlayerTurnState>,
    required: BTreeSet<PlayerId>,
    submitted: BTreeSet<PlayerId>,
    timeouts: BTreeMap<PlayerId, i64>,
    afk: BTreeSet<PlayerId>,
    kicked: BTreeSet<PlayerId>,
    started: Option<UtcTimestamp>,
) -> Result<MatchLifecycle, CanonicalEngineError> {
    let identity = state.match_lifecycle().identity().clone();
    let turn = TurnLifecycle::try_new(
        &identity, states, required, submitted, timeouts, afk, kicked, started,
    )
    .map_err(CanonicalEngineError::TurnLifecycle)?;
    Ok(MatchLifecycle::new(identity, turn))
}

pub(super) enum InteractionStateUpdate {
    Preserve,
    Replace(InteractionState),
}

#[allow(clippy::too_many_arguments)]
pub(super) fn apply_update<const PROCESSORS: usize>(
    state: GameState,
    lifecycle: MatchLifecycle,
    turn: Option<u32>,
    units: Vec<aonw_domain::Unit>,
    economy: Option<EconomyState>,
    fog_of_war: Option<FogOfWar>,
    diplomacy: Option<Diplomacy>,
    objectives: Option<ObjectiveState>,
    outcome: Option<GameOutcome>,
    interaction: InteractionStateUpdate,
    events: Box<[DomainEvent]>,
    processors: [TurnProcessor; PROCESSORS],
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let Some(revision) = state.revision().checked_next() else {
        return Ok(reject(
            state,
            CommandRejectionCode::StateRevisionOverflow,
            map_hash,
            ruleset_hash,
        ));
    };
    let turn = turn.unwrap_or_else(|| state.turn());
    let units = if units.is_empty() {
        state.units().to_vec()
    } else {
        units
    };
    let fog_of_war = fog_of_war.unwrap_or_else(|| state.fog_of_war().clone());
    let economy = economy.unwrap_or_else(|| state.economy().clone());
    let diplomacy = diplomacy.unwrap_or_else(|| state.diplomacy().clone());
    let objectives = objectives.unwrap_or_else(|| state.objectives().clone());
    let outcome = outcome.unwrap_or_else(|| state.outcome().clone());
    let interaction = match interaction {
        InteractionStateUpdate::Preserve => state.interaction().clone(),
        InteractionStateUpdate::Replace(value) => value,
    };
    let state = state
        .into_after_turn_kernel(aonw_domain::TurnKernelStateUpdate {
            revision,
            turn,
            lifecycle,
            units,
            economy,
            fog_of_war,
            diplomacy,
            objectives,
            outcome,
            interaction,
        })
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        state,
        events,
        Some(ExecutionEvidence::TurnKernel(TurnKernelExecution::new(
            processors,
            Vec::<aonw_domain::UnitId>::new(),
        ))),
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn transition_with_phase_evidence(
    transition: DomainTransition,
    combat_executions: Vec<crate::CombatExecution>,
    reset_unit_ids: Vec<aonw_domain::UnitId>,
    movement_executions: Vec<UnitMovementExecution>,
    invalidated_order_unit_ids: Vec<aonw_domain::UnitId>,
    finished_auto_explore_unit_ids: Vec<aonw_domain::UnitId>,
    founded_city_ids: Vec<aonw_domain::CityId>,
) -> DomainTransition {
    let processors = match transition.evidence() {
        Some(ExecutionEvidence::TurnKernel(value)) => value.processors().to_vec(),
        _ => Vec::new(),
    };
    transition.with_evidence(Some(ExecutionEvidence::TurnKernel(
        TurnKernelExecution::with_phases(
            processors,
            combat_executions,
            reset_unit_ids,
            movement_executions,
            invalidated_order_unit_ids,
            finished_auto_explore_unit_ids,
            founded_city_ids,
        ),
    )))
}

pub(super) fn accept_identity<const PROCESSORS: usize>(
    state: GameState,
    processors: [TurnProcessor; PROCESSORS],
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> DomainTransition {
    DomainTransition::accepted(
        state,
        Box::new([]),
        Some(ExecutionEvidence::TurnKernel(TurnKernelExecution::new(
            processors,
            Vec::<aonw_domain::UnitId>::new(),
        ))),
        map_hash,
        ruleset_hash,
    )
}

pub(super) fn reject(
    state: GameState,
    code: CommandRejectionCode,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> DomainTransition {
    DomainTransition::rejected(state, code, map_hash, ruleset_hash)
}

pub(super) fn system_content_hashes(
    context: SystemContext<'_>,
) -> Result<(ContentHash, ContentHash), CanonicalEngineError> {
    let map = context
        .map()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    let ruleset = context
        .ruleset()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    Ok((map, ruleset))
}
