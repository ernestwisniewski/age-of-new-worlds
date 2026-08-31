use crate::{HexCoord, MovementUnits};

/// Invalid persisted movement route.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MovementPathError {
    MissingTravelStep,
    InvalidOriginCost,
    ZeroEnterCost {
        step_index: usize,
    },
    CostOverflow {
        step_index: usize,
    },
    CumulativeCostMismatch {
        step_index: usize,
        expected: MovementUnits,
        actual: MovementUnits,
    },
    NonAdjacentStep {
        step_index: usize,
    },
    TargetMismatch {
        expected: HexCoord,
        actual: HexCoord,
    },
}

impl core::fmt::Display for MovementPathError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::MissingTravelStep => {
                formatter.write_str("queued path must contain an origin and a travel step")
            }
            Self::InvalidOriginCost => formatter.write_str("queued path origin costs must be zero"),
            Self::ZeroEnterCost { step_index } => {
                write!(
                    formatter,
                    "queued path step {step_index} has zero entry cost"
                )
            }
            Self::CostOverflow { step_index } => {
                write!(formatter, "queued path cost overflows at step {step_index}")
            }
            Self::CumulativeCostMismatch {
                step_index,
                expected,
                actual,
            } => write!(
                formatter,
                "queued path step {step_index} cumulative cost must be {}, found {}",
                expected.get(),
                actual.get()
            ),
            Self::NonAdjacentStep { step_index } => {
                write!(formatter, "queued path step {step_index} is not adjacent")
            }
            Self::TargetMismatch { expected, actual } => write!(
                formatter,
                "queued path target ({}, {}) does not match final step ({}, {})",
                expected.col(),
                expected.row(),
                actual.col(),
                actual.row()
            ),
        }
    }
}

impl std::error::Error for MovementPathError {}

/// One coordinate and its deterministic entry costs in a movement plan.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MovementStep {
    coordinate: HexCoord,
    enter_cost: MovementUnits,
    cumulative_cost: MovementUnits,
}

impl MovementStep {
    /// Constructs one plan step.
    #[must_use]
    pub const fn new(
        coordinate: HexCoord,
        enter_cost: MovementUnits,
        cumulative_cost: MovementUnits,
    ) -> Self {
        Self {
            coordinate,
            enter_cost,
            cumulative_cost,
        }
    }

    /// Returns the step coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns the cost of entering this step.
    #[must_use]
    pub const fn enter_cost(self) -> MovementUnits {
        self.enter_cost
    }

    /// Returns the route cost through this step.
    #[must_use]
    pub const fn cumulative_cost(self) -> MovementUnits {
        self.cumulative_cost
    }
}

/// Persisted route retained when a command cannot reach its target this turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct QueuedMovePath {
    target: HexCoord,
    steps: Box<[MovementStep]>,
}

impl QueuedMovePath {
    /// Constructs a route after validating its ordered coordinates and costs.
    ///
    /// # Errors
    ///
    /// Returns [`MovementPathError`] when the route has no travel step, does
    /// not start with zero costs, contains a non-adjacent coordinate, has an
    /// invalid cumulative cost, or does not finish at `target`.
    pub fn try_new(
        target: HexCoord,
        steps: impl Into<Box<[MovementStep]>>,
    ) -> Result<Self, MovementPathError> {
        let steps = steps.into();
        if steps.len() < 2 {
            return Err(MovementPathError::MissingTravelStep);
        }
        if steps[0].enter_cost() != MovementUnits::ZERO
            || steps[0].cumulative_cost() != MovementUnits::ZERO
        {
            return Err(MovementPathError::InvalidOriginCost);
        }

        let mut cumulative_cost = MovementUnits::ZERO;
        for (step_index, pair) in steps.windows(2).enumerate() {
            let step_index = step_index + 1;
            let previous = pair[0];
            let step = pair[1];
            if !step.enter_cost().is_positive() {
                return Err(MovementPathError::ZeroEnterCost { step_index });
            }
            if !previous
                .coordinate()
                .neighbors()
                .any(|coordinate| coordinate == step.coordinate())
            {
                return Err(MovementPathError::NonAdjacentStep { step_index });
            }
            cumulative_cost = cumulative_cost
                .checked_add(step.enter_cost())
                .ok_or(MovementPathError::CostOverflow { step_index })?;
            if step.cumulative_cost() != cumulative_cost {
                return Err(MovementPathError::CumulativeCostMismatch {
                    step_index,
                    expected: cumulative_cost,
                    actual: step.cumulative_cost(),
                });
            }
        }

        let Some(final_step) = steps.last() else {
            return Err(MovementPathError::MissingTravelStep);
        };
        let actual_target = final_step.coordinate();
        if actual_target != target {
            return Err(MovementPathError::TargetMismatch {
                expected: target,
                actual: actual_target,
            });
        }
        Ok(Self { target, steps })
    }

    /// Returns the final requested coordinate.
    #[must_use]
    pub const fn target(&self) -> HexCoord {
        self.target
    }

    /// Returns route steps in execution order, including the origin.
    #[must_use]
    pub const fn steps(&self) -> &[MovementStep] {
        &self.steps
    }
}

#[cfg(test)]
mod tests {
    use crate::{HexCoord, MovementUnits};

    use super::{MovementPathError, MovementStep, QueuedMovePath};

    fn step(col: i32, row: i32, enter_cost: u32, cumulative_cost: u32) -> MovementStep {
        MovementStep::new(
            HexCoord::new(col, row),
            MovementUnits::new(enter_cost),
            MovementUnits::new(cumulative_cost),
        )
    }

    #[test]
    fn queued_path_validates_ordered_adjacent_costs() {
        let path = QueuedMovePath::try_new(
            HexCoord::new(2, 0),
            vec![step(0, 0, 0, 0), step(1, 0, 2, 2), step(2, 0, 4, 6)],
        )
        .expect("valid route");

        assert_eq!(path.target(), HexCoord::new(2, 0));
        assert_eq!(path.steps().len(), 3);
    }

    #[test]
    fn queued_path_rejects_non_adjacent_and_inconsistent_steps() {
        assert_eq!(
            QueuedMovePath::try_new(
                HexCoord::new(2, 0),
                vec![step(0, 0, 0, 0), step(2, 0, 2, 2)]
            ),
            Err(MovementPathError::NonAdjacentStep { step_index: 1 })
        );
        assert_eq!(
            QueuedMovePath::try_new(
                HexCoord::new(1, 0),
                vec![step(0, 0, 0, 0), step(1, 0, 2, 3)]
            ),
            Err(MovementPathError::CumulativeCostMismatch {
                step_index: 1,
                expected: MovementUnits::new(2),
                actual: MovementUnits::new(3),
            })
        );
    }
}
