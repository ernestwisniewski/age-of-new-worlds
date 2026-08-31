use aonw_domain::{PendingInteraction, ResearchStateUpdate};

use super::rules::{player_research, selection_cost, validate_revision};
use super::{ResearchError, SelectTechnologyCommand};
use crate::{CommandRejectionCode, EngineContext, TechnologyAvailability, TechnologyUnlockQuery};

/// Atomic replacement produced by one research-selection command.
pub(crate) struct ResearchMutation {
    pub(crate) update: ResearchStateUpdate,
}

pub(crate) fn apply_select_technology(
    state: &aonw_domain::GameState,
    context: EngineContext<'_>,
    command: SelectTechnologyCommand,
) -> Result<ResearchMutation, ResearchError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    if !context.can_act() || !state.match_lifecycle().identity().contains(actor) {
        return Err(CommandRejectionCode::TechnologyPlayerNotControlled.into());
    }
    let current = player_research(state, actor);
    if TechnologyUnlockQuery::new(context.ruleset(), current).availability(command.technology())?
        != TechnologyAvailability::Available
    {
        return Err(CommandRejectionCode::TechnologyNotAvailable.into());
    }
    let cost = selection_cost(state, context, actor, command.technology())?;
    let selected = current.try_after_selecting(command.technology(), i64::from(cost / 2))?;
    let research = state.research().updating_player(actor.clone(), selected);
    let knowledge = state.knowledge().with_research(research);
    let interaction = match state.interaction().pending() {
        Some(PendingInteraction::ResearchSelection { owner_player_id })
            if owner_player_id == actor =>
        {
            state.interaction().clone().with_pending(None)
        }
        _ => state.interaction().clone(),
    };
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow)?;
    Ok(ResearchMutation {
        update: ResearchStateUpdate {
            revision,
            knowledge,
            interaction,
        },
    })
}
