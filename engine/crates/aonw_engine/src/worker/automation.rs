use std::cmp::Ordering;

use aonw_domain::{City, GameState, HexCoord, Unit, UnitKind, UnitPosture};

use super::model::{
    AutomateWorkerCommand, WorkerAutomationAction, WorkerAutomationExecution,
    WorkerAutomationMetrics, WorkerAutomationOption,
};
use super::planner_support::{
    automation_assignment_capacity, optionless_interaction, reserved_coordinates,
};
use super::rules::{
    WorkerMutation, WorkerRuleError, WorkerUpdate, improvement_city, start_improvement,
};
use super::score::{assignment_score, improvement_score};
use crate::movement::{
    find_route_costs, movement_from_plan, plan_route_for_unit, reachable_path_hits_hidden_blocker,
};
use crate::{
    CommandRejectionCode, DomainEvent, EngineContext, ExecutionEvidence, UnitMovementExecution,
};

#[derive(Clone, Debug)]
struct Candidate {
    option: WorkerAutomationOption,
    score: i64,
    build_turns: u32,
    city_id: aonw_domain::CityId,
    improvement_rank: usize,
}

#[derive(Clone, Copy)]
struct ReachableTarget<'state> {
    city: &'state City,
    coordinate: HexCoord,
    movement_cost: u32,
}

impl Candidate {
    fn compare_preference(&self, other: &Self) -> Ordering {
        other
            .option
            .movement_cost_units()
            .cmp(&self.option.movement_cost_units())
            .then_with(|| self.score.cmp(&other.score))
            .then_with(|| other.build_turns.cmp(&self.build_turns))
            .then_with(|| other.city_id.cmp(&self.city_id))
            .then_with(|| other.option.target().cmp(&self.option.target()))
            .then_with(|| other.improvement_rank.cmp(&self.improvement_rank))
    }
}

pub(super) fn plan_automation(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
) -> Result<WorkerAutomationOption, WorkerRuleError> {
    validate_worker(context, unit, unit.posture() == UnitPosture::AutoWorking)?;
    compute_automation_plan(state, context, unit)
}

fn compute_automation_plan(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
) -> Result<WorkerAutomationOption, WorkerRuleError> {
    let reserved = reserved_coordinates(state, unit);
    let planning_context = context
        .with_world(state)
        .with_unrestricted_hidden_pathing()
        .with_excluded_path_hexes(&reserved);
    let balance = context.ruleset().worker();
    let mut metrics = WorkerAutomationMetrics::default();
    let mut owned_cities = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == unit.owner_player_id())
        .collect::<Vec<_>>();
    owned_cities.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    let mut examined = Vec::new();
    'cities: for city in owned_cities {
        let mut targets = city.controlled_hexes().to_vec();
        targets.sort_unstable();
        for target in targets {
            if metrics.tiles_examined() >= balance.automation_tile_budget() {
                break 'cities;
            }
            metrics.tile();
            if reserved.contains(&target) {
                continue;
            }
            examined.push((city, target));
        }
    }
    let route_targets = examined
        .iter()
        .filter_map(|(_, target)| (*target != unit.position()).then_some(*target))
        .collect::<Vec<_>>();
    for _ in &route_targets {
        metrics.route();
    }
    let route_costs = find_route_costs(
        state.units(),
        context.map(),
        unit,
        &route_targets,
        unit.movement_units(),
        planning_context,
    );
    let reachable = examined
        .into_iter()
        .filter_map(|(city, coordinate)| {
            let movement_cost = if coordinate == unit.position() {
                0
            } else {
                route_costs.cost_at(context.map(), coordinate)?
            };
            Some(ReachableTarget {
                city,
                coordinate,
                movement_cost,
            })
        })
        .collect::<Vec<_>>();

    let build = (unit.worker_build_charges() > 0)
        .then(|| best_build(state, planning_context, unit, &reachable, &mut metrics))
        .flatten();
    let candidate =
        build.or_else(|| best_assignment(state, planning_context, unit, &reachable, &mut metrics));
    let option = candidate
        .ok_or(CommandRejectionCode::WorkerAutomationNoTarget)?
        .option;
    Ok(WorkerAutomationOption::new(
        option.target(),
        option.action(),
        option.movement_cost_units(),
        metrics,
    ))
}

pub(crate) fn apply_automation(
    state: &GameState,
    context: EngineContext<'_>,
    command: AutomateWorkerCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    if state.revision().get() != command.expected_revision() {
        return Err(CommandRejectionCode::StaleRevision.into());
    }
    let unit = state
        .unit(command.unit_id())
        .ok_or(CommandRejectionCode::WorkerNotFound)?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::WorkerNotControlled.into());
    }
    let continuation = unit.posture() == UnitPosture::AutoWorking;
    validate_worker(context, unit, continuation)?;
    let option = match plan_automation(state, context.with_world(state), unit) {
        Ok(value) => value,
        Err(WorkerRuleError::Rejected(CommandRejectionCode::WorkerAutomationNoTarget))
            if continuation =>
        {
            return update_automation_unit(
                state,
                unit.after_worker_automation_finished(),
                optionless_interaction(state, unit),
                Box::new([]),
                None,
            );
        }
        Err(error) => return Err(error),
    };
    if option.target() == unit.position() {
        let mutation = match option.action() {
            WorkerAutomationAction::Improve(improvement) => {
                start_improvement(state, context, unit.id(), improvement)?
            }
            WorkerAutomationAction::Assign => super::rules::apply_assign(
                state,
                context,
                super::AssignWorkerToHexCommand::new(state.revision().get(), unit.id()),
            )?,
        };
        return Ok(with_execution(mutation, unit.id().clone(), option, None));
    }

    move_toward_automation_target(state, context, unit, option)
}

fn move_toward_automation_target(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    option: WorkerAutomationOption,
) -> Result<WorkerMutation, WorkerRuleError> {
    let reserved = reserved_coordinates(state, unit);
    let planning_context = context
        .with_world(state)
        .with_unrestricted_hidden_pathing()
        .with_excluded_path_hexes(&reserved);
    let route = plan_route_for_unit(
        state.revision().get(),
        state.units(),
        planning_context,
        unit,
        option.target(),
        unit.movement_units(),
        false,
    )
    .map_err(|error| WorkerRuleError::Rejected(error.code()))?;
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow)?;
    let primed = unit.after_worker_automation_started();
    let movement = if reachable_path_hits_hidden_blocker(
        state.units(),
        &primed,
        route.reachable_steps(),
        planning_context,
    ) {
        None
    } else {
        Some(
            movement_from_plan(&primed, &route, revision, true, UnitPosture::AutoWorking)
                .map_err(|error| WorkerRuleError::Rejected(error.code()))?,
        )
    };
    let updated = movement
        .as_ref()
        .map_or_else(|| primed.clone(), |value| value.unit().clone());
    let mut units = state.units().to_vec();
    *units
        .iter_mut()
        .find(|candidate| candidate.id() == unit.id())
        .ok_or(CommandRejectionCode::WorkerNotFound)? = updated;
    let refs = units.iter().collect::<Vec<_>>();
    let fog = crate::movement::recompute_after_move(
        state.fog_of_war(),
        context.map(),
        unit.owner_player_id(),
        &refs,
        state.cities(),
    );
    let diplomacy =
        crate::movement::merge_discovered_contacts(state.diplomacy(), &fog, &refs, state.cities());
    let events = movement
        .as_ref()
        .and_then(|value| value.event())
        .cloned()
        .map(DomainEvent::UnitMoved)
        .into_iter()
        .collect::<Vec<_>>()
        .into_boxed_slice();
    let execution = WorkerAutomationExecution::new(
        unit.id().clone(),
        option,
        movement.and_then(|value| value.execution().cloned()),
    );
    Ok(WorkerMutation::Update(Box::new(WorkerUpdate {
        revision,
        units,
        infrastructure: state.infrastructure().clone(),
        interaction: optionless_interaction(state, unit),
        fog_of_war: fog,
        diplomacy,
        events,
        evidence: Some(ExecutionEvidence::WorkerAutomation(execution)),
    })))
}

fn best_build(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    targets: &[ReachableTarget<'_>],
    metrics: &mut WorkerAutomationMetrics,
) -> Option<Candidate> {
    let mut best: Option<Candidate> = None;
    for target in targets {
        if metrics.legality_evaluations() >= context.ruleset().worker().automation_legality_budget()
        {
            break;
        }
        let Some(candidate) = best_improvement_at(state, context, unit, *target, metrics) else {
            continue;
        };
        if best
            .as_ref()
            .is_none_or(|current| candidate.compare_preference(current).is_gt())
        {
            best = Some(candidate);
        }
    }
    best
}

fn best_improvement_at(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: ReachableTarget<'_>,
    metrics: &mut WorkerAutomationMetrics,
) -> Option<Candidate> {
    let tile = context.map().tile_at(target.coordinate)?;
    let mut recommendation: Option<Candidate> = None;
    for (rank, definition) in context
        .ruleset()
        .worker()
        .improvements()
        .iter()
        .copied()
        .enumerate()
    {
        if !record_legality(context, metrics) {
            break;
        }
        if improvement_city(
            state,
            context,
            unit,
            target.coordinate,
            definition.kind(),
            false,
        )
        .is_err()
        {
            continue;
        }
        let score = improvement_score(definition, tile);
        let build_turns = context.ruleset().worker().improvement_turns(
            definition.base_build_turns(),
            state
                .match_lifecycle()
                .identity()
                .match_rules()
                .game_length()
                .pace_profile(),
        );
        let candidate = Candidate {
            option: WorkerAutomationOption::new(
                target.coordinate,
                WorkerAutomationAction::Improve(definition.kind()),
                target.movement_cost,
                *metrics,
            ),
            score,
            build_turns,
            city_id: target.city.id().clone(),
            improvement_rank: rank,
        };
        if recommendation.as_ref().is_none_or(|current| {
            candidate.score > current.score
                || candidate.score == current.score
                    && candidate.improvement_rank < current.improvement_rank
        }) {
            recommendation = Some(candidate);
        }
    }
    recommendation
}

fn best_assignment(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    targets: &[ReachableTarget<'_>],
    metrics: &mut WorkerAutomationMetrics,
) -> Option<Candidate> {
    let mut best: Option<Candidate> = None;
    let mut evaluated_city = None;
    let mut city_has_capacity = false;
    for target in targets {
        if evaluated_city != Some(target.city.id()) {
            evaluated_city = Some(target.city.id());
            city_has_capacity = automation_assignment_capacity(state, context, unit, target.city);
        }
        if !city_has_capacity {
            continue;
        }
        if !record_legality(context, metrics) {
            break;
        }
        let Some(tile) = context.map().tile_at(target.coordinate) else {
            continue;
        };
        let Some(improvement) = state
            .infrastructure()
            .field_improvement_at(target.coordinate)
        else {
            continue;
        };
        let Some(definition) = context.ruleset().worker().improvement(improvement.kind()) else {
            continue;
        };
        let candidate = Candidate {
            option: WorkerAutomationOption::new(
                target.coordinate,
                WorkerAutomationAction::Assign,
                target.movement_cost,
                *metrics,
            ),
            score: assignment_score(target.city, target.coordinate, definition, tile),
            build_turns: 0,
            city_id: target.city.id().clone(),
            improvement_rank: usize::MAX,
        };
        if best
            .as_ref()
            .is_none_or(|current| candidate.compare_preference(current).is_gt())
        {
            best = Some(candidate);
        }
    }
    best
}

fn record_legality(context: EngineContext<'_>, metrics: &mut WorkerAutomationMetrics) -> bool {
    if metrics.legality_evaluations() >= context.ruleset().worker().automation_legality_budget() {
        return false;
    }
    metrics.legality();
    true
}

fn validate_worker(
    context: EngineContext<'_>,
    unit: &Unit,
    continuation: bool,
) -> Result<(), WorkerRuleError> {
    if unit.kind() != UnitKind::Worker {
        return Err(CommandRejectionCode::WorkerNotFound.into());
    }
    if unit.activity().blocks_manual_movement() || unit.posture() == UnitPosture::Fortified {
        return Err(CommandRejectionCode::WorkerUnavailable.into());
    }
    if !unit.movement_units().is_positive() {
        return Err(CommandRejectionCode::WorkerNoMovementPoints.into());
    }
    if unit.queued_path().is_some() && !continuation {
        return Err(CommandRejectionCode::WorkerQueuedPathActive.into());
    }
    if continuation && unit.posture() != UnitPosture::AutoWorking {
        return Err(CommandRejectionCode::WorkerAutomationNotActive.into());
    }
    if context.map().tile_at(unit.position()).is_none() {
        return Err(CommandRejectionCode::WorkerUnavailable.into());
    }
    Ok(())
}

fn with_execution(
    mutation: WorkerMutation,
    unit_id: aonw_domain::UnitId,
    option: WorkerAutomationOption,
    movement: Option<UnitMovementExecution>,
) -> WorkerMutation {
    match mutation {
        WorkerMutation::Update(mut update) => {
            update.evidence = Some(ExecutionEvidence::WorkerAutomation(
                WorkerAutomationExecution::new(unit_id, option, movement),
            ));
            WorkerMutation::Update(update)
        }
    }
}

fn update_automation_unit(
    state: &GameState,
    replacement: Unit,
    interaction: aonw_domain::InteractionState,
    events: Box<[DomainEvent]>,
    evidence: Option<ExecutionEvidence>,
) -> Result<WorkerMutation, WorkerRuleError> {
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow)?;
    let mut units = state.units().to_vec();
    let replacement_id = replacement.id().clone();
    *units
        .iter_mut()
        .find(|unit| unit.id() == &replacement_id)
        .ok_or(CommandRejectionCode::WorkerNotFound)? = replacement;
    Ok(WorkerMutation::Update(Box::new(WorkerUpdate {
        revision,
        units,
        infrastructure: state.infrastructure().clone(),
        interaction,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        events,
        evidence,
    })))
}
