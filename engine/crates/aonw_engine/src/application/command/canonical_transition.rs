use aonw_content::ContentHash;
use aonw_domain::GameState;

use super::CanonicalEngineError;
use crate::application::{DomainEvent, DomainTransition, ExecutionEvidence};

pub(super) fn apply_artifact(
    state: GameState,
    mutation: Result<crate::artifact::ArtifactMutation, crate::ArtifactError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::ArtifactError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(error) => return Err(CanonicalEngineError::Artifact(error)),
    };
    let next = state
        .into_after_artifact(mutation.update)
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next,
        mutation.events,
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_research(
    state: GameState,
    mutation: Result<crate::research::ResearchMutation, crate::ResearchError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::ResearchError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(error) => return Err(CanonicalEngineError::Research(error)),
    };
    let next = state
        .into_after_research(mutation.update)
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_diplomacy(
    state: GameState,
    mutation: Result<crate::diplomacy::DiplomacyMutation, crate::DiplomacyError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::DiplomacyError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(error) => return Err(CanonicalEngineError::DiplomacyCommand(error)),
    };
    let next = state
        .into_after_diplomacy(mutation.update)
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next,
        mutation.events,
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_worker(
    state: GameState,
    mutation: Result<crate::worker::WorkerMutation, crate::worker::WorkerRuleError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::worker::WorkerRuleError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let (next, events, evidence) = match mutation {
        crate::worker::WorkerMutation::Update(update) => {
            let next = state
                .into_after_worker(
                    update.revision,
                    update.units,
                    update.infrastructure,
                    update.interaction,
                    update.fog_of_war,
                    update.diplomacy,
                )
                .map_err(CanonicalEngineError::State)?;
            (next, update.events, update.evidence)
        }
    };
    Ok(DomainTransition::accepted(
        next,
        events,
        evidence,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_city(
    state: GameState,
    mutation: Result<crate::city::CityMutation, crate::city::CityRuleError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::city::CityRuleError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(crate::city::CityRuleError::Technology(error)) => {
            return Err(CanonicalEngineError::Technology(error));
        }
    };
    let next = match mutation {
        crate::city::CityMutation::Identity => state,
        crate::city::CityMutation::Update(update) => state
            .into_after_city(
                update.revision,
                update.units,
                update.cities,
                update.interaction,
                update.fog_of_war,
                update.diplomacy,
            )
            .map_err(CanonicalEngineError::State)?,
    };
    Ok(DomainTransition::accepted(
        next,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_production(
    state: GameState,
    mutation: Result<crate::production::ProductionMutation, crate::ProductionError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::ProductionError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(error) => return Err(CanonicalEngineError::Production(error)),
    };
    let (next, events) = match mutation {
        crate::production::ProductionMutation::Identity => (state, Vec::new().into_boxed_slice()),
        crate::production::ProductionMutation::Update { update, events } => (
            state
                .into_after_production(*update)
                .map_err(CanonicalEngineError::State)?,
            events,
        ),
    };
    Ok(DomainTransition::accepted(
        next,
        events,
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_combat(
    state: GameState,
    update: Result<crate::combat::CombatUpdate, crate::combat::CombatApplyError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match update {
        Ok(value) => value,
        Err(crate::combat::CombatApplyError::Rejected(rejection)) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(crate::combat::CombatApplyError::Diplomacy(error)) => {
            return Err(CanonicalEngineError::Diplomacy(error));
        }
    };
    let next = state
        .into_after_combat(aonw_domain::CombatStateUpdate {
            revision: update.revision,
            units: update.units,
            cities: update.cities,
            artifacts: update.artifacts,
            combat: update.combat,
            fog_of_war: update.fog_of_war,
            diplomacy: update.diplomacy,
        })
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next,
        update.events,
        Some(ExecutionEvidence::Combat(update.evidence)),
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_move(
    state: GameState,
    map: &aonw_content::MapDefinition,
    movement: Result<crate::movement::MovementTransition, crate::MoveUnitError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let movement = match movement {
        Ok(value) => value,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let updated_unit = movement.unit().clone();
    let next_revision = movement.revision();
    let mut fog = state.fog_of_war().clone();
    let mut diplomacy = state.diplomacy().clone();
    if movement.event().is_some() {
        fog = crate::movement::recompute_after_unit_move(
            &fog,
            map,
            &updated_unit,
            state.units(),
            state.cities(),
        );
        diplomacy = crate::movement::merge_discovered_contacts_after_unit_move(
            &diplomacy,
            &fog,
            &updated_unit,
            state.units(),
            state.cities(),
        );
    }
    let next_state = state
        .into_after_movement(next_revision, updated_unit, fog, diplomacy)
        .map_err(CanonicalEngineError::State)?;
    let events = movement
        .event()
        .cloned()
        .map(DomainEvent::UnitMoved)
        .into_iter()
        .collect::<Vec<_>>()
        .into_boxed_slice();
    let evidence = movement
        .execution()
        .cloned()
        .map(ExecutionEvidence::UnitMovement);
    Ok(DomainTransition::accepted(
        next_state,
        events,
        evidence,
        map_hash,
        ruleset_hash,
    ))
}
