use std::cmp::Ordering;

use aonw_content::MapDefinition;
use aonw_domain::{GameState, HexCoord, HexTileIndex, MovementUnits, Unit, UnitId, UnitPosture};

use super::compiled_map::neighbor_indices;
use super::cost::movement_cost_for_index;
use super::query::{validate_revision, validate_unit};
use super::{
    MovementCost, MovementOccupancy, MovementSearchMetrics, MovementSearchWorkspace,
    TerrainMovementQueryError, maximum_movement_units,
};
use crate::EngineContext;

/// Input for a revision-bound reachable-hex query.
#[derive(Clone, Copy, Debug)]
pub struct ReachableMovementQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
}

impl<'query> ReachableMovementQuery<'query> {
    /// Creates a query for every hex reachable during the current turn.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }
}

/// One row-major reachable coordinate and its minimum current-turn cost.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReachableMovementTile {
    coordinate: HexCoord,
    cost: MovementUnits,
    exhausts_movement: bool,
}

impl ReachableMovementTile {
    /// Returns the reachable coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns the minimum fixed-point cost from the unit origin.
    #[must_use]
    pub const fn cost(self) -> MovementUnits {
        self.cost
    }

    /// Returns whether entering this boundary tile consumes the remaining turn.
    #[must_use]
    pub const fn exhausts_movement(self) -> bool {
        self.exhausts_movement
    }
}

/// Deterministic row-major result for a reachable-hex query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableMovement {
    revision: u64,
    unit_id: UnitId,
    available_movement: MovementUnits,
    tiles: Box<[ReachableMovementTile]>,
    search_metrics: MovementSearchMetrics,
}

impl ReachableMovement {
    /// Returns the state revision used by the query.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }

    /// Returns the queried unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns movement available at query time.
    #[must_use]
    pub const fn available_movement(&self) -> MovementUnits {
        self.available_movement
    }

    /// Returns reachable tiles in stable row-major order.
    #[must_use]
    pub const fn tiles(&self) -> &[ReachableMovementTile] {
        &self.tiles
    }

    /// Returns deterministic search work counters.
    #[must_use]
    pub const fn search_metrics(&self) -> MovementSearchMetrics {
        self.search_metrics
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) struct FrontierNode {
    cost: u32,
    index: usize,
    col: i32,
    row: i32,
}

impl Ord for FrontierNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| other.col.cmp(&self.col))
            .then_with(|| other.row.cmp(&self.row))
    }
}

impl PartialOrd for FrontierNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[cfg(test)]
pub(crate) fn find_reachable_tiles(
    state: &GameState,
    context: EngineContext<'_>,
    query: ReachableMovementQuery<'_>,
) -> Result<ReachableMovement, TerrainMovementQueryError> {
    let mut workspace = MovementSearchWorkspace::default();
    find_reachable_tiles_with_workspace(state, context, query, &mut workspace)
}

pub(crate) fn find_reachable_tiles_with_workspace(
    state: &GameState,
    context: EngineContext<'_>,
    query: ReachableMovementQuery<'_>,
    workspace: &mut MovementSearchWorkspace,
) -> Result<ReachableMovement, TerrainMovementQueryError> {
    validate_revision(state, query.expected_revision)?;
    let unit = validate_unit(state, context, query.unit_id)?;
    let available = movement_available_for_query(unit, context.ruleset());
    let search_metrics = reachable_costs(
        state.units(),
        context.map(),
        unit,
        available,
        context,
        workspace,
    );
    let costs = &workspace.reachable_costs[..context.map().bounds().tile_count()];
    let tiles = costs
        .iter()
        .enumerate()
        .filter_map(|(index, cost)| {
            if *cost == u32::MAX {
                return None;
            }
            if index == context.map().tile_index(unit.position())?.get() {
                return None;
            }
            Some(ReachableMovementTile {
                coordinate: context.map().coordinate_at(HexTileIndex::new(index))?,
                cost: MovementUnits::new(*cost),
                exhausts_movement: *cost > available.get(),
            })
        })
        .collect::<Vec<_>>()
        .into_boxed_slice();
    Ok(ReachableMovement {
        revision: state.revision().get(),
        unit_id: unit.id().clone(),
        available_movement: available,
        tiles,
        search_metrics,
    })
}

pub(super) fn movement_available_for_query(
    unit: &Unit,
    ruleset: &aonw_content::RulesetDefinition,
) -> MovementUnits {
    let maximum =
        maximum_movement_units(ruleset, unit.kind(), unit.carried_artifact_id().is_some());
    if unit.posture() == UnitPosture::Fortified {
        maximum
    } else {
        core::cmp::min(unit.movement_units(), maximum)
    }
}

fn reachable_costs(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    available: MovementUnits,
    context: EngineContext<'_>,
    workspace: &mut MovementSearchWorkspace,
) -> MovementSearchMetrics {
    let tile_count = map.bounds().tile_count();
    workspace.prepare(tile_count);
    let Some(definition) = context.ruleset().unit(unit.kind()) else {
        return MovementSearchMetrics::default();
    };
    let mut metrics = MovementSearchMetrics::default();
    let Some(start) = map.tile_index(unit.position()).map(HexTileIndex::get) else {
        return metrics;
    };
    let occupied = MovementOccupancy::for_unit(units, map, unit, context);
    let access = context.prepare_movement_access(unit);
    let costs = &mut workspace.reachable_costs[..tile_count];
    costs[start] = 0;
    let frontier = &mut workspace.reachable_frontier;
    let start_coord = unit.position();
    frontier.push(FrontierNode {
        cost: 0,
        index: start,
        col: start_coord.col(),
        row: start_coord.row(),
    });
    metrics.pushed();
    let maximum = maximum_movement_units(
        context.ruleset(),
        unit.kind(),
        unit.carried_artifact_id().is_some(),
    );

    while let Some(current) = frontier.pop() {
        metrics.popped();
        if costs[current.index] != current.cost {
            continue;
        }
        if current.cost >= available.get() {
            continue;
        }
        metrics.expanded();
        let (neighbors, neighbor_count) =
            neighbor_indices(map, context.compiled_movement_map(), current.index);
        for &next_index in &neighbors[..neighbor_count] {
            metrics.examined_edge();
            let Some(next) = map.coordinate_at(HexTileIndex::new(next_index)) else {
                continue;
            };
            if occupied.contains(next_index) {
                continue;
            }
            if !context.can_plan_through_tile(unit, next) || access.blocks(next_index) {
                continue;
            }
            let movement_domain = definition.capabilities().movement_domain.domain();
            let MovementCost::Passable(enter_cost) = movement_cost_for_index(
                current.index,
                next,
                next_index,
                map,
                movement_domain,
                context,
                &access,
            ) else {
                continue;
            };
            if enter_cost > maximum && unit.carried_artifact_id().is_none() {
                continue;
            }
            let Some(next_cost) = current.cost.checked_add(enter_cost.get()) else {
                continue;
            };
            if costs[next_index] <= next_cost {
                continue;
            }
            costs[next_index] = next_cost;
            frontier.push(FrontierNode {
                cost: next_cost,
                index: next_index,
                col: next.col(),
                row: next.row(),
            });
            metrics.pushed();
        }
    }
    metrics
}

pub(super) fn eventual_costs(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    context: EngineContext<'_>,
    workspace: &mut MovementSearchWorkspace,
) -> MovementSearchMetrics {
    reachable_costs(
        units,
        map,
        unit,
        MovementUnits::new(u32::MAX),
        context,
        workspace,
    )
}
