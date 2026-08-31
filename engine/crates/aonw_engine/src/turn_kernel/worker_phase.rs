use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId};

use crate::{CanonicalEngineError, DomainEvent};

pub(super) struct WorkerPhase {
    pub(super) state: GameState,
    pub(super) events: Vec<DomainEvent>,
}

pub(super) fn advance_worker_phase(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<WorkerPhase, CanonicalEngineError> {
    let Some(update) = crate::worker::advance_workers(&state, map, ruleset, scope)
        .map_err(CanonicalEngineError::Worker)?
    else {
        return Ok(WorkerPhase {
            state,
            events: Vec::new(),
        });
    };
    let crate::worker::WorkerTurnUpdate {
        units,
        infrastructure,
        events,
    } = update;
    let revision = state.revision();
    let interaction = state.interaction().clone();
    let fog = state.fog_of_war().clone();
    let diplomacy = state.diplomacy().clone();
    let state = state
        .into_after_worker(revision, units, infrastructure, interaction, fog, diplomacy)
        .map_err(CanonicalEngineError::State)?;
    Ok(WorkerPhase { state, events })
}
