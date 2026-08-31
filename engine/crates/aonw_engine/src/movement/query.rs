use aonw_content::MapDefinition;
use aonw_domain::{GameState, HexCoord, MovementStep, MovementUnits, Unit, UnitId};

use super::MovementSearchMetrics;
use super::reachable::movement_available_for_query;
use super::route_search::{find_route, find_route_ignoring_capacity, find_route_to_any};
use crate::{CommandRejectionCode, EngineContext};

/// Input for deterministic terrain-only movement planning.
#[derive(Clone, Copy, Debug)]
pub struct TerrainMovementQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
    target: HexCoord,
}

impl<'query> TerrainMovementQuery<'query> {
    /// Creates a revision-bound route query.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId, target: HexCoord) -> Self {
        Self {
            expected_revision,
            unit_id,
            target,
        }
    }
}

/// Deterministic route and the prefix executable during the current turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TerrainMovementPlan {
    revision: u64,
    unit_id: UnitId,
    target: HexCoord,
    destination: HexCoord,
    total_cost: MovementUnits,
    available_movement: MovementUnits,
    remaining_movement: MovementUnits,
    furthest_reachable_step_index: usize,
    steps: Box<[MovementStep]>,
    search_metrics: MovementSearchMetrics,
}

impl TerrainMovementPlan {
    /// Returns the state revision used to compute the plan.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }

    /// Returns the moving unit identifier.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the requested destination.
    #[must_use]
    pub const fn target(&self) -> HexCoord {
        self.target
    }

    /// Returns the final route coordinate.
    ///
    /// This differs from `target` when planning an approach to an occupied hex.
    #[must_use]
    pub const fn destination(&self) -> HexCoord {
        self.destination
    }

    /// Returns the complete multi-turn route cost.
    #[must_use]
    pub const fn total_cost(&self) -> MovementUnits {
        self.total_cost
    }

    /// Returns movement available before executing the current-turn prefix.
    #[must_use]
    pub const fn available_movement(&self) -> MovementUnits {
        self.available_movement
    }

    /// Returns movement remaining after executing the current-turn prefix.
    #[must_use]
    pub const fn remaining_movement(&self) -> MovementUnits {
        self.remaining_movement
    }

    /// Returns the route including its zero-cost origin.
    #[must_use]
    pub const fn steps(&self) -> &[MovementStep] {
        &self.steps
    }

    /// Returns deterministic search work counters.
    #[must_use]
    pub const fn search_metrics(&self) -> MovementSearchMetrics {
        self.search_metrics
    }

    /// Returns the route prefix executable during the current turn.
    #[must_use]
    pub fn reachable_steps(&self) -> &[MovementStep] {
        &self.steps[..=self.furthest_reachable_step_index]
    }

    /// Returns whether the complete target can be reached this turn.
    #[must_use]
    pub fn target_reachable_this_turn(&self) -> bool {
        self.furthest_reachable_step_index + 1 == self.steps.len()
    }
}

/// Rejection from the terrain-only movement query.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum TerrainMovementQueryError {
    StaleRevision { expected: u64, actual: u64 },
    UnitNotFound,
    UnitNotControlled,
    UnitUnavailable,
    UnitUsesTradeRoutes,
    UnitOutOfBounds,
    TargetOutOfBounds,
    TargetIsCurrentTile,
    TargetIsForeignCityCenter,
    TargetOccupied,
    MovementCapacityInsufficient,
    PathNotFound,
}

impl TerrainMovementQueryError {
    /// Returns the stable language-neutral rejection code.
    #[must_use]
    pub const fn code(&self) -> CommandRejectionCode {
        match self {
            Self::StaleRevision { .. } => CommandRejectionCode::StaleRevision,
            Self::UnitNotFound => CommandRejectionCode::UnitNotFound,
            Self::UnitNotControlled => CommandRejectionCode::UnitNotControlled,
            Self::UnitUnavailable => CommandRejectionCode::UnitUnavailable,
            Self::UnitUsesTradeRoutes => CommandRejectionCode::UnitUsesTradeRoutes,
            Self::UnitOutOfBounds => CommandRejectionCode::UnitOutOfBounds,
            Self::TargetOutOfBounds => CommandRejectionCode::MoveTargetOutOfBounds,
            Self::TargetIsCurrentTile => CommandRejectionCode::MoveTargetIsCurrentTile,
            Self::TargetIsForeignCityCenter => CommandRejectionCode::MoveTargetIsForeignCityCenter,
            Self::TargetOccupied => CommandRejectionCode::MoveTargetOccupied,
            Self::MovementCapacityInsufficient => {
                CommandRejectionCode::UnitMovementCapacityInsufficient
            }
            Self::PathNotFound => CommandRejectionCode::MovePathNotFound,
        }
    }
}

impl core::fmt::Display for TerrainMovementQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::StaleRevision { expected, actual } => {
                write!(
                    formatter,
                    "stale revision {expected}; current revision is {actual}"
                )
            }
            Self::UnitNotFound => formatter.write_str("unit not found"),
            Self::UnitNotControlled => formatter.write_str("unit is not controlled by the actor"),
            Self::UnitUnavailable => formatter.write_str("unit is unavailable for manual movement"),
            Self::UnitUsesTradeRoutes => formatter.write_str("unit uses trade routes"),
            Self::UnitOutOfBounds => formatter.write_str("unit is outside map bounds"),
            Self::TargetOutOfBounds => formatter.write_str("target is outside map bounds"),
            Self::TargetIsCurrentTile => formatter.write_str("target is the current tile"),
            Self::TargetIsForeignCityCenter => {
                formatter.write_str("target is a foreign city center")
            }
            Self::TargetOccupied => formatter.write_str("target is occupied"),
            Self::MovementCapacityInsufficient => {
                formatter.write_str("unit movement capacity is insufficient")
            }
            Self::PathNotFound => formatter.write_str("movement path not found"),
        }
    }
}

impl std::error::Error for TerrainMovementQueryError {}

pub(crate) fn plan_terrain_route(
    state: &GameState,
    context: EngineContext<'_>,
    query: TerrainMovementQuery<'_>,
) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
    validate_revision(state, query.expected_revision)?;
    let unit = validate_unit(state, context, query.unit_id)?;
    plan_route_for_unit(
        state.revision().get(),
        state.units(),
        context,
        unit,
        query.target,
        movement_available_for_query(unit, context.ruleset()),
        true,
    )
}

#[allow(clippy::too_many_arguments)]
pub(crate) fn plan_route_for_unit(
    revision: u64,
    units: &[Unit],
    context: EngineContext<'_>,
    unit: &Unit,
    target: HexCoord,
    available_movement: MovementUnits,
    allow_occupied_approach: bool,
) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
    validate_target(context.map(), unit, target)?;
    if context.city_block_is_known(unit, target) {
        return Err(TerrainMovementQueryError::TargetIsForeignCityCenter);
    }

    let known_blocker = known_target_blocker(units, unit, target, context);
    let (steps, search_metrics) = if let Some(blocker) = known_blocker {
        if !allow_occupied_approach {
            return Err(TerrainMovementQueryError::TargetOccupied);
        }
        let approach = find_approach_route(
            units,
            context.map(),
            unit,
            target,
            available_movement,
            context,
        );
        let steps = approach
            .steps
            .ok_or(TerrainMovementQueryError::TargetOccupied)?;
        if steps.len() == 1 {
            return Err(TerrainMovementQueryError::TargetOccupied);
        }
        let approach_cost = steps
            .last()
            .map_or(MovementUnits::ZERO, |step| step.cumulative_cost());
        if blocker.owner_player_id() == unit.owner_player_id()
            && approach_cost <= available_movement
        {
            return Err(TerrainMovementQueryError::TargetOccupied);
        }
        (steps, approach.metrics)
    } else {
        let search = find_route(
            units,
            context.map(),
            unit,
            target,
            available_movement,
            context,
        );
        let Some(steps) = search.steps else {
            let diagnostic = find_route_ignoring_capacity(
                units,
                context.map(),
                unit,
                target,
                available_movement,
                context,
            );
            return Err(if diagnostic.steps.is_some() {
                TerrainMovementQueryError::MovementCapacityInsufficient
            } else {
                TerrainMovementQueryError::PathNotFound
            });
        };
        (steps, search.metrics)
    };
    let total_cost = steps
        .last()
        .map_or(MovementUnits::ZERO, |step| step.cumulative_cost());
    let furthest_reachable_step_index = reachable_step_index(&steps, available_movement);
    let reachable_cost = steps
        .get(furthest_reachable_step_index)
        .ok_or(TerrainMovementQueryError::PathNotFound)?
        .cumulative_cost();
    let remaining_movement = available_movement
        .checked_sub(reachable_cost)
        .unwrap_or(MovementUnits::ZERO);

    Ok(TerrainMovementPlan {
        revision,
        unit_id: unit.id().clone(),
        target,
        destination: steps
            .last()
            .map_or(unit.position(), |step| step.coordinate()),
        total_cost,
        available_movement,
        remaining_movement,
        furthest_reachable_step_index,
        steps: steps.into_boxed_slice(),
        search_metrics,
    })
}

pub(super) fn validate_revision(
    state: &GameState,
    expected_revision: u64,
) -> Result<(), TerrainMovementQueryError> {
    if state.revision().get() == expected_revision {
        return Ok(());
    }
    Err(TerrainMovementQueryError::StaleRevision {
        expected: expected_revision,
        actual: state.revision().get(),
    })
}

pub(super) fn validate_unit<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit_id: &UnitId,
) -> Result<&'state Unit, TerrainMovementQueryError> {
    let unit = state
        .unit(unit_id)
        .ok_or(TerrainMovementQueryError::UnitNotFound)?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(TerrainMovementQueryError::UnitNotControlled);
    }
    if unit.activity().blocks_manual_movement() {
        return Err(TerrainMovementQueryError::UnitUnavailable);
    }
    let Some(definition) = context.ruleset().unit(unit.kind()) else {
        return Err(TerrainMovementQueryError::UnitUnavailable);
    };
    if definition.capabilities().uses_trade_routes() {
        return Err(TerrainMovementQueryError::UnitUsesTradeRoutes);
    }
    if context.map().tile_at(unit.position()).is_none() {
        return Err(TerrainMovementQueryError::UnitOutOfBounds);
    }
    Ok(unit)
}

fn validate_target(
    map: &MapDefinition,
    unit: &Unit,
    target: HexCoord,
) -> Result<(), TerrainMovementQueryError> {
    if map.tile_at(target).is_none() {
        return Err(TerrainMovementQueryError::TargetOutOfBounds);
    }
    if target == unit.position() {
        return Err(TerrainMovementQueryError::TargetIsCurrentTile);
    }
    Ok(())
}

fn known_target_blocker<'state>(
    units: &'state [Unit],
    unit: &Unit,
    target: HexCoord,
    context: EngineContext<'_>,
) -> Option<&'state Unit> {
    units.iter().find(|candidate| {
        candidate.id() != unit.id()
            && candidate.position() == target
            && context.observes_occupancy(unit, candidate)
            && !context.can_share_occupied_city(unit, candidate.position())
    })
}

struct ApproachSearchResult {
    steps: Option<Vec<MovementStep>>,
    metrics: MovementSearchMetrics,
}

fn find_approach_route(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
) -> ApproachSearchResult {
    let destinations = map.neighbors(target).collect::<Vec<_>>();
    let search = find_route_to_any(units, map, unit, &destinations, available_movement, context);
    ApproachSearchResult {
        steps: search.steps,
        metrics: search.metrics,
    }
}

fn reachable_step_index(steps: &[MovementStep], available: MovementUnits) -> usize {
    let mut reachable_index = 0;
    for (index, step) in steps.iter().enumerate().skip(1) {
        let before_step = step
            .cumulative_cost()
            .checked_sub(step.enter_cost())
            .unwrap_or(MovementUnits::ZERO);
        if step.cumulative_cost() <= available || before_step < available {
            reachable_index = index;
        } else {
            break;
        }
    }
    reachable_index
}
