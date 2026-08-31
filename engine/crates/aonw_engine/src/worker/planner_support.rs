use std::collections::BTreeSet;

use aonw_domain::{City, GameState, HexCoord, Unit, UnitPosture};

use crate::EngineContext;

pub(super) fn automation_assignment_capacity(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    city: &City,
) -> bool {
    let assigned = state
        .units()
        .iter()
        .filter(|other| {
            other.id() != unit.id()
                && other.owner_player_id() == unit.owner_player_id()
                && other
                    .activity()
                    .worker_assignment()
                    .is_some_and(|coordinate| city.controls(coordinate))
        })
        .count();
    let reserved = state
        .units()
        .iter()
        .filter(|other| {
            other.id() != unit.id()
                && other.owner_player_id() == unit.owner_player_id()
                && other.posture() == UnitPosture::AutoWorking
                && other.queued_path().is_some_and(|path| {
                    city.controls(path.target())
                        && state
                            .infrastructure()
                            .field_improvement_at(path.target())
                            .is_some()
                })
        })
        .count();
    let limit = usize::try_from(
        context
            .ruleset()
            .worker()
            .assignment_limit(city.population()),
    )
    .unwrap_or(usize::MAX);
    assigned.saturating_add(reserved) < limit
}

pub(super) fn reserved_coordinates(state: &GameState, unit: &Unit) -> BTreeSet<HexCoord> {
    let mut reserved = BTreeSet::new();
    for other in state.units().iter().filter(|other| {
        other.id() != unit.id() && other.owner_player_id() == unit.owner_player_id()
    }) {
        if let Some(job) = other.activity().worker_job() {
            reserved.insert(job.target());
        }
        if let Some(target) = other.activity().worker_assignment() {
            reserved.insert(target);
        }
        if other.posture() == UnitPosture::AutoWorking
            && let Some(path) = other.queued_path()
        {
            reserved.insert(path.target());
        }
    }
    reserved
}

pub(super) fn optionless_interaction(
    state: &GameState,
    unit: &Unit,
) -> aonw_domain::InteractionState {
    if state
        .interaction()
        .pending()
        .and_then(aonw_domain::PendingInteraction::unit_id)
        == Some(unit.id())
    {
        state.interaction().clone().with_pending(None)
    } else {
        state.interaction().clone()
    }
}
