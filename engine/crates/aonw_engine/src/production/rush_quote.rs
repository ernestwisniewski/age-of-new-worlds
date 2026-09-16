use aonw_domain::{City, GameState};

use super::ProductionError;
use super::rush::{finite_target, target_cost};
use super::support::invalid;
use super::yield_rules::production_per_turn;
use crate::{CommandRejectionCode, EngineContext};

/// Exact next rush increment, its gold price and authoritative availability.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionRushQuote {
    production: i64,
    gold_cost: i64,
    rejection: Option<CommandRejectionCode>,
}

impl ProductionRushQuote {
    /// Returns the bounded production increment, or zero without a finite queue.
    #[must_use]
    pub const fn production(self) -> i64 {
        self.production
    }

    /// Returns the exact price, including when the treasury cannot afford it.
    #[must_use]
    pub const fn gold_cost(self) -> i64 {
        self.gold_cost
    }

    /// Returns the same first availability blocker as the rush command.
    #[must_use]
    pub const fn rejection(self) -> Option<CommandRejectionCode> {
        self.rejection
    }

    const fn unavailable(rejection: CommandRejectionCode) -> Self {
        Self {
            production: 0,
            gold_cost: 0,
            rejection: Some(rejection),
        }
    }
}

pub(super) fn quote(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    per_turn: i64,
) -> Result<ProductionRushQuote, ProductionError> {
    let Some(queue) = city.production_queue() else {
        return Ok(ProductionRushQuote::unavailable(
            CommandRejectionCode::ProductionQueueEmpty,
        ));
    };
    let target = match finite_target(queue.target()) {
        Ok(target) => target,
        Err(ProductionError::Rejected(code)) => return Ok(ProductionRushQuote::unavailable(code)),
        Err(error) => return Err(error),
    };
    quote_for_rate(
        state,
        context,
        city,
        target_cost(state, context, target)?,
        per_turn,
    )
}

pub(super) fn quote_for_cost(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    cost: i64,
) -> Result<ProductionRushQuote, ProductionError> {
    let queue = city
        .production_queue()
        .ok_or(CommandRejectionCode::ProductionQueueEmpty)?;
    if cost.saturating_sub(queue.invested_production()) <= 0 {
        return Ok(ProductionRushQuote::unavailable(
            CommandRejectionCode::RushProductionUnavailable,
        ));
    }
    let per_turn = production_per_turn(state, context, city, queue.target())?;
    quote_for_rate(state, context, city, cost, per_turn)
}

fn quote_for_rate(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    cost: i64,
    per_turn: i64,
) -> Result<ProductionRushQuote, ProductionError> {
    let queue = city
        .production_queue()
        .ok_or(CommandRejectionCode::ProductionQueueEmpty)?;
    let remaining = cost.saturating_sub(queue.invested_production());
    if remaining <= 0 {
        return Ok(ProductionRushQuote::unavailable(
            CommandRejectionCode::RushProductionUnavailable,
        ));
    }
    let production = remaining.min(per_turn.max(1));
    let gold_cost = production
        .checked_mul(context.ruleset().production().rush_gold_per_production())
        .ok_or_else(|| invalid("rush gold cost overflow"))?;
    let available = state
        .economy()
        .player_gold()
        .get(city.owner_player_id())
        .copied()
        .unwrap_or(0);
    let rejection = (production <= 0 || gold_cost <= 0 || available < gold_cost)
        .then_some(CommandRejectionCode::RushProductionUnavailable);
    Ok(ProductionRushQuote {
        production,
        gold_cost,
        rejection,
    })
}
