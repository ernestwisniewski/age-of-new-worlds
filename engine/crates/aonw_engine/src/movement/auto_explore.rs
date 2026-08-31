use std::cmp::Ordering;
use std::collections::BTreeSet;

use aonw_domain::{
    City, Diplomacy, FogOfWar, GameState, HexCoord, HexTileIndex, MatchIdentity, TransportNetwork,
    Unit, UnitKind, UnitPosture,
};

use super::fog::{merge_discovered_contacts, recompute_after_move, visible_from_source};
use super::logistics::{AutoExploreOption, AutoExploreUnitCommand, MovementLogisticsError};
use super::query::plan_route_for_unit;
use super::reachable::eventual_costs;
use super::transition::{movement_from_plan, reachable_path_hits_hidden_blocker};
use super::{MovementLogisticsUpdate, MovementSearchWorkspace, TerrainMovementPlan};
use crate::{
    AutoExplorePlannedEvent, CommandRejectionCode, DomainEvent, EngineContext, LogisticsExecution,
};

const NEWLY_DISCOVERED_SCORE: u64 = 1_000;
const UNDISCOVERED_TARGET_SCORE: u64 = 500;
const VISIBLE_HEX_SCORE: u64 = 2;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct Candidate {
    target: HexCoord,
    score: u64,
    newly_discovered: usize,
    target_undiscovered: bool,
    visible_hexes: usize,
    movement_cost: u32,
    distance: u64,
}

impl Candidate {
    fn compare_preference(self, other: Self) -> Ordering {
        self.score
            .cmp(&other.score)
            .then_with(|| self.newly_discovered.cmp(&other.newly_discovered))
            .then_with(|| self.target_undiscovered.cmp(&other.target_undiscovered))
            .then_with(|| other.movement_cost.cmp(&self.movement_cost))
            .then_with(|| other.distance.cmp(&self.distance))
            .then_with(|| other.target.col().cmp(&self.target.col()))
            .then_with(|| other.target.row().cmp(&self.target.row()))
    }
}

pub(super) struct PlannedAutoExplore {
    pub(super) route: TerrainMovementPlan,
    pub(super) option: AutoExploreOption,
}

pub(super) fn plan_auto_explore(
    state: &GameState,
    context: EngineContext<'_>,
    unit: &Unit,
    workspace: &mut MovementSearchWorkspace,
) -> Result<PlannedAutoExplore, MovementLogisticsError> {
    plan_auto_explore_for_world(
        state.revision().get(),
        state.units(),
        state.cities(),
        state.fog_of_war(),
        state.diplomacy(),
        state.match_lifecycle().identity(),
        state.transport_network(),
        context,
        unit,
        workspace,
    )
}

#[allow(clippy::too_many_arguments)]
pub(super) fn plan_auto_explore_for_world(
    revision: u64,
    units: &[Unit],
    cities: &[City],
    fog_of_war: &FogOfWar,
    diplomacy: &Diplomacy,
    match_identity: &MatchIdentity,
    transport_network: &TransportNetwork,
    context: EngineContext<'_>,
    unit: &Unit,
    workspace: &mut MovementSearchWorkspace,
) -> Result<PlannedAutoExplore, MovementLogisticsError> {
    validate_unit(match_identity, context, unit)?;
    let reserved = reserved_coordinates(units, unit);
    let context = context
        .with_movement_world(
            cities,
            fog_of_war,
            diplomacy,
            transport_network,
            match_identity,
        )
        .with_unrestricted_hidden_pathing()
        .with_excluded_path_hexes(&reserved);
    let metrics = eventual_costs(units, context.map(), unit, context, workspace);
    let discovered = fog_of_war
        .player(unit.owner_player_id())
        .map_or(&[][..], aonw_domain::PlayerFog::discovered_hexes);
    let mut best = None;
    for (index, &movement_cost) in workspace.reachable_costs[..context.map().bounds().tile_count()]
        .iter()
        .enumerate()
    {
        if movement_cost == u32::MAX {
            continue;
        }
        let Some(target) = context.map().coordinate_at(HexTileIndex::new(index)) else {
            continue;
        };
        if target == unit.position() || reserved.contains(&target) {
            continue;
        }
        let Some(tile) = context.map().tile_at(target) else {
            continue;
        };
        let observer_height = tile.height();
        let range = (2 + u32::from(observer_height / 2)).min(3);
        let reveal = visible_from_source(context.map(), target, range, observer_height);
        let newly_discovered = reveal
            .iter()
            .filter(|coordinate| discovered.binary_search(coordinate).is_err())
            .count();
        let target_undiscovered = discovered.binary_search(&target).is_err();
        if !target_undiscovered && newly_discovered == 0 {
            continue;
        }
        let visible_hexes = reveal.len();
        let score = u64::try_from(newly_discovered)
            .unwrap_or(u64::MAX)
            .saturating_mul(NEWLY_DISCOVERED_SCORE)
            .saturating_add(if target_undiscovered {
                UNDISCOVERED_TARGET_SCORE
            } else {
                0
            })
            .saturating_add(
                u64::try_from(visible_hexes)
                    .unwrap_or(u64::MAX)
                    .saturating_mul(VISIBLE_HEX_SCORE),
            );
        let candidate = Candidate {
            target,
            score,
            newly_discovered,
            target_undiscovered,
            visible_hexes,
            movement_cost,
            distance: unit.position().distance_to(target),
        };
        if best.is_none_or(|current| candidate.compare_preference(current).is_gt()) {
            best = Some(candidate);
        }
    }
    let best =
        best.ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::AutoExploreNoTarget))?;
    let route = plan_route_for_unit(
        revision,
        units,
        context,
        unit,
        best.target,
        unit.movement_units(),
        false,
    )
    .map_err(|error| MovementLogisticsError::new(error.code()))?;
    Ok(PlannedAutoExplore {
        option: AutoExploreOption {
            target: best.target,
            total_cost_units: route.total_cost().get(),
            metrics,
        },
        route,
    })
}

pub(crate) fn apply_auto_explore(
    state: &GameState,
    context: EngineContext<'_>,
    command: AutoExploreUnitCommand<'_>,
) -> Result<MovementLogisticsUpdate, MovementLogisticsError> {
    validate_revision(state, command.expected_revision())?;
    let unit = state
        .unit(command.unit_id())
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::UnitNotFound))?;
    let mut workspace = MovementSearchWorkspace::default();
    let planned = plan_auto_explore(state, context, unit, &mut workspace)?;
    let revision = state
        .revision()
        .checked_next()
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::StateRevisionOverflow))?;
    let primed = unit.after_auto_explore_started();
    let movement = if reachable_path_hits_hidden_blocker(
        state.units(),
        &primed,
        planned.route.reachable_steps(),
        context,
    ) {
        None
    } else {
        Some(
            movement_from_plan(
                &primed,
                &planned.route,
                revision,
                true,
                UnitPosture::AutoExploring,
            )
            .map_err(|error| MovementLogisticsError::new(error.code()))?,
        )
    };
    let updated = movement
        .as_ref()
        .map_or_else(|| primed.clone(), |movement| movement.unit().clone());
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated)?;
    let refs = units.iter().collect::<Vec<_>>();
    let fog = recompute_after_move(
        state.fog_of_war(),
        context.map(),
        unit.owner_player_id(),
        &refs,
        state.cities(),
    );
    let diplomacy = merge_discovered_contacts(state.diplomacy(), &fog, &refs, state.cities());
    let mut events = vec![DomainEvent::AutoExplorePlanned(
        AutoExplorePlannedEvent::new(unit.id().clone(), planned.option.target),
    )];
    if let Some(event) = movement
        .as_ref()
        .and_then(|movement| movement.event())
        .cloned()
    {
        events.push(DomainEvent::UnitMoved(event));
    }
    Ok(MovementLogisticsUpdate {
        revision,
        units,
        fog_of_war: fog,
        diplomacy,
        interaction: state.interaction().clone().without_unit(unit.id()),
        events: events.into_boxed_slice(),
        evidence: LogisticsExecution::AutoExplore {
            unit_id: unit.id().clone(),
            target: planned.option.target,
            movement: movement.and_then(|movement| movement.execution().cloned()),
        },
    })
}

pub(super) fn validate_revision(
    state: &GameState,
    expected_revision: u64,
) -> Result<(), MovementLogisticsError> {
    if state.revision().get() == expected_revision {
        Ok(())
    } else {
        Err(MovementLogisticsError::new(
            CommandRejectionCode::StaleRevision,
        ))
    }
}

fn validate_unit(
    match_identity: &MatchIdentity,
    context: EngineContext<'_>,
    unit: &Unit,
) -> Result<(), MovementLogisticsError> {
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotControlled,
        ));
    }
    if unit.kind() != UnitKind::Scout {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotScout,
        ));
    }
    if unit.activity().blocks_manual_movement() || unit.posture() == UnitPosture::Fortified {
        return Err(MovementLogisticsError::new(CommandRejectionCode::UnitBusy));
    }
    if !unit.movement_units().is_positive() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitExhausted,
        ));
    }
    if unit.queued_path().is_some() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitHasPath,
        ));
    }
    if context.map().tile_at(unit.position()).is_none() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitOutOfBounds,
        ));
    }
    if !match_identity.contains(unit.owner_player_id()) {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotControlled,
        ));
    }
    Ok(())
}

fn reserved_coordinates(units: &[Unit], unit: &Unit) -> BTreeSet<HexCoord> {
    let mut reserved = BTreeSet::new();
    for other in units.iter().filter(|other| {
        other.id() != unit.id()
            && other.owner_player_id() == unit.owner_player_id()
            && other.posture() == UnitPosture::AutoExploring
    }) {
        let Some(path) = other.queued_path() else {
            continue;
        };
        let mut found_current = false;
        for step in path.steps() {
            if found_current {
                reserved.insert(step.coordinate());
            } else {
                found_current = step.coordinate() == other.position();
            }
        }
        if !found_current {
            reserved.extend(
                path.steps()
                    .iter()
                    .map(|step| step.coordinate())
                    .filter(|coordinate| *coordinate != other.position()),
            );
        }
        reserved.insert(path.target());
    }
    reserved
}

fn replace_unit(units: &mut [Unit], updated: Unit) -> Result<(), MovementLogisticsError> {
    let target = units
        .iter_mut()
        .find(|unit| unit.id() == updated.id())
        .ok_or_else(|| {
            MovementLogisticsError::new(CommandRejectionCode::MovementUnitUpdateFailed)
        })?;
    *target = updated;
    Ok(())
}
