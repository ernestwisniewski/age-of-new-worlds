use aonw_domain::{
    City, Diplomacy, FieldImprovementKind, FogOfWar, GameState, InfrastructureState,
    InteractionState, PendingInteraction, StateRevision, Unit, UnitKind, WorkerJob,
};

use super::model::{
    AssignWorkerToHexCommand, BuildRoadCommand, CancelWorkerAssignmentCommand,
    CancelWorkerJobCommand, ConfirmWorkerImprovementCommand, SelectWorkerImprovementCommand,
    WorkerImprovementOption, WorkerOptions, WorkerOptionsQuery,
};
use crate::movement::{MovementCost, terrain_entry_cost};
use crate::{CommandRejectionCode, EngineContext, TechnologyUnlockQuery};

/// Corrupt content/state failure or a normal worker rejection.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum WorkerRuleError {
    Rejected(CommandRejectionCode),
}

impl From<CommandRejectionCode> for WorkerRuleError {
    fn from(value: CommandRejectionCode) -> Self {
        Self::Rejected(value)
    }
}

/// Atomic replacement produced by a worker command.
pub(crate) enum WorkerMutation {
    Update(Box<WorkerUpdate>),
}

pub(crate) struct WorkerUpdate {
    pub(crate) revision: StateRevision,
    pub(crate) units: Vec<Unit>,
    pub(crate) infrastructure: InfrastructureState,
    pub(crate) interaction: InteractionState,
    pub(crate) fog_of_war: FogOfWar,
    pub(crate) diplomacy: Diplomacy,
    pub(crate) events: Box<[crate::DomainEvent]>,
    pub(crate) evidence: Option<crate::ExecutionEvidence>,
}

pub(crate) fn apply_select(
    state: &GameState,
    context: EngineContext<'_>,
    command: SelectWorkerImprovementCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    start_improvement(state, context, command.unit_id(), command.improvement())
}

pub(crate) fn apply_confirm(
    state: &GameState,
    context: EngineContext<'_>,
    command: ConfirmWorkerImprovementCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    let pending = matching_pending(state, command.unit_id());
    let improvement = command
        .improvement()
        .or_else(|| pending.and_then(|pending| pending.1))
        .ok_or(CommandRejectionCode::WorkerImprovementNotSelected)?;
    if let Some((owner, _)) = pending
        && owner != context.actor_player_id()
    {
        return Err(CommandRejectionCode::WorkerActionNotControlled.into());
    }
    start_improvement(state, context, command.unit_id(), improvement)
}

pub(crate) fn apply_cancel_job(
    state: &GameState,
    context: EngineContext<'_>,
    command: CancelWorkerJobCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_worker(state, context, command.unit_id())?;
    if unit.activity().worker_job().is_none() {
        return Err(CommandRejectionCode::WorkerJobNotActive.into());
    }
    update_unit(
        state,
        unit.with_worker_job(None),
        clear_worker_pending(state, unit),
    )
}

pub(crate) fn apply_assign(
    state: &GameState,
    context: EngineContext<'_>,
    command: AssignWorkerToHexCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_worker(state, context, command.unit_id())?;
    assignment_city(state, context, unit, unit.position(), true)
        .ok_or(CommandRejectionCode::WorkerAssignmentUnavailable)?;
    update_unit(
        state,
        unit.after_worker_assigned(unit.position()),
        clear_worker_pending(state, unit),
    )
}

pub(crate) fn apply_cancel_assignment(
    state: &GameState,
    context: EngineContext<'_>,
    command: CancelWorkerAssignmentCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_worker(state, context, command.unit_id())?;
    if unit.activity().worker_assignment().is_none() {
        return Err(CommandRejectionCode::WorkerAssignmentNotActive.into());
    }
    update_unit(
        state,
        unit.after_worker_assignment_cancelled(),
        clear_worker_pending(state, unit),
    )
}

pub(crate) fn apply_build_road(
    state: &GameState,
    context: EngineContext<'_>,
    command: BuildRoadCommand<'_>,
) -> Result<WorkerMutation, WorkerRuleError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_worker(state, context, command.unit_id())?;
    validate_road(state, context, unit, unit.position(), true)?;
    let turns = context.ruleset().worker().road_build_turns(pace(state));
    let job = WorkerJob::RoadConstruction {
        target: unit.position(),
        remaining_turns: turns,
        total_turns: turns,
    };
    update_unit(
        state,
        unit.after_worker_job_started(job),
        clear_worker_pending(state, unit),
    )
}

pub(crate) fn query_options(
    state: &GameState,
    context: EngineContext<'_>,
    query: WorkerOptionsQuery<'_>,
) -> Result<WorkerOptions, WorkerRuleError> {
    validate_revision(state, query.expected_revision())?;
    let unit = controlled_worker(state, context, query.unit_id())?;
    let improvements = context
        .ruleset()
        .worker()
        .improvements()
        .iter()
        .filter_map(|definition| {
            improvement_city(
                state,
                context,
                unit,
                unit.position(),
                definition.kind(),
                true,
            )
            .ok()
            .map(|_| {
                WorkerImprovementOption::new(
                    definition.kind(),
                    context
                        .ruleset()
                        .worker()
                        .improvement_turns(definition.base_build_turns(), pace(state)),
                )
            })
        })
        .collect::<Vec<_>>();
    let can_assign = assignment_city(state, context, unit, unit.position(), true).is_some();
    let can_build_road = validate_road(state, context, unit, unit.position(), true).is_ok();
    let automation = super::automation::plan_automation(state, context, unit).ok();
    Ok(WorkerOptions::new(
        state.revision().get(),
        unit.id().clone(),
        unit.position(),
        improvements,
        can_assign,
        can_build_road,
        automation,
    ))
}

pub(super) fn start_improvement(
    state: &GameState,
    context: EngineContext<'_>,
    unit_id: &aonw_domain::UnitId,
    improvement: FieldImprovementKind,
) -> Result<WorkerMutation, WorkerRuleError> {
    let unit = controlled_worker(state, context, unit_id)?;
    improvement_city(state, context, unit, unit.position(), improvement, true)?;
    let definition = context
        .ruleset()
        .worker()
        .improvement(improvement)
        .ok_or(CommandRejectionCode::WorkerImprovementUnavailable)?;
    let turns = context
        .ruleset()
        .worker()
        .improvement_turns(definition.base_build_turns(), pace(state));
    let job = WorkerJob::FieldImprovement {
        target: unit.position(),
        improvement,
        remaining_turns: turns,
        total_turns: turns,
    };
    update_unit(
        state,
        unit.after_worker_job_started(job),
        clear_worker_pending(state, unit),
    )
}

pub(super) fn improvement_city<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: aonw_domain::HexCoord,
    improvement: FieldImprovementKind,
    require_ready: bool,
) -> Result<&'state City, WorkerRuleError> {
    if unit.kind() != UnitKind::Worker {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    if require_ready && unit.activity().blocks_manual_movement() {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    if require_ready && !unit.movement_units().is_positive() {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    if require_ready && unit.queued_path().is_some() {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    let tile = context
        .map()
        .tile_at(target)
        .ok_or(CommandRejectionCode::WorkerImprovementUnavailable)?;
    if state.cities().iter().any(|city| city.center() == target)
        || state
            .field_improvements()
            .iter()
            .any(|value| value.coordinate() == target)
    {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    let definition = context
        .ruleset()
        .worker()
        .improvement(improvement)
        .ok_or(CommandRejectionCode::WorkerImprovementUnavailable)?;
    if !definition.required_resources().is_empty()
        && !definition
            .required_resources()
            .iter()
            .any(|resource| tile.resources().contains(resource))
        || !definition.required_base_terrains().is_empty()
            && !definition
                .required_base_terrains()
                .contains(&tile.yield_terrain())
        || definition.requires_river()
            && !tile
                .terrain_tags()
                .contains(&aonw_content::TerrainType::River)
    {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    let city = state
        .cities()
        .iter()
        .find(|city| {
            city.owner_player_id() == unit.owner_player_id()
                && city.center() != target
                && city.controls(target)
        })
        .ok_or(CommandRejectionCode::WorkerImprovementUnavailable)?;
    let research = state
        .research()
        .players()
        .get(unit.owner_player_id())
        .ok_or(CommandRejectionCode::WorkerImprovementUnavailable)?;
    if !TechnologyUnlockQuery::new(context.ruleset(), research).is_improvement_unlocked(improvement)
    {
        return Err(CommandRejectionCode::WorkerImprovementUnavailable.into());
    }
    Ok(city)
}

pub(super) fn assignment_city<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: aonw_domain::HexCoord,
    require_ready: bool,
) -> Option<&'state City> {
    if unit.kind() != UnitKind::Worker
        || require_ready && unit.activity().blocks_manual_movement()
        || require_ready && !unit.movement_units().is_positive()
        || require_ready && unit.queued_path().is_some()
        || context.map().tile_at(target).is_none()
        || state
            .field_improvements()
            .iter()
            .all(|value| value.coordinate() != target)
        || state.units().iter().any(|other| {
            other.id() != unit.id()
                && other.owner_player_id() == unit.owner_player_id()
                && other.activity().worker_assignment() == Some(target)
        })
    {
        return None;
    }
    let city = state.cities().iter().find(|city| {
        city.owner_player_id() == unit.owner_player_id()
            && city.center() != target
            && city.controls(target)
    })?;
    let assigned = state
        .units()
        .iter()
        .filter(|other| {
            other.owner_player_id() == unit.owner_player_id()
                && other
                    .activity()
                    .worker_assignment()
                    .is_some_and(|coordinate| city.controls(coordinate))
        })
        .count();
    (assigned
        < usize::try_from(
            context
                .ruleset()
                .worker()
                .assignment_limit(city.population()),
        )
        .unwrap_or(usize::MAX))
    .then_some(city)
}

pub(super) fn validate_road(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    target: aonw_domain::HexCoord,
    require_ready: bool,
) -> Result<(), WorkerRuleError> {
    if unit.kind() != UnitKind::Worker
        || require_ready && unit.activity().blocks_manual_movement()
        || require_ready && !unit.movement_units().is_positive()
        || require_ready && unit.queued_path().is_some()
    {
        return Err(CommandRejectionCode::WorkerRoadUnavailable.into());
    }
    let tile = context
        .map()
        .tile_at(target)
        .ok_or(CommandRejectionCode::WorkerRoadUnavailable)?;
    if state.transport_network().at(target).is_some() {
        return Err(CommandRejectionCode::RoadConstructionExistingRoad.into());
    }
    if state.city_at(target).is_some() {
        return Err(CommandRejectionCode::RoadConstructionCity.into());
    }
    if let Some(controller) = state.city_controlling(target)
        && controller.owner_player_id() != unit.owner_player_id()
    {
        return Err(CommandRejectionCode::RoadConstructionEnemyTerritory.into());
    }
    if matches!(
        terrain_entry_cost(tile, aonw_domain::UnitMovementDomain::Land),
        MovementCost::Blocked
    ) {
        return Err(CommandRejectionCode::RoadConstructionImpassableTerrain.into());
    }
    Ok(())
}

fn controlled_worker<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit_id: &aonw_domain::UnitId,
) -> Result<&'state Unit, WorkerRuleError> {
    let unit = state
        .unit(unit_id)
        .ok_or(CommandRejectionCode::WorkerNotFound)?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::WorkerNotControlled.into());
    }
    Ok(unit)
}

fn validate_revision(state: &GameState, expected: u64) -> Result<(), WorkerRuleError> {
    if state.revision().get() == expected {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}

fn pace(state: &GameState) -> aonw_domain::PaceProfile {
    state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile()
}

fn matching_pending<'state>(
    state: &'state GameState,
    unit_id: &aonw_domain::UnitId,
) -> Option<(&'state aonw_domain::PlayerId, Option<FieldImprovementKind>)> {
    match state.interaction().pending()? {
        PendingInteraction::WorkerActionSelection {
            owner_player_id,
            unit_id: selected,
            improvement,
        } if selected == unit_id => Some((owner_player_id, *improvement)),
        _ => None,
    }
}

fn clear_worker_pending(state: &GameState, unit: &Unit) -> InteractionState {
    let interaction = state.interaction().clone();
    if matches!(
        interaction.pending(),
        Some(PendingInteraction::WorkerActionSelection { unit_id, .. }) if unit_id == unit.id()
    ) {
        interaction.with_pending(None)
    } else {
        interaction
    }
}

fn update_unit(
    state: &GameState,
    replacement: Unit,
    interaction: InteractionState,
) -> Result<WorkerMutation, WorkerRuleError> {
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow)?;
    let mut units = state.units().to_vec();
    let target = units
        .iter_mut()
        .find(|unit| unit.id() == replacement.id())
        .ok_or(CommandRejectionCode::WorkerNotFound)?;
    *target = replacement;
    Ok(WorkerMutation::Update(Box::new(WorkerUpdate {
        revision,
        units,
        infrastructure: state.infrastructure().clone(),
        interaction,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
        events: Box::new([]),
        evidence: None,
    })))
}
