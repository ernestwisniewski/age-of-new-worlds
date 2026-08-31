use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    FieldImprovement, GameState, InfrastructureState, PlayerId, TransportCondition,
    TransportNetwork, TransportSegment, Unit, WorkerJob,
};

use super::rules::{improvement_city, validate_road};
use crate::{DomainEvent, EngineContext, WorkerCompletedJobEvent, WorkerJobCompletion};

/// Atomic worker and infrastructure replacement produced by turn progression.
pub(crate) struct WorkerTurnUpdate {
    pub(crate) units: Vec<Unit>,
    pub(crate) infrastructure: InfrastructureState,
    pub(crate) events: Vec<DomainEvent>,
}

struct WorkerCompletion {
    replacement: Option<Unit>,
    event: Option<DomainEvent>,
}

pub(crate) fn advance_workers(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<Option<WorkerTurnUpdate>, Box<str>> {
    if !state.units().iter().any(|unit| {
        scope.contains(unit.owner_player_id()) && unit.activity().worker_job().is_some()
    }) {
        return Ok(None);
    }
    let mut units = state.units().to_vec();
    let mut improvements = state.field_improvements().to_vec();
    let mut roads = state.transport_network().segments().to_vec();
    let mut events = Vec::new();
    let mut index = 0;
    while index < units.len() {
        let unit = units[index].clone();
        if !scope.contains(unit.owner_player_id()) {
            index += 1;
            continue;
        }
        let Some(job) = unit.activity().worker_job().cloned() else {
            index += 1;
            continue;
        };
        if unit.position() != job.target() || map.tile_at(job.target()).is_none() {
            units[index] = unit.with_worker_job(None);
            index += 1;
            continue;
        }
        if job.remaining_turns() > 1 {
            units[index] =
                unit.with_worker_job(Some(job.with_remaining_turns(job.remaining_turns() - 1)));
            index += 1;
            continue;
        }
        let context =
            EngineContext::canonical(unit.owner_player_id(), map, ruleset).with_world(state);
        let completion = complete_job(state, context, &unit, &job, &mut improvements, &mut roads);
        if let Some(event) = completion.event {
            events.push(event);
        }
        if let Some(replacement) = completion.replacement {
            units[index] = replacement;
            index += 1;
        } else {
            units.remove(index);
        }
    }
    let network = TransportNetwork::try_new(roads)
        .map_err(|coordinate| format!("duplicate road at {coordinate:?}").into_boxed_str())?;
    let infrastructure = InfrastructureState::try_new(improvements, network)
        .map_err(|error| error.to_string().into_boxed_str())?;
    Ok(Some(WorkerTurnUpdate {
        units,
        infrastructure,
        events,
    }))
}

fn complete_job(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    job: &WorkerJob,
    improvements: &mut Vec<FieldImprovement>,
    roads: &mut Vec<TransportSegment>,
) -> WorkerCompletion {
    match job {
        WorkerJob::FieldImprovement {
            target,
            improvement,
            ..
        } => complete_improvement(state, context, unit, *target, *improvement, improvements),
        WorkerJob::RoadConstruction { target, .. } => {
            complete_road(state, context, unit, *target, roads)
        }
    }
}

fn complete_improvement(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: aonw_domain::HexCoord,
    improvement: aonw_domain::FieldImprovementKind,
    improvements: &mut Vec<FieldImprovement>,
) -> WorkerCompletion {
    if improvements
        .iter()
        .any(|value| value.coordinate() == target)
    {
        return cleared(unit);
    }
    let Ok(city) = improvement_city(state, context, unit, target, improvement, false) else {
        return cleared(unit);
    };
    improvements.push(FieldImprovement::new(
        target,
        improvement,
        Some(city.id().clone()),
    ));
    let event = DomainEvent::WorkerCompletedJob(WorkerCompletedJobEvent::new(
        unit.id().clone(),
        target,
        WorkerJobCompletion::FieldImprovement(improvement),
    ));
    WorkerCompletion {
        replacement: unit.after_worker_improvement_completed(),
        event: Some(event),
    }
}

fn complete_road(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: aonw_domain::HexCoord,
    roads: &mut Vec<TransportSegment>,
) -> WorkerCompletion {
    if roads.iter().any(|segment| segment.coordinate() == target)
        || validate_road(state, context, unit, target, false).is_err()
    {
        return cleared(unit);
    }
    let city_id = state
        .cities()
        .iter()
        .find(|city| city.owner_player_id() == unit.owner_player_id() && city.controls(target))
        .map(|city| city.id().clone());
    roads.push(TransportSegment::road(
        target,
        TransportCondition::Operational,
        unit.owner_player_id().clone(),
        city_id,
    ));
    let event = DomainEvent::WorkerCompletedJob(WorkerCompletedJobEvent::new(
        unit.id().clone(),
        target,
        WorkerJobCompletion::Road,
    ));
    WorkerCompletion {
        replacement: Some(unit.with_worker_job(None)),
        event: Some(event),
    }
}

fn cleared(unit: &Unit) -> WorkerCompletion {
    WorkerCompletion {
        replacement: Some(unit.with_worker_job(None)),
        event: None,
    }
}
