use aonw_domain::{City, CityProductionTarget, CityProjectType, GameState};

use super::ProductionError;
use super::commands::initial_investment;
use super::spawn::spawn_position;
use super::turn::project_output;
use super::yield_rules::ProductionRates;
use crate::EngineContext;

/// Current-rate estimate for selecting or continuing one production target.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionForecast {
    invested_production: i64,
    production_per_turn: i64,
    estimated_turns: Option<u64>,
    project_output: Option<i64>,
    spawn_blocked: bool,
}

impl ProductionForecast {
    /// Returns the investment preserved or rolled over by the start command.
    #[must_use]
    pub const fn invested_production(self) -> i64 {
        self.invested_production
    }

    /// Returns production including the target's technology and specialization bonuses.
    #[must_use]
    pub const fn production_per_turn(self) -> i64 {
        self.production_per_turn
    }

    /// Returns remaining turns at the current rate, or no finite estimate.
    #[must_use]
    pub const fn estimated_turns(self) -> Option<u64> {
        self.estimated_turns
    }

    /// Returns the gold or science output of a continuous project, including zero.
    #[must_use]
    pub const fn project_output(self) -> Option<i64> {
        self.project_output
    }

    /// Returns whether the completed active unit is waiting for a spawn location.
    #[must_use]
    pub const fn spawn_blocked(self) -> bool {
        self.spawn_blocked
    }
}

pub(super) fn forecast(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
    cost: i64,
    rates: &ProductionRates,
) -> Result<ProductionForecast, ProductionError> {
    let invested_production = initial_investment(city, cost);
    let production_per_turn = rates.for_target(city, target)?;
    let project_output = if let CityProductionTarget::Project(project) = target {
        Some(project_output(
            production_per_turn,
            context
                .ruleset()
                .production()
                .project_divisor(project == CityProjectType::Research),
        )?)
    } else {
        None
    };
    let spawn_blocked = completed_spawn_blocked(state, context, city, target, cost)?;
    let estimated_turns = if project_output.is_some() || spawn_blocked {
        None
    } else {
        remaining_turns(cost, invested_production, production_per_turn)
    };
    Ok(ProductionForecast {
        invested_production,
        production_per_turn,
        estimated_turns,
        project_output,
        spawn_blocked,
    })
}

fn completed_spawn_blocked(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
    cost: i64,
) -> Result<bool, ProductionError> {
    let CityProductionTarget::Unit(kind) = target else {
        return Ok(false);
    };
    if !city
        .production_queue()
        .is_some_and(|queue| queue.target() == target && queue.invested_production() >= cost)
    {
        return Ok(false);
    }
    Ok(spawn_position(context, city, kind, state.units(), state.occupancy_policy())?.is_none())
}

fn remaining_turns(cost: i64, invested: i64, production: i64) -> Option<u64> {
    let remaining = u64::try_from(cost.saturating_sub(invested).max(0)).ok()?;
    if remaining == 0 {
        return Some(0);
    }
    let production = u64::try_from(production).ok().filter(|value| *value > 0)?;
    Some(remaining.div_ceil(production))
}

#[cfg(test)]
mod tests {
    use super::remaining_turns;

    #[test]
    fn remaining_turns_round_up_without_overflow_or_a_zero_rate_estimate() {
        assert_eq!(remaining_turns(10, 0, 3), Some(4));
        assert_eq!(remaining_turns(10, 9, 3), Some(1));
        assert_eq!(remaining_turns(10, 10, 0), Some(0));
        assert_eq!(remaining_turns(10, 12, 3), Some(0));
        assert_eq!(remaining_turns(10, 9, 0), None);
        assert_eq!(remaining_turns(i64::MAX, 0, i64::MAX), Some(1));
        assert_eq!(remaining_turns(i64::MAX, 0, 1), Some(i64::MAX as u64));
    }
}
