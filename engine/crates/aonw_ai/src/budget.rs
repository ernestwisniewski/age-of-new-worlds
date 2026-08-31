use core::fmt;

/// Deterministic MCTS limits independent of machine speed and wall clocks.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct PlanningBudget {
    iterations: u32,
    max_nodes: u32,
    max_depth: u32,
}

impl PlanningBudget {
    /// Largest accepted exact iteration count for one search.
    pub const MAX_ITERATIONS: u32 = 4_096;
    /// Largest retained tree including its root.
    pub const MAX_NODES: u32 = 1_024;
    /// Largest accepted command sequence depth.
    pub const MAX_DEPTH: u32 = 32;

    /// Validates a strictly positive iteration, node, and depth budget.
    ///
    /// `max_nodes` includes the root and must leave room for one action node.
    ///
    /// # Errors
    ///
    /// Returns a typed error for a zero limit or fewer than two nodes.
    pub const fn try_new(
        iterations: u32,
        max_nodes: u32,
        max_depth: u32,
    ) -> Result<Self, PlanningBudgetError> {
        if iterations == 0 {
            return Err(PlanningBudgetError::ZeroIterations);
        }
        if iterations > Self::MAX_ITERATIONS {
            return Err(PlanningBudgetError::TooManyIterations {
                maximum: Self::MAX_ITERATIONS,
            });
        }
        if max_nodes < 2 {
            return Err(PlanningBudgetError::InsufficientNodes);
        }
        if max_nodes > Self::MAX_NODES {
            return Err(PlanningBudgetError::TooManyNodes {
                maximum: Self::MAX_NODES,
            });
        }
        if max_depth == 0 {
            return Err(PlanningBudgetError::ZeroDepth);
        }
        if max_depth > Self::MAX_DEPTH {
            return Err(PlanningBudgetError::TooDeep {
                maximum: Self::MAX_DEPTH,
            });
        }
        Ok(Self {
            iterations,
            max_nodes,
            max_depth,
        })
    }

    /// Returns the exact number of search iterations.
    #[must_use]
    pub const fn iterations(self) -> u32 {
        self.iterations
    }

    /// Returns the maximum number of retained nodes including the root.
    #[must_use]
    pub const fn max_nodes(self) -> u32 {
        self.max_nodes
    }

    /// Returns the maximum command depth for selection and rollout.
    #[must_use]
    pub const fn max_depth(self) -> u32 {
        self.max_depth
    }
}

/// Invalid deterministic planning budget.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlanningBudgetError {
    /// An exact search cannot run zero iterations.
    ZeroIterations,
    /// Iteration count exceeds the reviewed work ceiling.
    TooManyIterations {
        /// Largest accepted iteration count.
        maximum: u32,
    },
    /// Root plus at least one action node are required.
    InsufficientNodes,
    /// Retained node count exceeds the reviewed memory ceiling.
    TooManyNodes {
        /// Largest accepted node count.
        maximum: u32,
    },
    /// Search and rollout require at least one command level.
    ZeroDepth,
    /// Command depth exceeds the reviewed work and trace ceiling.
    TooDeep {
        /// Largest accepted command depth.
        maximum: u32,
    },
}

impl fmt::Display for PlanningBudgetError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ZeroIterations => formatter.write_str("iterations must be greater than zero"),
            Self::TooManyIterations { maximum } => {
                write!(formatter, "iterations must not exceed {maximum}")
            }
            Self::InsufficientNodes => formatter.write_str("max_nodes must be at least two"),
            Self::TooManyNodes { maximum } => {
                write!(formatter, "max_nodes must not exceed {maximum}")
            }
            Self::ZeroDepth => formatter.write_str("max_depth must be greater than zero"),
            Self::TooDeep { maximum } => {
                write!(formatter, "max_depth must not exceed {maximum}")
            }
        }
    }
}

impl std::error::Error for PlanningBudgetError {}

#[cfg(test)]
mod tests {
    use super::{PlanningBudget, PlanningBudgetError};

    #[test]
    fn rejects_each_unusable_limit() {
        assert_eq!(
            PlanningBudget::try_new(0, 2, 1),
            Err(PlanningBudgetError::ZeroIterations)
        );
        assert_eq!(
            PlanningBudget::try_new(1, 1, 1),
            Err(PlanningBudgetError::InsufficientNodes)
        );
        assert_eq!(
            PlanningBudget::try_new(1, 2, 0),
            Err(PlanningBudgetError::ZeroDepth)
        );
        assert_eq!(
            PlanningBudget::try_new(PlanningBudget::MAX_ITERATIONS + 1, 2, 1),
            Err(PlanningBudgetError::TooManyIterations {
                maximum: PlanningBudget::MAX_ITERATIONS
            })
        );
        assert_eq!(
            PlanningBudget::try_new(1, PlanningBudget::MAX_NODES + 1, 1),
            Err(PlanningBudgetError::TooManyNodes {
                maximum: PlanningBudget::MAX_NODES
            })
        );
        assert_eq!(
            PlanningBudget::try_new(1, 2, PlanningBudget::MAX_DEPTH + 1),
            Err(PlanningBudgetError::TooDeep {
                maximum: PlanningBudget::MAX_DEPTH
            })
        );
        assert_eq!(
            PlanningBudgetError::ZeroIterations.to_string(),
            "iterations must be greater than zero"
        );
        assert_eq!(
            PlanningBudgetError::InsufficientNodes.to_string(),
            "max_nodes must be at least two"
        );
        assert_eq!(
            PlanningBudgetError::ZeroDepth.to_string(),
            "max_depth must be greater than zero"
        );
        assert_eq!(
            PlanningBudgetError::TooManyIterations {
                maximum: PlanningBudget::MAX_ITERATIONS
            }
            .to_string(),
            "iterations must not exceed 4096"
        );
        assert_eq!(
            PlanningBudgetError::TooManyNodes {
                maximum: PlanningBudget::MAX_NODES
            }
            .to_string(),
            "max_nodes must not exceed 1024"
        );
        assert_eq!(
            PlanningBudgetError::TooDeep {
                maximum: PlanningBudget::MAX_DEPTH
            }
            .to_string(),
            "max_depth must not exceed 32"
        );
    }
}
