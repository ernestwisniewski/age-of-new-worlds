use std::collections::BTreeSet;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{CityId, GameState, PlayerId};

use crate::{CanonicalEngineError, CombatExecution, CombatTarget, DomainEvent};

use super::city_phase::advance_city_phase;
use super::worker_phase::advance_worker_phase;

struct SettlementPhase {
    state: GameState,
    events: Vec<DomainEvent>,
    founded_city_ids: Vec<CityId>,
}

pub(super) struct TurnPreparationPhase {
    pub(super) state: GameState,
    pub(super) events: Vec<DomainEvent>,
    pub(super) research_events: Vec<DomainEvent>,
    pub(super) founded_city_ids: Vec<CityId>,
}

pub(super) struct SimultaneousPreparationPhase {
    pub(super) turn: TurnPreparationPhase,
    pub(super) combat_events: Box<[DomainEvent]>,
    pub(super) combat_executions: Box<[CombatExecution]>,
    pub(super) weariness_counts: crate::economy::WarWearinessEventCounts,
}

fn advance_settlement_phase(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<SettlementPhase, CanonicalEngineError> {
    let city = advance_city_phase(state, map, ruleset, scope)?;
    let mut events = city.events;
    let founded_city_ids = city.founded_city_ids;
    let worker = advance_worker_phase(city.state, map, ruleset, scope)?;
    events.extend(worker.events);
    Ok(SettlementPhase {
        state: worker.state,
        events,
        founded_city_ids,
    })
}

pub(super) fn advance_turn_preparation(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
    attacked_city_ids: &BTreeSet<CityId>,
) -> Result<TurnPreparationPhase, CanonicalEngineError> {
    let settlement = advance_settlement_phase(state, map, ruleset, scope)?;
    let economy = crate::economy::prepare_turn_economy(
        settlement.state,
        map,
        ruleset,
        scope,
        attacked_city_ids,
    )
    .map_err(|error| CanonicalEngineError::Economy(error.to_string().into()))?;
    let production = crate::production::advance_turn_production(economy, map, ruleset, scope)
        .map_err(CanonicalEngineError::Production)?;
    let artifacts = crate::artifact::advance_turn_artifacts(production.state, scope)
        .map_err(CanonicalEngineError::Artifact)?;
    let research = crate::research::advance_turn_research(
        artifacts.state,
        map,
        ruleset,
        scope,
        &production.research_project_science,
    )
    .map_err(CanonicalEngineError::Research)?;
    let mut events = settlement.events;
    events.extend(production.events);
    events.extend(artifacts.events);
    Ok(TurnPreparationPhase {
        state: research.state,
        events,
        research_events: research.events,
        founded_city_ids: settlement.founded_city_ids,
    })
}

pub(super) fn advance_simultaneous_preparation(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<SimultaneousPreparationPhase, CanonicalEngineError> {
    let combat_owners = crate::economy::CombatEconomyOwnerIndex::from_state(&state);
    let combat =
        crate::combat::resolve_intended_attacks(state, map, ruleset).map_err(
            |error| match error {
                crate::combat::CombatPhaseError::Diplomacy(source) => {
                    CanonicalEngineError::Diplomacy(source)
                }
                crate::combat::CombatPhaseError::State(source) => {
                    CanonicalEngineError::State(source)
                }
            },
        )?;
    let attacked_city_ids = combat
        .events
        .iter()
        .filter_map(|event| match event {
            DomainEvent::CombatResolved(value) => match value.target() {
                CombatTarget::City(city_id) => Some(city_id.clone()),
                CombatTarget::Unit(_) => None,
            },
            _ => None,
        })
        .collect::<BTreeSet<_>>();
    let weariness_counts =
        crate::economy::WarWearinessEventCounts::from_combat(&combat_owners, &combat.events)
            .map_err(|error| CanonicalEngineError::Economy(error.to_string().into()))?;
    let turn = advance_turn_preparation(combat.state, map, ruleset, scope, &attacked_city_ids)?;
    Ok(SimultaneousPreparationPhase {
        turn,
        combat_events: combat.events,
        combat_executions: combat.executions,
        weariness_counts,
    })
}
