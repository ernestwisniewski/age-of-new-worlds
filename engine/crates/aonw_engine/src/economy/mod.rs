mod forecast;
mod forecast_rules;
mod model;
pub(crate) mod rules;
mod turn;

pub use forecast::{
    CityGoldIncomeSource, EconomyForecast, EconomyForecastQuery, StabilityBreakdown,
    UnitUpkeepBreakdown, UnitUpkeepSource, WealthProjectGoldIncomeSource,
};
pub use model::{
    CityYieldBreakdown, CityYieldContribution, CityYieldContributionKind, CityYieldQuery,
    StrategicResourceProjection, StrategicResourceProjectionQuery, StrategicResourceSource,
    YieldValue,
};
pub use rules::EconomyQueryError;

pub(crate) use forecast_rules::query_economy_forecast;
pub(crate) use rules::{query_city_yield, query_strategic_resource_projection};
pub(crate) use turn::{
    CombatEconomyOwnerIndex, PreparedEconomyTurn, WarWearinessEventCounts, advance_turn_stability,
    city_turn_output, current_stability_breakdown, prepare_turn_economy,
    settle_turn_income_and_upkeep, unit_upkeep_breakdown,
};
