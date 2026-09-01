use aonw_content::ContentHash;
use aonw_domain::{GameOutcome, GameState, MatchIdentity, PlayerId, PlayerTurnState};

use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainEvent, DomainTransition, MatchEndedEvent,
    PlayerResignedEvent, ResignParticipantCommand, TurnProcessor,
};

use super::support::{
    InteractionStateUpdate, accept_identity, apply_update, rebuild_lifecycle, reject,
};

pub(super) fn apply_resignation(
    state: GameState,
    command: ResignParticipantCommand<'_>,
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
    let identity = state.match_lifecycle().identity();
    let turn = state.match_lifecycle().turn();
    if !identity.contains(command.player_id())
        || turn.kicked_player_ids().contains(command.player_id())
    {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnPlayerNotActive,
            map_hash,
            ruleset_hash,
        ));
    }
    if turn.resigned_player_ids().contains(command.player_id()) {
        return Ok(accept_identity(
            state,
            [TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        ));
    }
    let active = active_players(&state);
    if active.len() <= 1 || !active.contains(command.player_id()) {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnPlayerNotActive,
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
    let mut resigned = turn.resigned_player_ids().clone();
    resigned.insert(command.player_id().clone());
    let lifecycle = rebuild_lifecycle(
        &state,
        states,
        required,
        submitted,
        turn.timeout_streaks_by_player_id().clone(),
        turn.afk_player_ids().clone(),
        turn.kicked_player_ids().clone(),
        resigned,
        turn.turn_started_at().cloned(),
    )?;
    let outcome = resignation_outcome(identity, &active, command.player_id())?;
    let events = resignation_events(state.turn(), command.player_id(), outcome.as_ref());
    apply_update(
        state,
        lifecycle,
        None,
        Vec::new(),
        None,
        None,
        None,
        None,
        outcome,
        InteractionStateUpdate::Preserve,
        events,
        [TurnProcessor::Lifecycle],
        map_hash,
        ruleset_hash,
    )
}

fn active_players(state: &GameState) -> Vec<PlayerId> {
    let turn = state.match_lifecycle().turn();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| {
            !turn.kicked_player_ids().contains(*player)
                && !turn.resigned_player_ids().contains(*player)
        })
        .cloned()
        .collect()
}

fn resignation_outcome(
    identity: &MatchIdentity,
    active: &[PlayerId],
    resigning: &PlayerId,
) -> Result<Option<GameOutcome>, CanonicalEngineError> {
    if active.len() != 2 {
        return Ok(None);
    }
    active
        .iter()
        .find(|player| *player != resigning)
        .cloned()
        .map(|winner| crate::outcome::resignation_outcome(identity, winner))
        .transpose()
        .map_err(CanonicalEngineError::Outcome)
}

fn resignation_events(
    turn: u32,
    resigning: &PlayerId,
    outcome: Option<&GameOutcome>,
) -> Box<[DomainEvent]> {
    let mut events = vec![DomainEvent::PlayerResigned(PlayerResignedEvent::new(
        turn,
        resigning.clone(),
    ))];
    if let Some(outcome) = outcome {
        events.push(DomainEvent::MatchEnded(MatchEndedEvent::new(
            turn,
            outcome.clone(),
        )));
    }
    events.into_boxed_slice()
}
