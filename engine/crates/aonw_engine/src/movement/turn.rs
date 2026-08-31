use std::collections::BTreeSet;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    Diplomacy, FogOfWar, GameState, InteractionState, PlayerId, Unit, UnitKind, UnitPosture,
};

use super::auto_explore::plan_auto_explore_for_world;
use super::fog::{merge_discovered_contacts, recompute_after_move};
use super::merchant::{MerchantPlanKind, plan_to_city, route_from_plan};
use super::query::plan_route_for_unit;
use super::transition::{movement_from_plan, reachable_path_hits_hidden_blocker};
use super::{
    MovementSearchWorkspace, UnitMovedEvent, UnitMovementExecution, maximum_movement_units,
};
use crate::{DomainEvent, EngineContext};

pub(crate) struct TurnMovementUpdate {
    pub(crate) units: Vec<Unit>,
    pub(crate) fog_of_war: FogOfWar,
    pub(crate) diplomacy: Diplomacy,
    pub(crate) interaction: InteractionState,
    pub(crate) events: Vec<DomainEvent>,
    pub(crate) executions: Vec<UnitMovementExecution>,
    pub(crate) reset_unit_ids: Vec<aonw_domain::UnitId>,
    pub(crate) invalidated_order_unit_ids: Vec<aonw_domain::UnitId>,
    pub(crate) finished_auto_explore_unit_ids: Vec<aonw_domain::UnitId>,
}

struct MovementProgress {
    units: Vec<Unit>,
    fog: FogOfWar,
    diplomacy: Diplomacy,
    events: Vec<DomainEvent>,
    executions: Vec<UnitMovementExecution>,
    reset_unit_ids: Vec<aonw_domain::UnitId>,
    invalidated_order_unit_ids: Vec<aonw_domain::UnitId>,
}

pub(crate) fn advance_turn_movement(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    player_ids: &[PlayerId],
) -> Result<TurnMovementUpdate, crate::CommandRejectionCode> {
    let scope = player_ids.iter().cloned().collect::<BTreeSet<_>>();
    let mut progress = reset_and_advance_orders(state, map, ruleset, &scope, player_ids)?;
    let mut workspace = MovementSearchWorkspace::default();
    let mut finished_auto_explore_unit_ids = Vec::new();
    let mut interaction = state.interaction().clone().expire_turn_skip_for(&scope);
    advance_worker_automation(state, map, ruleset, &scope, &mut progress, &mut interaction)?;
    for index in 0..progress.units.len() {
        let scout = progress.units[index].clone();
        if !scope.contains(scout.owner_player_id())
            || scout.kind() != UnitKind::Scout
            || scout.posture() != UnitPosture::AutoExploring
            || !scout.movement_units().is_positive()
            || scout.queued_path().is_some()
        {
            continue;
        }
        let context = movement_context(
            &scout,
            map,
            ruleset,
            state,
            &progress.fog,
            &progress.diplomacy,
        );
        let planned = plan_auto_explore_for_world(
            state.revision().get(),
            &progress.units,
            state.cities(),
            &progress.fog,
            &progress.diplomacy,
            state.match_lifecycle().identity(),
            state.transport_network(),
            context,
            &scout,
            &mut workspace,
        );
        let Ok(planned) = planned else {
            progress.units[index] = scout.after_auto_explore_finished();
            interaction = interaction.without_unit(scout.id());
            finished_auto_explore_unit_ids.push(scout.id().clone());
            continue;
        };
        if reachable_path_hits_hidden_blocker(
            &progress.units,
            &scout,
            planned.route.reachable_steps(),
            context,
        ) {
            progress.units[index] = scout.after_auto_explore_finished();
            interaction = interaction.without_unit(scout.id());
            finished_auto_explore_unit_ids.push(scout.id().clone());
            continue;
        }
        let movement = movement_from_plan(
            &scout,
            &planned.route,
            state.revision(),
            true,
            UnitPosture::AutoExploring,
        )
        .map_err(|error| error.code())?;
        let execution = movement.execution().cloned();
        progress.units[index] = movement.unit().clone();
        interaction = interaction.without_unit(scout.id());
        record_movement(&mut progress.events, &mut progress.executions, execution);
        recompute_scope_fog(
            &mut progress.fog,
            &mut progress.diplomacy,
            map,
            state,
            &progress.units,
            &[scout.owner_player_id().clone()],
        );
    }
    Ok(TurnMovementUpdate {
        units: progress.units,
        fog_of_war: progress.fog,
        diplomacy: progress.diplomacy,
        interaction,
        events: progress.events,
        executions: progress.executions,
        reset_unit_ids: progress.reset_unit_ids,
        invalidated_order_unit_ids: progress.invalidated_order_unit_ids,
        finished_auto_explore_unit_ids,
    })
}

fn advance_worker_automation(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &BTreeSet<PlayerId>,
    progress: &mut MovementProgress,
    interaction: &mut InteractionState,
) -> Result<(), crate::CommandRejectionCode> {
    let worker_ids = progress
        .units
        .iter()
        .filter(|unit| {
            scope.contains(unit.owner_player_id())
                && unit.kind() == UnitKind::Worker
                && unit.posture() == UnitPosture::AutoWorking
        })
        .map(|unit| unit.id().clone())
        .collect::<Vec<_>>();
    if worker_ids.is_empty() {
        return Ok(());
    }
    let mut temporary = state
        .clone()
        .into_after_worker(
            state.revision(),
            core::mem::take(&mut progress.units),
            state.infrastructure().clone(),
            core::mem::take(interaction),
            core::mem::take(&mut progress.fog),
            core::mem::take(&mut progress.diplomacy),
        )
        .map_err(|_| crate::CommandRejectionCode::InvalidUnit)?;
    for worker_id in worker_ids {
        let current = temporary
            .unit(&worker_id)
            .cloned()
            .ok_or(crate::CommandRejectionCode::WorkerNotFound)?;
        let context = EngineContext::canonical(current.owner_player_id(), map, ruleset);
        let command = crate::AutomateWorkerCommand::new(state.revision().get(), &worker_id);
        let mutation = crate::worker::apply_automation(&temporary, context, command);
        let Ok(crate::worker::WorkerMutation::Update(update)) = mutation else {
            let replacement = current.after_worker_automation_finished();
            let next_interaction = temporary.interaction().clone().without_unit(&worker_id);
            temporary = temporary
                .into_after_unit_action(state.revision(), replacement, next_interaction, None)
                .map_err(|_| crate::CommandRejectionCode::InvalidUnit)?;
            continue;
        };
        let crate::worker::WorkerUpdate {
            units,
            infrastructure,
            interaction: next_interaction,
            fog_of_war,
            diplomacy,
            events,
            evidence,
            ..
        } = *update;
        progress.events.extend(events);
        if let Some(crate::ExecutionEvidence::WorkerAutomation(execution)) = evidence
            && let Some(movement) = execution.movement().cloned()
        {
            progress.executions.push(movement);
        }
        temporary = temporary
            .into_after_worker(
                state.revision(),
                units,
                infrastructure,
                next_interaction,
                fog_of_war,
                diplomacy,
            )
            .map_err(|_| crate::CommandRejectionCode::InvalidUnit)?;
    }
    progress.units = temporary.units().to_vec();
    progress.fog = temporary.fog_of_war().clone();
    progress.diplomacy = temporary.diplomacy().clone();
    *interaction = temporary.interaction().clone();
    Ok(())
}

fn reset_and_advance_orders(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &BTreeSet<PlayerId>,
    player_ids: &[PlayerId],
) -> Result<MovementProgress, crate::CommandRejectionCode> {
    if state
        .units()
        .iter()
        .filter(|unit| scope.contains(unit.owner_player_id()))
        .any(|unit| ruleset.unit(unit.kind()).is_none())
    {
        return Err(crate::CommandRejectionCode::UnitDefinitionMissing);
    }
    let mut reset_unit_ids = Vec::new();
    let mut units = state
        .units()
        .iter()
        .map(|unit| {
            if !scope.contains(unit.owner_player_id()) {
                return unit.clone();
            }
            reset_unit_ids.push(unit.id().clone());
            unit.after_turn_movement_reset(maximum_movement_units(
                ruleset,
                unit.kind(),
                unit.carried_artifact_id().is_some(),
            ))
        })
        .collect::<Vec<_>>();
    let mut fog = state.fog_of_war().clone();
    let mut diplomacy = state.diplomacy().clone();
    let mut events = Vec::new();
    let mut executions = Vec::new();
    let mut invalidated_order_unit_ids = Vec::new();
    for index in 0..units.len() {
        if !scope.contains(units[index].owner_player_id()) {
            continue;
        }
        let original = units[index].clone();
        let context = movement_context(&original, map, ruleset, state, &fog, &diplomacy);
        let (updated, execution, invalidated) = if original.merchant_trade_route().is_some() {
            advance_merchant(state.revision().get(), &units, state, context, &original)
        } else if original.queued_path().is_some() && original.posture() != UnitPosture::AutoWorking
        {
            advance_queued(state.revision().get(), &units, context, &original)
        } else {
            (original, None, false)
        };
        if invalidated {
            invalidated_order_unit_ids.push(updated.id().clone());
        }
        record_movement(&mut events, &mut executions, execution);
        units[index] = updated;
    }
    recompute_scope_fog(&mut fog, &mut diplomacy, map, state, &units, player_ids);
    Ok(MovementProgress {
        units,
        fog,
        diplomacy,
        events,
        executions,
        reset_unit_ids,
        invalidated_order_unit_ids,
    })
}

fn advance_queued(
    revision: u64,
    units: &[Unit],
    context: EngineContext<'_>,
    unit: &Unit,
) -> (Unit, Option<UnitMovementExecution>, bool) {
    let Some(path) = unit.queued_path() else {
        return (unit.clone(), None, false);
    };
    let planning_context = if unit.kind() == UnitKind::Merchant {
        context.with_owned_city_stacking()
    } else {
        context
    };
    let plan = plan_route_for_unit(
        revision,
        units,
        planning_context.with_unrestricted_hidden_pathing(),
        unit,
        path.target(),
        unit.movement_units(),
        false,
    );
    let Ok(plan) = plan else {
        return (unit.without_queued_path(), None, true);
    };
    if reachable_path_hits_hidden_blocker(units, unit, plan.reachable_steps(), context) {
        return (unit.clone(), None, false);
    }
    movement_from_plan(
        unit,
        &plan,
        aonw_domain::StateRevision::new(revision),
        true,
        unit.posture(),
    )
    .map_or_else(
        |_| (unit.without_queued_path(), None, true),
        |movement| {
            (
                movement.unit().clone(),
                movement.execution().cloned(),
                false,
            )
        },
    )
}

fn advance_merchant(
    revision: u64,
    units: &[Unit],
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
) -> (Unit, Option<UnitMovementExecution>, bool) {
    let Some(saved) = unit.merchant_trade_route() else {
        return (unit.clone(), None, false);
    };
    if unit.kind() != UnitKind::Merchant
        || unit.activity().blocks_manual_movement()
        || unit.posture() == UnitPosture::Fortified
    {
        return (unit.without_merchant_route(), None, true);
    }
    let Some(mut origin) = state.city(saved.origin_city_id()) else {
        return (unit.without_merchant_route(), None, true);
    };
    let Some(mut destination) = state.city(saved.destination_city_id()) else {
        return (unit.without_merchant_route(), None, true);
    };
    if origin.owner_player_id() != unit.owner_player_id()
        || destination.owner_player_id() != unit.owner_player_id()
        || origin.id() == destination.id()
    {
        return (unit.without_merchant_route(), None, true);
    }
    if unit.position() == destination.center() {
        core::mem::swap(&mut origin, &mut destination);
    }
    let plan = plan_to_city(
        revision,
        units,
        context,
        unit,
        destination,
        MerchantPlanKind::CyclicRoute,
    );
    let Ok(plan) = plan else {
        return (unit.without_merchant_route(), None, true);
    };
    if reachable_path_hits_hidden_blocker(units, unit, plan.reachable_steps(), context) {
        return (unit.clone(), None, false);
    }
    let Ok(movement) = movement_from_plan(
        unit,
        &plan,
        aonw_domain::StateRevision::new(revision),
        false,
        UnitPosture::Active,
    ) else {
        return (unit.without_merchant_route(), None, true);
    };
    let mut updated = movement.unit().clone();
    let route = if updated.position() == destination.center() {
        match plan_to_city(
            revision,
            units,
            context,
            &updated,
            origin,
            MerchantPlanKind::CyclicRoute,
        ) {
            Ok(reverse) => route_from_plan(
                context,
                destination.id().clone(),
                origin.id().clone(),
                &reverse,
            ),
            Err(_) => {
                return (
                    updated.without_merchant_route(),
                    movement.execution().cloned(),
                    true,
                );
            }
        }
    } else {
        route_from_plan(
            context,
            origin.id().clone(),
            destination.id().clone(),
            &plan,
        )
    };
    updated = updated.after_merchant_route_assigned(route);
    (updated, movement.execution().cloned(), false)
}

#[allow(clippy::too_many_arguments)]
fn movement_context<'world>(
    unit: &'world Unit,
    map: &'world MapDefinition,
    ruleset: &'world RulesetDefinition,
    state: &'world GameState,
    fog: &'world FogOfWar,
    diplomacy: &'world Diplomacy,
) -> EngineContext<'world> {
    EngineContext::canonical(unit.owner_player_id(), map, ruleset).with_movement_world(
        state.cities(),
        fog,
        diplomacy,
        state.transport_network(),
        state.match_lifecycle().identity(),
    )
}

fn record_movement(
    events: &mut Vec<DomainEvent>,
    executions: &mut Vec<UnitMovementExecution>,
    execution: Option<UnitMovementExecution>,
) {
    let Some(execution) = execution else {
        return;
    };
    let Some(last) = execution.steps().last() else {
        return;
    };
    events.push(DomainEvent::UnitMoved(UnitMovedEvent::new(
        execution.unit_id().clone(),
        execution.from(),
        last.coordinate(),
    )));
    executions.push(execution);
}

fn recompute_scope_fog(
    fog: &mut FogOfWar,
    diplomacy: &mut Diplomacy,
    map: &MapDefinition,
    state: &GameState,
    units: &[Unit],
    player_ids: &[PlayerId],
) {
    let refs = units.iter().collect::<Vec<_>>();
    for player_id in player_ids {
        *fog = recompute_after_move(fog, map, player_id, &refs, state.cities());
    }
    *diplomacy = merge_discovered_contacts(diplomacy, fog, &refs, state.cities());
}
