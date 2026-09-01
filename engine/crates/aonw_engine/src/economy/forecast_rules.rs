use aonw_domain::GameState;

use crate::{CommandRejectionCode, EngineContext};

use super::{
    CityGoldIncomeSource, EconomyForecast, EconomyForecastQuery, WealthProjectGoldIncomeSource,
    rules::EconomyQueryError,
};

pub(crate) fn query_economy_forecast(
    state: &GameState,
    context: EngineContext<'_>,
    query: EconomyForecastQuery,
) -> Result<EconomyForecast, EconomyQueryError> {
    if state.revision().get() != query.expected_revision() {
        return Err(EconomyQueryError::Rejected(
            CommandRejectionCode::StaleRevision,
        ));
    }
    let player = context.actor_player_id();
    let mut city_sources = Vec::new();
    let mut city_income = 0_i64;
    for city in state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
    {
        let amount = crate::economy::city_turn_output(state, context, city)
            .map_err(projection_invalid)?
            .gold;
        if amount <= 0 {
            continue;
        }
        city_income = city_income
            .checked_add(amount)
            .ok_or(EconomyQueryError::ArithmeticOverflow)?;
        city_sources.push(CityGoldIncomeSource::new(city.id().clone(), amount));
    }
    city_sources.sort_unstable_by(|left, right| left.city_id().cmp(right.city_id()));

    let mut project_sources =
        crate::production::selected_wealth_project_gold(state, context, player)
            .map_err(projection_invalid)?
            .into_iter()
            .filter(|source| source.amount > 0)
            .map(|source| WealthProjectGoldIncomeSource::new(source.city_id, source.amount))
            .collect::<Vec<_>>();
    project_sources.sort_unstable_by(|left, right| left.city_id().cmp(right.city_id()));
    let project_income = project_sources.iter().try_fold(0_i64, |total, source| {
        total
            .checked_add(source.amount())
            .ok_or(EconomyQueryError::ArithmeticOverflow)
    })?;
    let gross_income = city_income
        .checked_add(project_income)
        .ok_or(EconomyQueryError::ArithmeticOverflow)?;
    let upkeep = crate::economy::unit_upkeep_breakdown(state, context.ruleset(), player)
        .map_err(projection_invalid)?;
    let net_per_turn = gross_income
        .checked_sub(upkeep.total())
        .ok_or(EconomyQueryError::ArithmeticOverflow)?;
    let stability = crate::economy::current_stability_breakdown(
        state,
        context.map(),
        context.ruleset(),
        player,
    )
    .map_err(projection_invalid)?;
    Ok(EconomyForecast::new(
        player.clone(),
        state
            .economy()
            .player_gold()
            .get(player)
            .copied()
            .unwrap_or_default(),
        city_income,
        project_income,
        gross_income,
        net_per_turn,
        city_sources,
        project_sources,
        upkeep,
        stability,
    ))
}

fn projection_invalid(error: impl core::fmt::Display) -> EconomyQueryError {
    EconomyQueryError::ProjectionInvalid(error.to_string().into())
}
