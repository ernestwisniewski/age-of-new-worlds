use aonw_domain::{
    GameState, HexCoord, MovementPathError, MovementStep, MovementUnits, QueuedMovePath,
    StateRevision, Unit, UnitBuildError, UnitId,
};

use super::{TerrainMovementQuery, TerrainMovementQueryError};
use crate::{CommandRejectionCode, EngineContext, GameEngine};

/// Revision-bound manual movement command.
#[derive(Clone, Copy, Debug)]
pub struct MoveUnitCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    target: HexCoord,
}

impl<'command> MoveUnitCommand<'command> {
    /// Creates a manual movement command.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'command UnitId, target: HexCoord) -> Self {
        Self {
            expected_revision,
            unit_id,
            target,
        }
    }

    /// Returns the commanded unit.
    #[must_use]
    pub const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
}

/// One authoritative unit-movement event.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitMovedEvent {
    unit_id: UnitId,
    from: HexCoord,
    to: HexCoord,
}

impl UnitMovedEvent {
    pub(crate) const fn new(unit_id: UnitId, from: HexCoord, to: HexCoord) -> Self {
        Self { unit_id, from, to }
    }
    /// Returns the moved unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the movement origin.
    #[must_use]
    pub const fn from(&self) -> HexCoord {
        self.from
    }

    /// Returns the movement destination.
    #[must_use]
    pub const fn to(&self) -> HexCoord {
        self.to
    }
}

/// Exact ordered steps executed by one accepted movement command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitMovementExecution {
    unit_id: UnitId,
    from: HexCoord,
    steps: Box<[MovementStep]>,
}

impl UnitMovementExecution {
    pub(crate) fn new(
        unit_id: UnitId,
        from: HexCoord,
        steps: impl Into<Box<[MovementStep]>>,
    ) -> Self {
        Self {
            unit_id,
            from,
            steps: steps.into(),
        }
    }
    /// Returns the moved unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the movement origin.
    #[must_use]
    pub const fn from(&self) -> HexCoord {
        self.from
    }

    /// Returns executed travel steps, excluding the origin.
    #[must_use]
    pub const fn steps(&self) -> &[MovementStep] {
        &self.steps
    }
}

/// Accepted movement result for one canonical unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct MovementTransition {
    revision: StateRevision,
    unit: Unit,
    event: Option<UnitMovedEvent>,
    execution: Option<UnitMovementExecution>,
}

impl MovementTransition {
    /// Returns the next canonical revision.
    #[must_use]
    pub(crate) const fn revision(&self) -> StateRevision {
        self.revision
    }

    /// Returns the updated canonical unit.
    #[must_use]
    pub(crate) const fn unit(&self) -> &Unit {
        &self.unit
    }

    /// Returns the movement event when the unit changed position.
    #[must_use]
    pub(crate) const fn event(&self) -> Option<&UnitMovedEvent> {
        self.event.as_ref()
    }

    /// Returns exact authoritative steps when the unit changed position.
    #[must_use]
    pub(crate) const fn execution(&self) -> Option<&UnitMovementExecution> {
        self.execution.as_ref()
    }

    /// Returns whether hidden authoritative occupancy caused an accepted no-op.
    #[must_use]
    #[cfg(test)]
    pub(crate) const fn is_no_op(&self) -> bool {
        self.event.is_none() && self.execution.is_none()
    }
}

/// Failure produced while applying a manual movement command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MoveUnitError {
    /// Query validation or planning rejected the command.
    Query(TerrainMovementQueryError),
    /// The next state revision cannot be represented.
    RevisionOverflow,
    /// A queued path could not be rebased after partial movement.
    InvalidQueuedPath(MovementPathError),
    /// The updated canonical unit violates its own invariants.
    InvalidUnit(UnitBuildError),
    /// The validated unit disappeared while constructing the update.
    UnitUpdateFailed,
}

impl MoveUnitError {
    /// Returns the stable language-neutral rejection code.
    #[must_use]
    pub const fn code(&self) -> CommandRejectionCode {
        match self {
            Self::Query(error) => error.code(),
            Self::RevisionOverflow => CommandRejectionCode::StateRevisionOverflow,
            Self::InvalidQueuedPath(_) => CommandRejectionCode::InvalidQueuedMovementPath,
            Self::InvalidUnit(_) => CommandRejectionCode::InvalidUnit,
            Self::UnitUpdateFailed => CommandRejectionCode::MovementUnitUpdateFailed,
        }
    }
}

impl core::fmt::Display for MoveUnitError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Query(error) => error.fmt(formatter),
            Self::RevisionOverflow => formatter.write_str("state revision overflow"),
            Self::InvalidQueuedPath(error) => error.fmt(formatter),
            Self::InvalidUnit(error) => error.fmt(formatter),
            Self::UnitUpdateFailed => formatter.write_str("movement unit update failed"),
        }
    }
}

impl std::error::Error for MoveUnitError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Query(error) => Some(error),
            Self::InvalidQueuedPath(error) => Some(error),
            Self::InvalidUnit(error) => Some(error),
            Self::RevisionOverflow | Self::UnitUpdateFailed => None,
        }
    }
}

pub(crate) fn apply_move_unit(
    state: &GameState,
    context: EngineContext<'_>,
    command: MoveUnitCommand<'_>,
) -> Result<MovementTransition, MoveUnitError> {
    let plan = GameEngine::plan_terrain_route(
        state,
        context,
        TerrainMovementQuery::new(command.expected_revision, command.unit_id, command.target),
    )
    .map_err(MoveUnitError::Query)?;
    let next_revision = state
        .revision()
        .get()
        .checked_add(1)
        .map(StateRevision::new)
        .ok_or(MoveUnitError::RevisionOverflow)?;
    let unit = state
        .unit(command.unit_id)
        .ok_or(MoveUnitError::UnitUpdateFailed)?;
    let reachable_steps = plan.reachable_steps();

    if reachable_path_hits_hidden_blocker(state.units(), unit, reachable_steps, context) {
        return Ok(MovementTransition {
            revision: next_revision,
            unit: unit
                .after_movement(
                    unit.position(),
                    unit.movement_units(),
                    unit.queued_path().cloned(),
                )
                .map_err(MoveUnitError::InvalidUnit)?,
            event: None,
            execution: None,
        });
    }

    let destination_step = reachable_steps
        .last()
        .ok_or(MoveUnitError::UnitUpdateFailed)?;
    let destination = destination_step.coordinate();
    let queued_path = if plan.target_reachable_this_turn() {
        None
    } else {
        Some(rebase_queued_path(
            plan.destination(),
            plan.steps(),
            reachable_steps.len().saturating_sub(1),
        )?)
    };
    let updated = unit
        .after_movement(destination, plan.remaining_movement(), queued_path)
        .map_err(MoveUnitError::InvalidUnit)?;

    if destination == unit.position() {
        return Ok(MovementTransition {
            revision: next_revision,
            unit: updated,
            event: None,
            execution: None,
        });
    }
    let executed_steps = reachable_steps
        .iter()
        .copied()
        .skip(1)
        .collect::<Vec<_>>()
        .into_boxed_slice();
    Ok(MovementTransition {
        revision: next_revision,
        unit: updated,
        event: Some(UnitMovedEvent {
            unit_id: unit.id().clone(),
            from: unit.position(),
            to: destination,
        }),
        execution: Some(UnitMovementExecution {
            unit_id: unit.id().clone(),
            from: unit.position(),
            steps: executed_steps,
        }),
    })
}

pub(crate) fn reachable_path_hits_hidden_blocker(
    units: &[Unit],
    moving_unit: &Unit,
    reachable_steps: &[MovementStep],
    context: EngineContext<'_>,
) -> bool {
    reachable_steps.iter().skip(1).any(|step| {
        units.iter().any(|candidate| {
            candidate.id() != moving_unit.id()
                && candidate.owner_player_id() != moving_unit.owner_player_id()
                && !context.observes_occupancy(moving_unit, candidate)
                && candidate.position() == step.coordinate()
        })
    }) || reachable_steps.iter().skip(1).any(|step| {
        context.city_blocks(moving_unit, step.coordinate())
            && !context.city_block_is_known(moving_unit, step.coordinate())
    }) || reachable_steps.iter().skip(1).any(|step| {
        context.territory_blocks(moving_unit, step.coordinate())
            && !context.territory_block_is_known(moving_unit, step.coordinate())
    })
}

pub(crate) fn movement_from_plan(
    unit: &Unit,
    plan: &super::TerrainMovementPlan,
    revision: StateRevision,
    retain_incomplete_path: bool,
    posture: aonw_domain::UnitPosture,
) -> Result<MovementTransition, MoveUnitError> {
    let reachable_steps = plan.reachable_steps();
    let destination = reachable_steps
        .last()
        .ok_or(MoveUnitError::UnitUpdateFailed)?
        .coordinate();
    let queued_path = if plan.target_reachable_this_turn() || !retain_incomplete_path {
        None
    } else {
        Some(rebase_queued_path(
            plan.destination(),
            plan.steps(),
            reachable_steps.len().saturating_sub(1),
        )?)
    };
    let updated = unit
        .after_automated_movement(destination, plan.remaining_movement(), queued_path, posture)
        .map_err(MoveUnitError::InvalidUnit)?;
    if destination == unit.position() {
        return Ok(MovementTransition {
            revision,
            unit: updated,
            event: None,
            execution: None,
        });
    }
    let executed_steps = reachable_steps.iter().copied().skip(1).collect::<Vec<_>>();
    Ok(MovementTransition {
        revision,
        unit: updated,
        event: Some(UnitMovedEvent::new(
            unit.id().clone(),
            unit.position(),
            destination,
        )),
        execution: Some(UnitMovementExecution::new(
            unit.id().clone(),
            unit.position(),
            executed_steps,
        )),
    })
}

fn rebase_queued_path(
    target: HexCoord,
    steps: &[MovementStep],
    reached_index: usize,
) -> Result<QueuedMovePath, MoveUnitError> {
    let remaining = steps
        .get(reached_index..)
        .ok_or(MoveUnitError::UnitUpdateFailed)?;
    let mut cumulative = MovementUnits::ZERO;
    let rebased = remaining
        .iter()
        .enumerate()
        .map(|(index, step)| {
            let enter_cost = if index == 0 {
                MovementUnits::ZERO
            } else {
                step.enter_cost()
            };
            cumulative =
                cumulative
                    .checked_add(enter_cost)
                    .ok_or(MoveUnitError::InvalidQueuedPath(
                        MovementPathError::CostOverflow { step_index: index },
                    ))?;
            Ok(MovementStep::new(step.coordinate(), enter_cost, cumulative))
        })
        .collect::<Result<Vec<_>, MoveUnitError>>()?;
    QueuedMovePath::try_new(target, rebased).map_err(MoveUnitError::InvalidQueuedPath)
}
