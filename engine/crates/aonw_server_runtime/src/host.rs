use std::sync::Arc;

use aonw_domain::{GameState, PlayerId};
use aonw_engine::{
    DomainEvent, EngineContext, ExecutionEvidence, GameEngine, MovementVisibility, PlayerCommand,
    TurnCommand,
};
use aonw_projection::{
    ProjectedView, RecipientDisclosure, SessionStamp, diff_view, unchanged_view,
};

use crate::{
    PreparedServerWorld, RecipientOutcome, ServerCommandOutcome, ServerHostError,
    SubmitTurnRequest, validate_state,
};

/// Complete trusted input for one authenticated player command.
///
/// The authoritative actor comes from the server session. For turn commands,
/// the host replaces any embedded player identifier with this actor before
/// entering the engine.
#[derive(Clone, Debug)]
pub struct PlayerCommandRequest<'command> {
    /// Canonical state locked by the server transaction.
    pub state: GameState,
    /// Immutable map and rules prepared outside the match transaction.
    pub world: PreparedServerWorld,
    /// Player identity derived from the authenticated server session.
    pub authenticated_actor: PlayerId,
    /// Strict command decoded by the trusted server boundary.
    pub command: PlayerCommand<'command>,
    /// Durable offset immediately before this command.
    pub initial_event_offset: u64,
}

/// Applies one authenticated `SubmitTurn` without retaining process-local session state.
///
/// The caller must hold the match transaction and persist the returned state, offsets,
/// and recipient outputs atomically. An error means that nothing may be persisted.
///
/// # Errors
///
/// Returns an error for inconsistent trusted inputs, offset overflow, invalid immutable
/// content, or an internal engine failure.
pub fn apply_submit_turn(
    request: SubmitTurnRequest,
) -> Result<ServerCommandOutcome, ServerHostError> {
    let SubmitTurnRequest {
        state,
        world,
        authenticated_actor,
        expected_revision,
        initial_event_offset,
    } = request;
    let command_actor = authenticated_actor.clone();
    apply_player_command(PlayerCommandRequest {
        state,
        world,
        authenticated_actor,
        command: PlayerCommand::SubmitTurn(TurnCommand::new(expected_revision, &command_actor)),
        initial_event_offset,
    })
}

/// Applies one authenticated player command without retaining process-local session state.
///
/// The caller must hold the match transaction and persist the returned state, offsets,
/// and recipient outputs atomically. An error means that nothing may be persisted.
///
/// # Errors
///
/// Returns an error for inconsistent trusted inputs, offset overflow, invalid immutable
/// content, or an internal engine failure.
pub fn apply_player_command(
    request: PlayerCommandRequest<'_>,
) -> Result<ServerCommandOutcome, ServerHostError> {
    validate_request(&request)?;
    let PlayerCommandRequest {
        state,
        world,
        authenticated_actor,
        command,
        initial_event_offset,
    } = request;
    let command = bind_authenticated_actor(command, &authenticated_actor);
    let budget = command.event_budget(&state);
    initial_event_offset
        .checked_add(budget.maximum())
        .ok_or(ServerHostError::EventOffsetOverflow)?;

    let compiled = world.compiled();
    let visibility = MovementVisibility::for_player(&state, compiled.map(), &authenticated_actor);
    let before_digest = GameEngine::state_digest(&state);
    let before_revision = state.revision().get();
    let before_views = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(|participant| {
            let recipient = Arc::new(participant.id().clone());
            let view = ProjectedView::try_for_recipient(
                &state,
                recipient,
                compiled.map(),
                compiled.ruleset(),
            )
            .map_err(ServerHostError::Projection)?;
            Ok((participant.id().clone(), view))
        })
        .collect::<Result<Vec<_>, ServerHostError>>()?;

    let context =
        EngineContext::canonical(&authenticated_actor, compiled.map(), compiled.ruleset())
            .with_compiled_movement_map(compiled)
            .with_movement_visibility(&visibility);
    let parts = GameEngine::apply_player_owned(state, context, command)
        .map_err(ServerHostError::Engine)?
        .into_parts();
    let final_event_offset =
        checked_final_event_offset(initial_event_offset, budget, parts.events.len())?;
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let accepted = rejection.is_none();
    let state_digest = parts.digest.unwrap_or(before_digest);
    let stamp = SessionStamp {
        revision: parts.state.revision(),
        state_digest,
        map_hash: parts.map_hash,
        ruleset_hash: parts.ruleset_hash,
    };
    let recipients = before_views
        .into_iter()
        .map(|(recipient, before)| {
            recipient_outcome(
                recipient,
                &before,
                &parts.state,
                &parts.events,
                parts.evidence.as_ref(),
                accepted,
                before_revision,
                stamp,
                &world,
            )
        })
        .collect::<Result<Vec<_>, ServerHostError>>()?
        .into_boxed_slice();

    Ok(ServerCommandOutcome {
        state: parts.state,
        rejection,
        events: parts.events,
        evidence: parts.evidence,
        stamp,
        initial_event_offset,
        final_event_offset,
        recipients,
    })
}

fn bind_authenticated_actor<'command>(
    command: PlayerCommand<'command>,
    authenticated_actor: &'command PlayerId,
) -> PlayerCommand<'command> {
    match command {
        PlayerCommand::EndTurn(command) => PlayerCommand::EndTurn(TurnCommand::new(
            command.expected_revision(),
            authenticated_actor,
        )),
        PlayerCommand::SubmitTurn(command) => PlayerCommand::SubmitTurn(TurnCommand::new(
            command.expected_revision(),
            authenticated_actor,
        )),
        command => command,
    }
}

fn validate_request(request: &PlayerCommandRequest<'_>) -> Result<(), ServerHostError> {
    validate_state(&request.state, &request.world)?;
    let identity = request.state.match_lifecycle().identity();
    if !identity.contains(&request.authenticated_actor) {
        return Err(ServerHostError::UnknownAuthenticatedActor(
            request.authenticated_actor.clone(),
        ));
    }
    Ok(())
}

fn checked_final_event_offset(
    initial: u64,
    budget: aonw_engine::EventBudget,
    actual: usize,
) -> Result<u64, ServerHostError> {
    let actual = u64::try_from(actual).map_err(|_| ServerHostError::EventBudgetExceeded {
        maximum: budget.maximum(),
        actual: u64::MAX,
    })?;
    if !budget.accepts(actual) {
        return Err(ServerHostError::EventBudgetExceeded {
            maximum: budget.maximum(),
            actual,
        });
    }
    initial
        .checked_add(actual)
        .ok_or(ServerHostError::EventOffsetOverflow)
}

#[allow(clippy::too_many_arguments)]
fn recipient_outcome(
    recipient: PlayerId,
    before: &ProjectedView,
    state: &GameState,
    events: &[DomainEvent],
    evidence: Option<&ExecutionEvidence>,
    accepted: bool,
    before_revision: u64,
    stamp: SessionStamp,
    world: &crate::PreparedServerWorld,
) -> Result<RecipientOutcome, ServerHostError> {
    let disclosure = if accepted {
        RecipientDisclosure::new(recipient.clone(), before.units(), before.cities(), evidence)
    } else {
        RecipientDisclosure::empty(recipient.clone())
    };
    let after = if accepted {
        Some(
            ProjectedView::try_for_recipient(
                state,
                Arc::new(recipient.clone()),
                world.compiled().map(),
                world.compiled().ruleset(),
            )
            .map_err(ServerHostError::Projection)?,
        )
    } else {
        None
    };
    let patch = after.as_ref().map_or_else(
        || unchanged_view(before_revision, before),
        |after| diff_view(before_revision, state.revision().get(), before, after),
    );
    let snapshot = after.as_ref().unwrap_or(before).snapshot(stamp);
    let events = events
        .iter()
        .filter(|event| disclosure.allows_event(event))
        .cloned()
        .collect();
    Ok(RecipientOutcome {
        recipient_player_id: recipient,
        snapshot,
        patch,
        events,
        disclosure,
    })
}
