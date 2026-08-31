use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    Diplomacy, EconomyState, GameOutcome, GameState, ObjectiveState, PlayerId, Unit,
};

use crate::{CanonicalEngineError, DomainEvent, MatchEndedEvent};

use super::agreement_phase::settle_resource_trades;
use super::diplomacy_phase::advance_turn_diplomacy;
use super::objective_phase::advance_turn_objectives;

pub(super) struct FinalTurnPhases {
    pub(super) economy: EconomyState,
    pub(super) diplomacy: Diplomacy,
    pub(super) objectives: ObjectiveState,
    pub(super) outcome: GameOutcome,
    pub(super) diplomacy_events: Vec<DomainEvent>,
    pub(super) objective_events: Vec<DomainEvent>,
    pub(super) stability_events: Vec<DomainEvent>,
    pub(super) outcome_events: Vec<DomainEvent>,
}

#[allow(clippy::too_many_arguments)]
pub(super) fn advance_final_turn_phases(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    diplomacy: Diplomacy,
    scope: &[PlayerId],
    turn: u32,
    weariness_counts: &mut crate::economy::WarWearinessEventCounts,
) -> Result<FinalTurnPhases, CanonicalEngineError> {
    let diplomacy_phase = advance_turn_diplomacy(state, ruleset, units, diplomacy, turn)
        .map_err(CanonicalEngineError::DiplomacyCommand)?;
    let (economy, diplomacy) =
        settle_resource_trades(state, ruleset, diplomacy_phase.diplomacy, scope)
            .map_err(CanonicalEngineError::DiplomacyCommand)?;
    let objective_phase = advance_turn_objectives(state, map, economy, units, scope)?;
    weariness_counts.include_diplomacy_events(&diplomacy_phase.events);
    let stability_phase = crate::economy::advance_turn_stability(
        state,
        map,
        ruleset,
        &objective_phase.economy,
        &diplomacy,
        scope,
        turn,
        weariness_counts,
    )
    .map_err(|error| CanonicalEngineError::Economy(error.to_string().into()))?;
    let outcome = crate::outcome::resolve_game_outcome_after_turn(
        state,
        map,
        ruleset,
        units,
        &stability_phase.economy,
        &objective_phase.objectives,
        turn,
    )
    .map_err(CanonicalEngineError::Outcome)?;
    let outcome_events = if !state.outcome().is_terminal() && outcome.is_terminal() {
        vec![DomainEvent::MatchEnded(MatchEndedEvent::new(
            turn,
            outcome.clone(),
        ))]
    } else {
        Vec::new()
    };
    Ok(FinalTurnPhases {
        economy: stability_phase.economy,
        diplomacy,
        objectives: objective_phase.objectives,
        outcome,
        diplomacy_events: diplomacy_phase.events,
        objective_events: objective_phase.events,
        stability_events: stability_phase.events,
        outcome_events,
    })
}
